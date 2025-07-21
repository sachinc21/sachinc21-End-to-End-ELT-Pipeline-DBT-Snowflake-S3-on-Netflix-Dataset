WITH raw_links AS (
    SELECT * FROM MOVIELENS.RAW.RAW_LINKS
)

SELECT
    movieID as movie_id,
    imdbID as imdb_id,
    tmdbID as tmdb_id
FROM raw_links