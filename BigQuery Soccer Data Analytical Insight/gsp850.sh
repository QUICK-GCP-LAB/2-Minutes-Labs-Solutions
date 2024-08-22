#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`
#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

bq query --use_legacy_sql=false \
"
SELECT
 Events.playerId,
 (Players.firstName || ' ' || Players.lastName) AS playerName,
 SUM(IF(Tags2Name.Label = 'assist', 1, 0)) AS numAssists
FROM
 \`soccer.events\` Events,
 Events.tags Tags
LEFT JOIN
 \`soccer.tags2name\` Tags2Name ON
   Tags.id = Tags2Name.Tag
LEFT JOIN
 \`soccer.players\` Players ON
   Events.playerId = Players.wyId
GROUP BY
 playerId, playerName
ORDER BY
 numAssists 
"

bq query --use_legacy_sql=false \
"
WITH
Passes AS
(
 SELECT
   *,
   /* 1801 is known Tag for 'accurate' from tags2name table */
   (1801 IN UNNEST(tags.id)) AS accuratePass,
   (CASE
     WHEN ARRAY_LENGTH(positions) != 2 THEN NULL
     ELSE
  /* Translate 0-100 (x,y) coordinate-based distances to absolute positions
  using "average" field dimensions of 105x68 before combining in 2D dist calc */
       SQRT(
         POW(
           (positions[ORDINAL(2)].x - positions[ORDINAL(1)].x) * 105/100,
           2) +
         POW(
           (positions[ORDINAL(2)].y - positions[ORDINAL(1)].y) * 68/100,
           2)
         )
     END) AS passDistance
 FROM
   \`soccer.events\`
 WHERE
   eventName = 'Pass'
)
SELECT
 Passes.teamId,
 Teams.name AS team,
 Teams.area.name AS teamArea,
 COUNT(Passes.Id) AS numPasses,
 AVG(Passes.passDistance) AS avgPassDistance,
 SAFE_DIVIDE(
   SUM(IF(Passes.accuratePass, Passes.passDistance, 0)),
   SUM(IF(Passes.accuratePass, 1, 0))
   ) AS avgAccuratePassDistance
FROM
 Passes
LEFT JOIN
 \`soccer.teams\` Teams ON
   Passes.teamId = Teams.wyId
WHERE
 Teams.type = 'club'
GROUP BY
 teamId, team, teamArea
ORDER BY
 avgPassDistance

"

bq query --use_legacy_sql=false \
"
WITH
Shots AS
(
 SELECT
  *,
  /* 101 is known Tag for 'goals' from goals table */
  (101 IN UNNEST(tags.id)) AS isGoal,
  /* Translate 0-100 (x,y) coordinate-based distances to absolute positions
  using "average" field dimensions of 105x68 before combining in 2D dist calc */
  SQRT(
    POW(
      (100 - positions[ORDINAL(1)].x) * 105/100,
      2) +
    POW(
      (50 - positions[ORDINAL(1)].y) * 68/100,
      2)
     ) AS shotDistance
 FROM
  \`soccer.events\`
 WHERE
  /* Includes both "open play" & free kick shots (including penalties) */
  eventName = 'Shot' OR
  (eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty'))
)
SELECT
 ROUND(shotDistance, 0) AS ShotDistRound0,
 COUNT(*) AS numShots,
 SUM(IF(isGoal, 1, 0)) AS numGoals,
 AVG(IF(isGoal, 1, 0)) AS goalPct
FROM
 Shots
WHERE
 shotDistance <= 50
GROUP BY
 ShotDistRound0
ORDER BY
 ShotDistRound0
"

bq query --use_legacy_sql=false \
"
WITH
Shots AS
(
 SELECT
  *,
  /* 101 is known Tag for 'goals' from goals table */
  (101 IN UNNEST(tags.id)) AS isGoal,
  /* Translate 0-100 (x,y) coordinates to absolute positions using "average"
  field dimensions of 105x68 before using in various distance calcs;
  LEAST used to cap shot locations to on-field (x, y) (i.e. no exact 100s) */
  LEAST(positions[ORDINAL(1)].x, 99.99999) * 105/100 AS shotXAbs,
  LEAST(positions[ORDINAL(1)].y, 99.99999) * 68/100 AS shotYAbs
 FROM
   \`soccer.events\`
 WHERE
   /* Includes both "open play" & free kick shots (including penalties) */
   eventName = 'Shot' OR
   (eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty'))
),
ShotsWithAngle AS
(
 SELECT
   Shots.*,
   /* Law of cosines to get 'open' angle from shot location to goal, given
    that goal opening is 7.32m, placed midway up at field end of (105, 34) */
   SAFE.ACOS(
     SAFE_DIVIDE(
       ( /* Squared distance between shot and 1 post, in meters */
         (POW(105 - shotXAbs, 2) + POW(34 + (7.32/2) - shotYAbs, 2)) +
         /* Squared distance between shot and other post, in meters */
         (POW(105 - shotXAbs, 2) + POW(34 - (7.32/2) - shotYAbs, 2)) -
         /* Squared length of goal opening, in meters */
         POW(7.32, 2)
       ),
       (2 *
         /* Distance between shot and 1 post, in meters */
         SQRT(POW(105 - shotXAbs, 2) + POW(34 + 7.32/2 - shotYAbs, 2)) *
         /* Distance between shot and other post, in meters */
         SQRT(POW(105 - shotXAbs, 2) + POW(34 - 7.32/2 - shotYAbs, 2))
       )
     )
   /* Translate radians to degrees */
   ) * 180 / ACOS(-1)
   AS shotAngle
 FROM
   Shots
)
SELECT
 ROUND(shotAngle, 0) AS ShotAngleRound0,
 COUNT(*) AS numShots,
 SUM(IF(isGoal, 1, 0)) AS numGoals,
 AVG(IF(isGoal, 1, 0)) AS goalPct
FROM
 ShotsWithAngle
GROUP BY
 ShotAngleRound0
ORDER BY
 ShotAngleRound0
"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#