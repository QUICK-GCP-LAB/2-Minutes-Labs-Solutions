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

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  event_type,
  COUNT(*) AS event_count
FROM \`bigquery-public-data.ncaa_basketball.mbb_pbp_sr\`
GROUP BY 1
ORDER BY event_count DESC;
"

bq query --use_legacy_sql=false \
"
#standardSQL
#most three points made
SELECT
  scheduled_date,
  name,
  market,
  alias,
  three_points_att,
  three_points_made,
  three_points_pct,
  opp_name,
  opp_market,
  opp_alias,
  opp_three_points_att,
  opp_three_points_made,
  opp_three_points_pct,
  (three_points_made + opp_three_points_made) AS total_threes
FROM \`bigquery-public-data.ncaa_basketball.mbb_teams_games_sr\`
WHERE season > 2010
ORDER BY total_threes DESC
LIMIT 5;
"

bq query --use_legacy_sql=false \
"
#standardSQL
SELECT
  venue_name, venue_capacity, venue_city, venue_state
FROM \`bigquery-public-data.ncaa_basketball.mbb_teams_games_sr\`
GROUP BY 1,2,3,4
ORDER BY venue_capacity DESC
LIMIT 5;
"

bq query --use_legacy_sql=false \
"
#standardSQL
#highest scoring game of all time
SELECT
  scheduled_date,
  name,
  market,
  alias,
  points_game AS team_points,
  opp_name,
  opp_market,
  opp_alias,
  opp_points_game AS opposing_team_points,
  points_game + opp_points_game AS point_total
FROM \`bigquery-public-data.ncaa_basketball.mbb_teams_games_sr\`
WHERE season > 2010
ORDER BY point_total DESC
LIMIT 5;
"

bq query --use_legacy_sql=false \
"
#standardSQL
#biggest point difference in a championship game
SELECT
  scheduled_date,
  name,
  market,
  alias,
  points_game AS team_points,
  opp_name,
  opp_market,
  opp_alias,
  opp_points_game AS opposing_team_points,
  ABS(points_game - opp_points_game) AS point_difference
FROM \`bigquery-public-data.ncaa_basketball.mbb_teams_games_sr\`
WHERE season > 2015 AND tournament_type = 'National Championship'
ORDER BY point_difference DESC
LIMIT 5;
"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#