WITH raw_tags AS (
    SELECT * FROM MOVIELENS.RAW.RAW_TAGS
)

SELECT
    userID as user_id,
    movieID as movie_id,
    tag,
    TO_TIMESTAMP_LTZ(timestamp) AS tag_timestamp
FROM raw_tags