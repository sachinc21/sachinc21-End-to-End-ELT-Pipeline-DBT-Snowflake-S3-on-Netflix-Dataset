# 🎬 End-to-End-ELT-Pipeline-S3-Snowflake-DBT-on-Netflix-Dataset
This repository contains an end-to-end ELT pipeline project focusing on transforming and modeling a simulated Netflix dataset (MovieLens) using **DBT (Data Build Tool)**, **Snowflake** as the data warehouse, and **Amazon S3** for data storage. The project demonstrates a modern ELT (Extract, Load, Transform) pipeline, emphasizing data quality, modularity, and robust data modeling practices.

## 📝 Project Overview

The primary objective of this project is to showcase the capabilities of DBT in building a scalable and maintainable data transformation layer. We take raw MovieLens data, load it into Snowflake, and then use DBT to apply various transformations, create a dimensional model, ensure data quality through testing, and generate comprehensive documentation. This project is a practical demonstration of data engineering best practices for analytics.

## 🛠️ Architecture

The project follows an ELT (Extract, Load, Transform) architecture:

1.  **Extract & Load (S3 & Snowflake):**
    * Raw MovieLens CSV data is stored in an **Amazon S3** bucket.
    * Data is then loaded directly into a "raw" schema in **Snowflake** using Snowflake's `COPY INTO` command.

2.  **Transform (DBT on Snowflake):**
    * **DBT** connects to Snowflake and orchestrates all data transformations.
    * Data flows through a series of layers:
        * **Staging Layer:** Initial cleaning and standardization of raw data (e.g., renaming columns, basic type casting).
        * **Dimensional Layer (Dim & Fact):** Creation of star schema tables (`dim_movies`, `dim_users`, `fct_ratings`, `fct_genome_scores`) optimized for analytical queries.
        * **Mart Layer:** Final aggregated or specialized tables for specific business use cases (e.g., `mart_movie_releases`).

3.  **Analysis & Reporting:**
    * The transformed data in Snowflake can then be connected to Business Intelligence (BI) tools (e.g., Looker Studio, Power BI, Tableau) for dashboarding and reporting.

## 🧰 Tech Stack

| Component         | Tool                    |
|-------------------|------------------------|
| ☁️ Cloud Storage  | Amazon S3               |
| 🧊 Data Warehouse | Snowflake               |
| 🔷 Transformation | dbt (open-source core)  |
| 🎞 Dataset        | MovieLens 20M           |
| 💻 Language       | SQL + YAML              |
| 🖥️ IDE            | VS Code + dbt CLI       |

---

## 🚀 Setup and Installation

Follow these steps to set up the project locally and connect to your cloud resources.

### AWS S3 Setup

1.  **Create an AWS Account:** If you don't have one, sign up for a free tier account at [aws.amazon.com](https://aws.amazon.com/).

2.  **Create an S3 Bucket:**
    * Go to the S3 service in your AWS Console.
    * Click "Create bucket" and provide a **globally unique** name (e.g., `netflix-dataset-sachin`).
    * Choose a region close to you.
    * Keep default settings for now (or adjust as per your security requirements).

3.  **Upload MovieLens Data:**
    * Download the MovieLens 20M dataset from [grouplens.org/datasets/movielens/20m/](https://grouplens.org/datasets/movielens/20m/).
    * Extract the `ml-20m.zip` file.
    * Upload the following CSV files from the extracted folder to your S3 bucket: `links.csv`, `movies.csv`, `ratings.csv`, `tags.csv`, `genome-scores.csv`, `genome-tags.csv`.
      
    <img width="1867" height="792" alt="Screenshot 2025-07-21 142827" src="https://github.com/user-attachments/assets/7f77cc23-b236-4a19-af0e-4847cff284c5" />

4.  **Create IAM User for Snowflake Access:**
    * Go to IAM service in your AWS Console.
    * Create a new user (e.g., `snowflake-s3-user`).
    * Grant this user programmatic access (access key & secret key).
    * Attach a policy that grants `AmazonS3FullAccess` to your specific bucket (or `s3:*` if you prefer broader access for this project).
    * **Download the CSV file containing the Access Key ID and Secret Access Key.** **Store these securely; they will only be shown once.**

### Snowflake Setup

1.  **Create a Snowflake Account:** Sign up for a 30-day free trial at [snowflake.com](https://www.snowflake.com/).

2.  **Log in to Snowflake UI (Snowsight):**

3.  **Create Database, Schema, Role, and User:**
    * Open a new SQL Worksheet.
    * Execute the following SQL commands to set up your environment. Replace `your_password` with a strong password.

    ```sql
    -- Use ADMIN role for setup
    USE ROLE ACCOUNTADMIN;

    -- Create a custom role for DBT
    CREATE ROLE TRANSFORM;
    GRANT ROLE TRANSFORM TO USER YOUR_SNOWFLAKE_ROOT_USERNAME; -- Replace YOUR_SNOWFLAKE_ROOT_USERNAME

    -- Create a dedicated warehouse
    CREATE WAREHOUSE COMPUTE_WH WITH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
    GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE TRANSFORM;

    -- Create a database and schemas
    CREATE DATABASE MOVIELENS;
    CREATE SCHEMA MOVIELENS.RAW;
    CREATE SCHEMA MOVIELENS.DEV;
    CREATE SCHEMA MOVIELENS.SNAPSHOTS;

    -- Grant permissions to the TRANSFORM role
    GRANT USAGE ON DATABASE MOVIELENS TO ROLE TRANSFORM;
    GRANT USAGE ON SCHEMA MOVIELENS.RAW TO ROLE TRANSFORM;
    GRANT USAGE ON SCHEMA MOVIELENS.DEV TO ROLE TRANSFORM;
    GRANT USAGE ON SCHEMA MOVIELENS.SNAPSHOTS TO ROLE TRANSFORM;

    GRANT CREATE TABLE ON SCHEMA MOVIELENS.RAW TO ROLE TRANSFORM;
    GRANT CREATE VIEW ON SCHEMA MOVIELENS.RAW TO ROLE TRANSFORM;
    GRANT CREATE TABLE ON SCHEMA MOVIELENS.DEV TO ROLE TRANSFORM;
    GRANT CREATE VIEW ON SCHEMA MOVIELENS.DEV TO ROLE TRANSFORM;
    GRANT CREATE TABLE ON SCHEMA MOVIELENS.SNAPSHOTS TO ROLE TRANSFORM;
    GRANT CREATE VIEW ON SCHEMA MOVIELENS.SNAPSHOTS TO ROLE TRANSFORM;

    GRANT SELECT ON ALL TABLES IN SCHEMA MOVIELENS.RAW TO ROLE TRANSFORM;
    GRANT SELECT ON ALL VIEWS IN SCHEMA MOVIELENS.RAW TO ROLE TRANSFORM;
    GRANT SELECT ON ALL TABLES IN SCHEMA MOVIELENS.DEV TO ROLE TRANSFORM;
    GRANT SELECT ON ALL VIEWS IN SCHEMA MOVIELENS.DEV TO ROLE TRANSFORM;
    GRANT SELECT ON ALL TABLES IN SCHEMA MOVIELENS.SNAPSHOTS TO ROLE TRANSFORM;
    GRANT SELECT ON ALL VIEWS IN SCHEMA MOVIELENS.SNAPSHOTS TO ROLE TRANSFORM;

    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA MOVIELENS.DEV TO ROLE TRANSFORM;
    GRANT ALL PRIVILEGES ON ALL VIEWS IN SCHEMA MOVIELENS.DEV TO ROLE TRANSFORM;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA MOVIELENS.SNAPSHOTS TO ROLE TRANSFORM;
    GRANT ALL PRIVILEGES ON ALL VIEWS IN SCHEMA MOVIELENS.SNAPSHOTS TO ROLE TRANSFORM;

    -- Create a dedicated DBT user
    CREATE USER DBT_USER PASSWORD = 'your_password' DEFAULT_ROLE = TRANSFORM DEFAULT_WAREHOUSE = COMPUTE_WH;
    GRANT ROLE TRANSFORM TO USER DBT_USER;
    ```

4.  **Create Snowflake Stage for S3:**
    * In a new SQL Worksheet, execute the following, replacing placeholders with your S3 bucket name and AWS credentials:

    
    * **Important:** Using `STORAGE INTEGRATION` is a more secure and recommended approach for production environments. For this project, a `STAGE` with credentials is used for simplicity.

5.  **Load Raw Data into Snowflake Tables:**
    * For each CSV file uploaded to S3, create a corresponding table in the `MOVIELENS.RAW` schema and load data using `COPY INTO`.
    * Example for `movies.csv`:

   ```sql
        -- Set Defaults
    USE WAREHOUSE COMPUTE_WH;
    USE DATABASE MOVIELENS;
    USE SCHEMA RAW;

    -- Integrating Data from S3
    CREATE OR REPLACE STAGE netflixstage
        URL = 's3://netflix-dataset-sachin'
        CREDENTIALS = (
            AWS_KEY_ID = 'AKI***MQMAKFB**HUWD*',
            AWS_SECRET_KEY = 'x9k34UT/l42UAVyqhI5m8eli3P3TFcw3SxvUvxkd'
        );

    -- Load raw movies
    CREATE OR REPLACE TABLE raw_movies (
        movieID INTEGER,
        title STRING,
        genres STRING
    );

    COPY INTO raw_movies
    FROM @netflixstage/movies.csv
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

    -- Preview
    SELECT * FROM raw_movies;

    -- Load raw ratings
    CREATE OR REPLACE TABLE raw_ratings (
        userId INTEGER,
        movieID INTEGER,
        rating FLOAT,
        timestamp BIGINT   
    );

    COPY INTO raw_ratings
    FROM @netflixstage/ratings.csv
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

    -- Load raw tags
    CREATE OR REPLACE TABLE raw_tags (
        userID INTEGER,
        movieID INTEGER,
        tag STRING,
        timestamp BIGINT
    );

    COPY INTO raw_tags
    FROM @netflixstage/tags.csv
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"')
    ON_ERROR = 'CONTINUE';

    -- Load raw genome scores
    CREATE OR REPLACE TABLE raw_genome_scores (
        movieID INTEGER,
        tagID INTEGER,
        relevance FLOAT
    );

    COPY INTO raw_genome_scores
    FROM @netflixstage/genome-scores.csv
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

    -- Load raw genome tags
    CREATE OR REPLACE TABLE raw_genome_tags (
        tagId INTEGER,
        tag STRING
    );

    COPY INTO raw_genome_tags
    FROM @netflixstage/genome-tags.csv
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

    -- Load raw links
    CREATE OR REPLACE TABLE raw_links (
        movieId INTEGER,
        imdbId INTEGER,
        tmdbId INTEGER
    );

    COPY INTO raw_links
    FROM @netflixstage/links.csv
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED


   ```


## How to Run

Navigate to the root of your `netflix-dbt-analysis` directory in your terminal (ensure your virtual environment is active).

1.  **Run all DBT Models:**
    ```bash
    dbt run
    ```
    This command will execute all models, creating views and tables in your Snowflake `DEV` schema based on their materialization configurations.
    
    <img width="1154" height="795" alt="Screenshot 2025-07-21 231614" src="https://github.com/user-attachments/assets/b8ab7b75-401c-49d9-9ac4-67d3817fb09a" />


3.  **Run Specific Models:**
    ```bash
    dbt run --select dim_movies
    dbt run --select fact_ratings
    ```

4.  **Run DBT Seeds (if new seed files are added):**
    ```bash
    dbt seed
    ```

5.  **Run DBT Snapshots (to capture SCD Type 2 changes):**
    ```bash
    dbt snapshot
    ```
    * To observe changes, first modify data in a source table (e.g., `src_tags` in Snowflake), then run `dbt snapshot` again. Query the `MOVIELENS.SNAPSHOTS.SNAP_TAGS` table to see the `dbt_valid_from` and `dbt_valid_to` columns.

6.  **Run DBT Tests:**
    ```bash
    dbt test
    ```
    This will execute all generic and singular tests defined in `schema.yml` and the `tests/` directory.

7.  **Generate and Serve Documentation:**
    ```bash
    dbt docs generate
    dbt docs serve
    ```
    Open your web browser to the URL provided (usually `http://localhost:8080`) to explore the project's documentation, data catalog, and lineage graph.
    
    <img width="1866" height="835" alt="Screenshot 2025-07-16 215218" src="https://github.com/user-attachments/assets/e923d544-49ae-43e3-84d9-c2e5c6fa0446" />

    <img width="1868" height="835" alt="Screenshot 2025-07-16 220915" src="https://github.com/user-attachments/assets/f9c2846d-4e41-4050-b9dc-1c9f3b8142f3" />

9.  **Compile Analysis Files:**
    ```bash
    dbt compile
    ```
    This compiles the SQL in your `analyses/` folder into executable SQL, which can then be copied and run directly in Snowflake or used by other tools. Compiled files are found in the `target/compiled/netflix/analyses/` directory.

## 🧩 Key DBT Concepts Demonstrated

* **Models:** SQL `SELECT` statements that define data transformations.
* **Materializations:** Strategies for persisting models in the data warehouse (e.g., `view`, `table`, `incremental`, `ephemeral`).
* **Snapshots:** Capturing historical changes of mutable tables (SCD Type 2).
* **Testing:** Ensuring data quality and integrity (generic and singular tests).
* **Documentation:** Automated generation of data dictionaries and lineage graphs.
* **Macros:** Reusable Jinja + SQL code blocks (functions).
* **Analysis:** Ad-hoc SQL queries that don't create permanent database objects.
* **Seeds:** Loading static CSV data into the data warehouse.
* **Sources:** Defining and documenting raw data sources in the data warehouse.
* **Packages:** Leveraging community-contributed DBT functionality (e.g., `dbt-utils`).

