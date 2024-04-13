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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

bq mk --dataset $DEVSHELL_PROJECT_ID:bracketology

bq query --use_legacy_sql=false \
"
SELECT
  season,
  COUNT(*) as games_per_tournament
  FROM
 \`bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games\`
 GROUP BY season
 ORDER BY season # default is Ascending (low to high)
"

bq query --use_legacy_sql=false \
"
# create a row for the winning team
SELECT
  # features
  season, # ex: 2015 season has March 2016 tournament games
  round, # sweet 16
  days_from_epoch, # how old is the game
  game_date,
  day, # Friday
  'win' AS label, # our label
  win_seed AS seed, # ranking
  win_market AS market,
  win_name AS name,
  win_alias AS alias,
  win_school_ncaa AS school_ncaa,
  # win_pts AS points,
  lose_seed AS opponent_seed, # ranking
  lose_market AS opponent_market,
  lose_name AS opponent_name,
  lose_alias AS opponent_alias,
  lose_school_ncaa AS opponent_school_ncaa
  # lose_pts AS opponent_points
FROM \`bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games\`
UNION ALL
# create a separate row for the losing team
SELECT
# features
  season,
  round,
  days_from_epoch,
  game_date,
  day,
  'loss' AS label, # our label
  lose_seed AS seed, # ranking
  lose_market AS market,
  lose_name AS name,
  lose_alias AS alias,
  lose_school_ncaa AS school_ncaa,
  # lose_pts AS points,
  win_seed AS opponent_seed, # ranking
  win_market AS opponent_market,
  win_name AS opponent_name,
  win_alias AS opponent_alias,
  win_school_ncaa AS opponent_school_ncaa
  # win_pts AS opponent_points
FROM
\`bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games\`;
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE MODEL
  \`bracketology.ncaa_model\`
OPTIONS
  ( model_type='logistic_reg') AS
# create a row for the winning team
SELECT
  # features
  season,
  'win' AS label, # our label
  win_seed AS seed, # ranking
  win_school_ncaa AS school_ncaa,
  lose_seed AS opponent_seed, # ranking
  lose_school_ncaa AS opponent_school_ncaa
FROM \`bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games\`
WHERE season <= 2017
UNION ALL
# create a separate row for the losing team
SELECT
# features
  season,
  'loss' AS label, # our label
  lose_seed AS seed, # ranking
  lose_school_ncaa AS school_ncaa,
  win_seed AS opponent_seed, # ranking
  win_school_ncaa AS opponent_school_ncaa
FROM
\`bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games\`
# now we split our dataset with a WHERE clause so we can train on a subset of data and then evaluate and test the model's performance against a reserved subset so the model doesn't memorize or overfit to the training data.
# tournament season information from 1985 - 2017
# here we'll train on 1985 - 2017 and predict for 2018
WHERE season <= 2017
"

bq query --use_legacy_sql=false \
"
SELECT
  category,
  weight
FROM
  UNNEST((
    SELECT
      category_weights
    FROM
      ML.WEIGHTS(MODEL \`bracketology.ncaa_model\`)
    WHERE
      processed_input = 'seed')) # try other features like 'school_ncaa'
      ORDER BY weight DESC;
SELECT
  *
FROM
  ML.EVALUATE(MODEL   \`bracketology.ncaa_model\`);
CREATE OR REPLACE TABLE \`bracketology.predictions\` AS (
SELECT * FROM ML.PREDICT(MODEL \`bracketology.ncaa_model\`,
# predicting for 2018 tournament games (2017 season)
(SELECT * FROM \`data-to-insights.ncaa.2018_tournament_results\`)
)
);
"

bq query --use_legacy_sql=false \
"
# create training dataset:
# create a row for the winning team
CREATE OR REPLACE TABLE \`bracketology.training_new_features\` AS
WITH outcomes AS (
SELECT
  # features
  season, # 1994
  'win' AS label, # our label
  win_seed AS seed, # ranking # this time without seed even
  win_school_ncaa AS school_ncaa,
  lose_seed AS opponent_seed, # ranking
  lose_school_ncaa AS opponent_school_ncaa
FROM \`bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games\` t
WHERE season >= 2014
UNION ALL
# create a separate row for the losing team
SELECT
# features
  season, # 1994
  'loss' AS label, # our label
  lose_seed AS seed, # ranking
  lose_school_ncaa AS school_ncaa,
  win_seed AS opponent_seed, # ranking
  win_school_ncaa AS opponent_school_ncaa
FROM
\`bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games\` t
WHERE season >= 2014
UNION ALL
# add in 2018 tournament game results not part of the public dataset:
SELECT
  season,
  label,
  seed,
  school_ncaa,
  opponent_seed,
  opponent_school_ncaa
FROM
  \`data-to-insights.ncaa.2018_tournament_results\`
)
SELECT
o.season,
label,
# our team
  seed,
  school_ncaa,
  # new pace metrics (basketball possession)
  team.pace_rank,
  team.poss_40min,
  team.pace_rating,
  # new efficiency metrics (scoring over time)
  team.efficiency_rank,
  team.pts_100poss,
  team.efficiency_rating,
# opposing team
  opponent_seed,
  opponent_school_ncaa,
  # new pace metrics (basketball possession)
  opp.pace_rank AS opp_pace_rank,
  opp.poss_40min AS opp_poss_40min,
  opp.pace_rating AS opp_pace_rating,
  # new efficiency metrics (scoring over time)
  opp.efficiency_rank AS opp_efficiency_rank,
  opp.pts_100poss AS opp_pts_100poss,
  opp.efficiency_rating AS opp_efficiency_rating,
# a little feature engineering (take the difference in stats)
  # new pace metrics (basketball possession)
  opp.pace_rank - team.pace_rank AS pace_rank_diff,
  opp.poss_40min - team.poss_40min AS pace_stat_diff,
  opp.pace_rating - team.pace_rating AS pace_rating_diff,
  # new efficiency metrics (scoring over time)
  opp.efficiency_rank - team.efficiency_rank AS eff_rank_diff,
  opp.pts_100poss - team.pts_100poss AS eff_stat_diff,
  opp.efficiency_rating - team.efficiency_rating AS eff_rating_diff
FROM outcomes AS o
LEFT JOIN \`data-to-insights.ncaa.feature_engineering\` AS team
ON o.school_ncaa = team.team AND o.season = team.season
LEFT JOIN \`data-to-insights.ncaa.feature_engineering\` AS opp
ON o.opponent_school_ncaa = opp.team AND o.season = opp.season;

CREATE OR REPLACE MODEL
  \`bracketology.ncaa_model_updated\`
OPTIONS
  ( model_type='logistic_reg') AS
SELECT
  # this time, don't train the model on school name or seed
  season,
  label,
  # our pace
  poss_40min,
  pace_rank,
  pace_rating,
  # opponent pace
  opp_poss_40min,
  opp_pace_rank,
  opp_pace_rating,
  # difference in pace
  pace_rank_diff,
  pace_stat_diff,
  pace_rating_diff,
  # our efficiency
  pts_100poss,
  efficiency_rank,
  efficiency_rating,
  # opponent efficiency
  opp_pts_100poss,
  opp_efficiency_rank,
  opp_efficiency_rating,
  # difference in efficiency
  eff_rank_diff,
  eff_stat_diff,
  eff_rating_diff
FROM \`bracketology.training_new_features\`
# here we'll train on 2014 - 2017 and predict on 2018
WHERE season BETWEEN 2014 AND 2017; # between in SQL is inclusive of end points
"

bq query --use_legacy_sql=false \
"
SELECT
  *
FROM
  ML.EVALUATE(MODEL     \`bracketology.ncaa_model_updated\`);

CREATE OR REPLACE TABLE \`bracketology.ncaa_2018_predictions\` AS
SELECT
  *
FROM
  ML.PREDICT(MODEL \`bracketology.ncaa_model_updated\`, 
    (
      SELECT
        *
      FROM \`bracketology.training_new_features\`
      WHERE season = 2018
    )
  );

SELECT
CONCAT(school_ncaa, ' was predicted to ',IF(predicted_label='loss','lose','win'),' ',CAST(ROUND(p.prob,2)*100 AS STRING), '% but ', IF(n.label='loss','lost','won')) AS narrative,
predicted_label, # what the model thought
n.label, # what actually happened
ROUND(p.prob,2) AS probability,
season,
# us
seed,
school_ncaa,
pace_rank,
efficiency_rank,
# them
opponent_seed,
opponent_school_ncaa,
opp_pace_rank,
opp_efficiency_rank
FROM \`bracketology.ncaa_2018_predictions\` AS n,
UNNEST(predicted_label_probs) AS p
WHERE
  predicted_label <> n.label # model got it wrong
  AND p.prob > .75  # by more than 75% confidence
ORDER BY prob DESC
"

bq query --use_legacy_sql=false \
"
SELECT
CONCAT(opponent_school_ncaa, ' (', opponent_seed, ') was ',CAST(ROUND(ROUND(p.prob,2)*100,2) AS STRING),'% predicted to upset ', school_ncaa, ' (', seed, ') and did!') AS narrative,
predicted_label, # what the model thought
n.label, # what actually happened
ROUND(p.prob,2) AS probability,
season,

# us
seed,
school_ncaa,
pace_rank,
efficiency_rank,

# them
opponent_seed,
opponent_school_ncaa,
opp_pace_rank,
opp_efficiency_rank,

(CAST(opponent_seed AS INT64) - CAST(seed AS INT64)) AS seed_diff

FROM \`bracketology.ncaa_2018_predictions\` AS n,
UNNEST(predicted_label_probs) AS p
WHERE
  predicted_label = 'loss'
  AND predicted_label = n.label # model got it right
  AND p.prob >= .55  # by 55%+ confidence
  AND (CAST(opponent_seed AS INT64) - CAST(seed AS INT64)) > 2 # seed difference magnitude
ORDER BY (CAST(opponent_seed AS INT64) - CAST(seed AS INT64)) DESC;

SELECT
  NULL AS label,
  team.school_ncaa AS team_school_ncaa,
  team.seed AS team_seed,
  opp.school_ncaa AS opp_school_ncaa,
  opp.seed AS opp_seed
FROM \`data-to-insights.ncaa.2019_tournament_seeds\` AS team
CROSS JOIN \`data-to-insights.ncaa.2019_tournament_seeds\` AS opp
# teams cannot play against themselves :)
WHERE team.school_ncaa <> opp.school_ncaa;

CREATE OR REPLACE TABLE \`bracketology.ncaa_2019_tournament\` AS
WITH team_seeds_all_possible_games AS (
  SELECT
    NULL AS label,
    team.school_ncaa AS school_ncaa,
    team.seed AS seed,
    opp.school_ncaa AS opponent_school_ncaa,
    opp.seed AS opponent_seed
  FROM \`data-to-insights.ncaa.2019_tournament_seeds\` AS team
  CROSS JOIN \`data-to-insights.ncaa.2019_tournament_seeds\` AS opp
  # teams cannot play against themselves :)
  WHERE team.school_ncaa <> opp.school_ncaa
)
, add_in_2018_season_stats AS (
SELECT
  team_seeds_all_possible_games.*,
  # bring in features from the 2018 regular season for each team
  (SELECT AS STRUCT * FROM \`data-to-insights.ncaa.feature_engineering\` WHERE school_ncaa = team AND season = 2018) AS team,
  (SELECT AS STRUCT * FROM \`data-to-insights.ncaa.feature_engineering\` WHERE opponent_school_ncaa = team AND season = 2018) AS opp
FROM team_seeds_all_possible_games
)
# Preparing 2019 data for prediction
SELECT
  label,
  2019 AS season, # 2018-2019 tournament season
# our team
  seed,
  school_ncaa,
  # new pace metrics (basketball possession)
  team.pace_rank,
  team.poss_40min,
  team.pace_rating,
  # new efficiency metrics (scoring over time)
  team.efficiency_rank,
  team.pts_100poss,
  team.efficiency_rating,
# opposing team
  opponent_seed,
  opponent_school_ncaa,
  # new pace metrics (basketball possession)
  opp.pace_rank AS opp_pace_rank,
  opp.poss_40min AS opp_poss_40min,
  opp.pace_rating AS opp_pace_rating,
  # new efficiency metrics (scoring over time)
  opp.efficiency_rank AS opp_efficiency_rank,
  opp.pts_100poss AS opp_pts_100poss,
  opp.efficiency_rating AS opp_efficiency_rating,
# a little feature engineering (take the difference in stats)
  # new pace metrics (basketball possession)
  opp.pace_rank - team.pace_rank AS pace_rank_diff,
  opp.poss_40min - team.poss_40min AS pace_stat_diff,
  opp.pace_rating - team.pace_rating AS pace_rating_diff,
  # new efficiency metrics (scoring over time)
  opp.efficiency_rank - team.efficiency_rank AS eff_rank_diff,
  opp.pts_100poss - team.pts_100poss AS eff_stat_diff,
  opp.efficiency_rating - team.efficiency_rating AS eff_rating_diff
FROM add_in_2018_season_stats;

CREATE OR REPLACE TABLE \`bracketology.ncaa_2019_tournament_predictions\` AS
SELECT
  *
FROM
  ML.PREDICT(MODEL     \`bracketology.ncaa_model_updated\`, 
(
SELECT * FROM \`bracketology.ncaa_2019_tournament\`
));
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE \`bracketology.predictions\` AS (

SELECT * FROM ML.PREDICT(MODEL \`bracketology.ncaa_model\`,

# predicting for 2018 tournament games (2017 season)
(SELECT * FROM \`data-to-insights.ncaa.2018_tournament_results\`)
)
)
"

bq query --use_legacy_sql=false \
"
# create training dataset:
# create a row for the winning team
CREATE OR REPLACE TABLE \`bracketology.training_new_features\` AS
WITH outcomes AS (
SELECT
  # features
  season, # 1994

  'win' AS label, # our label

  win_seed AS seed, # ranking # this time without seed even
  win_school_ncaa AS school_ncaa,

  lose_seed AS opponent_seed, # ranking
  lose_school_ncaa AS opponent_school_ncaa

FROM \`bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games\` t
WHERE season >= 2014

UNION ALL

# create a separate row for the losing team
SELECT
# features
  season, # 1994

  'loss' AS label, # our label

  lose_seed AS seed, # ranking
  lose_school_ncaa AS school_ncaa,

  win_seed AS opponent_seed, # ranking
  win_school_ncaa AS opponent_school_ncaa

FROM
\`bigquery-public-data.ncaa_basketball.mbb_historical_tournament_games\` t
WHERE season >= 2014

UNION ALL

# add in 2018 tournament game results not part of the public dataset:
SELECT
  season,
  label,
  seed,
  school_ncaa,
  opponent_seed,
  opponent_school_ncaa
FROM
  \`data-to-insights.ncaa.2018_tournament_results\`

)

SELECT
o.season,
label,

# our team
  seed,
  school_ncaa,
  # new pace metrics (basketball possession)
  team.pace_rank,
  team.poss_40min,
  team.pace_rating,
  # new efficiency metrics (scoring over time)
  team.efficiency_rank,
  team.pts_100poss,
  team.efficiency_rating,

# opposing team
  opponent_seed,
  opponent_school_ncaa,
  # new pace metrics (basketball possession)
  opp.pace_rank AS opp_pace_rank,
  opp.poss_40min AS opp_poss_40min,
  opp.pace_rating AS opp_pace_rating,
  # new efficiency metrics (scoring over time)
  opp.efficiency_rank AS opp_efficiency_rank,
  opp.pts_100poss AS opp_pts_100poss,
  opp.efficiency_rating AS opp_efficiency_rating,

# a little feature engineering (take the difference in stats)

  # new pace metrics (basketball possession)
  opp.pace_rank - team.pace_rank AS pace_rank_diff,
  opp.poss_40min - team.poss_40min AS pace_stat_diff,
  opp.pace_rating - team.pace_rating AS pace_rating_diff,
  # new efficiency metrics (scoring over time)
  opp.efficiency_rank - team.efficiency_rank AS eff_rank_diff,
  opp.pts_100poss - team.pts_100poss AS eff_stat_diff,
  opp.efficiency_rating - team.efficiency_rating AS eff_rating_diff

FROM outcomes AS o
LEFT JOIN \`data-to-insights.ncaa.feature_engineering\` AS team
ON o.school_ncaa = team.team AND o.season = team.season
LEFT JOIN \`data-to-insights.ncaa.feature_engineering\` AS opp
ON o.opponent_school_ncaa = opp.team AND o.season = opp.season
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE \`bracketology.ncaa_2018_predictions\` AS

# let's add back our other data columns for context
SELECT
  *
FROM
  ML.PREDICT(MODEL     \`bracketology.ncaa_model_updated\`, (

SELECT
* # include all columns now (the model has already been trained)
FROM \`bracketology.training_new_features\`

WHERE season = 2018

))
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE \`bracketology.ncaa_2019_tournament_predictions\` AS

SELECT
  *
FROM
  # let's predicted using the newer model
  ML.PREDICT(MODEL     \`bracketology.ncaa_model_updated\`, (

# let's predict on March 2019 tournament games:
SELECT * FROM \`bracketology.ncaa_2019_tournament\`
))

"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#