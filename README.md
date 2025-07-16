# End-to-End-ELT-Pipeline-S3-Snowflake-DBT-on-Netflix-Dataset
This repository contains an end-to-end ELT pipeline project focusing on transforming and modeling a simulated Netflix dataset (MovieLens) using **DBT (Data Build Tool)**, **Snowflake** as the data warehouse, and **Amazon S3** for data storage. The project demonstrates a modern ELT (Extract, Load, Transform) pipeline, emphasizing data quality, modularity, and robust data modeling practices.

## Project Overview

The primary objective of this project is to showcase the capabilities of DBT in building a scalable and maintainable data transformation layer. We take raw MovieLens data, load it into Snowflake, and then use DBT to apply various transformations, create a dimensional model, ensure data quality through testing, and generate comprehensive documentation. This project is a practical demonstration of data engineering best practices for analytics.

## Architecture

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

## Technologies Used

* **Cloud Storage:** Amazon S3
* **Cloud Data Warehouse:** Snowflake
* **Data Transformation Tool:** DBT (Data Build Tool)
* **Database:** SQL
* **Version Control:** Git / GitHub
* **Local Development Environment:** Visual Studio Code, Python Virtual Environments

## Setup and Installation

Follow these steps to set up the project locally and connect to your cloud resources.

### AWS S3 Setup

1.  **Create an AWS Account:** If you don't have one, sign up for a free tier account at [aws.amazon.com](https://aws.amazon.com/).

2.  **Create an S3 Bucket:**
    * Go to the S3 service in your AWS Console.
    * Click "Create bucket" and provide a **globally unique** name (e.g., `yourname-netflix-dbt-data`).
    * Choose a region close to you.
    * Keep default settings for now (or adjust as per your security requirements).

3.  **Upload MovieLens Data:**
    * Download the MovieLens 20M dataset from [grouplens.org/datasets/movielens/20m/](https://grouplens.org/datasets/movielens/20m/).
    * Extract the `ml-20m.zip` file.
    * Upload the following CSV files from the extracted folder to your S3 bucket: `links.csv`, `movies.csv`, `ratings.csv`, `tags.csv`, `genome-scores.csv`, `genome-tags.csv`.

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

    ```sql
    USE WAREHOUSE COMPUTE_WH;
    USE DATABASE MOVIELENS;
    USE SCHEMA RAW;

    CREATE STAGE NETFLIX_STAGE
      URL='s3://your-s3-bucket-name/' -- Replace with your S3 bucket name
      CREDENTIALS=(AWS_KEY_ID='YOUR_AWS_ACCESS_KEY_ID' AWS_SECRET_KEY='YOUR_AWS_SECRET_ACCESS_KEY');
    ```
    * **Important:** Using `STORAGE INTEGRATION` is a more secure and recommended approach for production environments. For this project, a `STAGE` with credentials is used for simplicity.

5.  **Load Raw Data into Snowflake Tables:**
    * For each CSV file uploaded to S3, create a corresponding table in the `MOVIELENS.RAW` schema and load data using `COPY INTO`.
    * Example for `movies.csv`:

    ```sql
    USE WAREHOUSE COMPUTE_WH;
    USE DATABASE MOVIELENS;
    USE SCHEMA RAW;

    CREATE OR REPLACE TABLE RAW_MOVIES (
        MOVIEID INTEGER,
        TITLE VARCHAR,
        GENRES VARCHAR
    );

    COPY INTO RAW_MOVIES
    FROM @NETFLIX_STAGE/movies.csv
    FILE_FORMAT = (TYPE = CSV FIELD_DELIMITER = ',' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

    -- Repeat for ratings.csv, tags.csv, links.csv, genome-scores.csv, genome-tags.csv
    -- Adjust table schema and file names accordingly.
    ```
    * Refer to the original project source for full schema definitions and `COPY INTO` commands for all files.


## How to Run

Navigate to the root of your `netflix-dbt-analysis` directory in your terminal (ensure your virtual environment is active).

1.  **Run all DBT Models:**
    ```bash
    dbt run
    ```
    This command will execute all models, creating views and tables in your Snowflake `DEV` schema based on their materialization configurations.

2.  **Run Specific Models:**
    ```bash
    dbt run --select dim_movies
    dbt run --select fact_ratings
    ```

3.  **Run DBT Seeds (if new seed files are added):**
    ```bash
    dbt seed
    ```

4.  **Run DBT Snapshots (to capture SCD Type 2 changes):**
    ```bash
    dbt snapshot
    ```
    * To observe changes, first modify data in a source table (e.g., `src_tags` in Snowflake), then run `dbt snapshot` again. Query the `MOVIELENS.SNAPSHOTS.SNAP_TAGS` table to see the `dbt_valid_from` and `dbt_valid_to` columns.

5.  **Run DBT Tests:**
    ```bash
    dbt test
    ```
    This will execute all generic and singular tests defined in `schema.yml` and the `tests/` directory.

6.  **Generate and Serve Documentation:**
    ```bash
    dbt docs generate
    dbt docs serve
    ```
    Open your web browser to the URL provided (usually `http://localhost:8080`) to explore the project's documentation, data catalog, and lineage graph.

7.  **Compile Analysis Files:**
    ```bash
    dbt compile
    ```
    This compiles the SQL in your `analyses/` folder into executable SQL, which can then be copied and run directly in Snowflake or used by other tools. Compiled files are found in the `target/compiled/netflix/analyses/` directory.

## Key DBT Concepts Demonstrated

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

