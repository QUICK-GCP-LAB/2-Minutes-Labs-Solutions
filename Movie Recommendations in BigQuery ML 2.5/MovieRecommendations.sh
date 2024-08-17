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

bq --location=US mk --dataset movies

  bq load --source_format=CSV \
 --location=US \
 --autodetect movies.movielens_ratings \
 gs://dataeng-movielens/ratings.csv

  bq load --source_format=CSV \
 --location=US   \
 --autodetect movies.movielens_movies_raw \
 gs://dataeng-movielens/movies.csv

bq query --use_legacy_sql=false \
"
SELECT
  COUNT(DISTINCT userId) numUsers,
  COUNT(DISTINCT movieId) numMovies,
  COUNT(*) totalRatings
FROM
  movies.movielens_ratings
"

bq query --use_legacy_sql=false \
"
SELECT
  *
FROM
  movies.movielens_movies_raw
WHERE
  movieId < 5
"

bq query --use_legacy_sql=false \
"
CREATE OR REPLACE TABLE
  movies.movielens_movies AS
SELECT
  * REPLACE(SPLIT(genres, '|') AS genres)
FROM
  movies.movielens_movies_raw
"

bq query --use_legacy_sql=false \
"
SELECT * FROM ML.EVALUATE(MODEL \`cloud-training-prod-bucket.movies.movie_recommender\`)
"

bq query --use_legacy_sql=false \
"
SELECT
  *
FROM
  ML.PREDICT(MODEL \`cloud-training-prod-bucket.movies.movie_recommender\`,
    (
    SELECT
      movieId,
      title,
      903 AS userId
    FROM
      \`movies.movielens_movies\`,
      UNNEST(genres) g
    WHERE
      g = 'Comedy' ))
ORDER BY
  predicted_rating DESC
LIMIT
  5  
"

bq query --use_legacy_sql=false \
"
SELECT
  *
FROM
  ML.PREDICT(MODEL \`cloud-training-prod-bucket.movies.movie_recommender\`,
    (
    WITH
      seen AS (
      SELECT
        ARRAY_AGG(movieId) AS movies
      FROM
        movies.movielens_ratings
      WHERE
        userId = 903 )
    SELECT
      movieId,
      title,
      903 AS userId
    FROM
      movies.movielens_movies,
      UNNEST(genres) g,
      seen
    WHERE
      g = 'Comedy'
      AND movieId NOT IN UNNEST(seen.movies) ))
ORDER BY
  predicted_rating DESC
LIMIT
  5
"

bq query --use_legacy_sql=false \
"
SELECT
*
FROM
ML.PREDICT(MODEL \`cloud-training-prod-bucket.movies.movie_recommender\`,
  (
  WITH
    allUsers AS (
    SELECT
      DISTINCT userId
    FROM
      movies.movielens_ratings )
  SELECT
    96481 AS movieId,
    (
    SELECT
      title
    FROM
      movies.movielens_movies
    WHERE
      movieId=96481) title,
    userId
  FROM
    allUsers ))
ORDER BY
predicted_rating DESC
LIMIT
100
"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
