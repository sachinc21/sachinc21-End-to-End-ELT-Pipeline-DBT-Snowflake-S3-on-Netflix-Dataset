{{ config(materialized = 'table')}}
WITH raw_ratings AS (
    SELECT * FROM MOVIELENS.RAW.RAW_RATINGS
)

SELECT 
    userID as user_id,
    movieID as movie_id,
    rating,
    TO_TIMESTAMP_LTZ(timestamp) AS rating_timestamp
FROM raw_ratings