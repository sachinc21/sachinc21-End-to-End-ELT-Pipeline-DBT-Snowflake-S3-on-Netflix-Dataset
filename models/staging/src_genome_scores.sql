WITH raw_genome_scores AS (
    SELECT * FROM MOVIELENS.RAW.RAW_GENOME_SCORES
)

SELECT
    movieID as movie_id,
    tagID as tag_id,
    relevance
FROM raw_genome_scores