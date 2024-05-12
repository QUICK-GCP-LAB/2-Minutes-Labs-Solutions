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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

bq query --use_legacy_sql=false '
SELECT
 date,
 label,
 (team1.score + team2.score) AS totalGoals
FROM
 `soccer.matches` Matches
LEFT JOIN
 `soccer.competitions` Competitions ON
   Matches.competitionId = Competitions.wyId
WHERE
 status = "Played" AND
 Competitions.name = "Spanish first division"
ORDER BY
 totalGoals DESC, date DESC
'
bq query --use_legacy_sql=false '
SELECT
 playerId,
 (Players.firstName || " " || Players.lastName) AS playerName,
 COUNT(id) AS numPasses
FROM
 `soccer.events` Events
LEFT JOIN
 `soccer.players` Players ON
   Events.playerId = Players.wyId
WHERE
 eventName = "Pass"
GROUP BY
 playerId, playerName
ORDER BY
 numPasses DESC
LIMIT 10
'

bq query --use_legacy_sql=false '
SELECT
 playerId,
 (Players.firstName || " " || Players.lastName) AS playerName,
 COUNT(id) AS numPKAtt,
 SUM(IF(101 IN UNNEST(tags.id), 1, 0)) AS numPKGoals,
 SAFE_DIVIDE(
   SUM(IF(101 IN UNNEST(tags.id), 1, 0)),
   COUNT(id)
   ) AS PKSuccessRate
FROM
 `soccer.events` Events
LEFT JOIN
 `soccer.players` Players ON
   Events.playerId = Players.wyId
WHERE
 eventName = "Free Kick" AND
 subEventName = "Penalty"
GROUP BY
 playerId, playerName
HAVING
 numPkAtt >= 5
ORDER BY
 PKSuccessRate DESC, numPKAtt DESC
'

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#