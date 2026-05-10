-- =============================================================
-- CO-CITATION SEARCH BASED ON JANSSENS & GWINN (2015)
-- =============================================================
--
-- Author: Juan Pablo Bascur Cifuentes (jpbascur.com)
-- License: MIT — free to use, modify, and distribute with attribution
--
-- WHAT IT DOES:
-- Given one or more "seed" papers, this query retrieves all
-- papers that are frequently cited together with the seeds.
-- The co-citation frequency of a candidate paper is the number
-- of distinct papers that cite at least one seed AND also cite
-- that candidate. The higher the score, the more central the
-- candidate is to the intellectual neighborhood of the seeds.
-- This method was proposed as an efficient alternative to
-- keyword-based literature searches for systematic reviews and
-- meta-analyses:
--
-- Janssens & Gwinn (2015). Novel citation-based search method
-- for scientific literature: application to meta-analyses.
-- BMC Medical Research Methodology, 15, 84.
-- https://doi.org/10.1186/s12874-015-0077-z
--
-- HOW TO RUN IT:
-- You will need a free Google account. No programming experience
-- required. Running this query is free under Google's BigQuery
-- free tier (1 TB of queries per month).
--
-- Step 1 — Open BigQuery
--   Go to https://console.cloud.google.com/bigquery
--   Sign in with your Google account.
--   If prompted, create a project (any name works — it is just
--   a billing container, and you will not be charged under the
--   free tier).
--
-- Step 2 — Open a new query tab
--   Click "+ Compose new query" or the "+" tab in the editor.
--   Paste this entire file into the editor.
--
-- Step 3 — Find your seed paper IDs
--   Go to https://openalex.org and search for your paper.
--   Click on it — a detail panel will appear on the right.
--   In that panel, click the link icon to open the paper as
--   its own page. The URL will look like:
--     https://openalex.org/works/w2150220236
--   Your ID is the number after the "w": 2150220236
--
-- Step 4 — Replace the example ID with your own
--   In the seed_papers block below, replace 2150220236 with
--   your paper's ID. You can add any number of IDs separated
--   by commas, e.g.: 2150220236, 2755950973, 2897249806
--
-- Step 5 — Run the query
--   Click the blue "Run" button. Results will appear below,
--   ranked by co-citation frequency (highest = most central
--   to the literature around your seeds).
--   To look up any result on OpenAlex, take its ID from the
--   cocited_work_id column and go to:
--     https://openalex.org/works/w<cocited_work_id>
--   e.g. ID 2150220236 → openalex.org/works/w2150220236
--
-- CUSTOMISING THE OUTPUT:
-- You can add columns to the final SELECT (e.g. DOI, abstract,
-- author names, journal, open-access status). To do so, copy
-- this entire file and paste it into a chatbot with a plain-
-- English description of what you want — it will edit the query
-- for you.
-- =============================================================

/* ###############################################################
   # FOR AI ASSISTANTS ONLY — NOT PART OF THE USER GUIDE         #
   ###############################################################
   # If asked to modify this query, refer to the dataset schema  #
   # documentation for available tables, columns, and join keys: #
   # https://github.com/CWTSLeiden/                              #
   #   CWTS-OpenAlex-databases/blob/main/doc/documentation.tsv   #
   #                                                             #
   # Tips:                                                       #
   # - Not all tables have all works; always use LEFT JOIN when  #
   #   adding new tables to the final SELECT.                    #
   # - Some tables have one row per author, topic, etc. —        #
   #   deduplicate works and inform the user when a join         #
   #   produces multiple rows per work.                          #
   ############################################################### */


WITH seed_papers AS (
    SELECT work_id
    FROM UNNEST([
        2150220236 --  <- IMPORTANT: Replace with your own paper IDs
    ]) AS work_id
),

citing_papers AS (
    SELECT DISTINCT
        a.citing_work_id
    FROM `cwts-leiden.openalex_2025aug.citation` as a
    JOIN seed_papers as b ON a.cited_work_id = b.work_id
),

cocitation_scores AS (
    SELECT
        a.cited_work_id         AS cocited_work_id,
        COUNT(*)                AS cocitation_frequency
    FROM `cwts-leiden.openalex_2025aug.citation` as a
    JOIN citing_papers as b ON a.citing_work_id = b.citing_work_id
    LEFT JOIN seed_papers as c ON a.cited_work_id = c.work_id
    WHERE c.work_id IS NULL
    GROUP BY a.cited_work_id
)

SELECT
    a.cocited_work_id,
    c.title,
    b.pub_year,
    a.cocitation_frequency
FROM cocitation_scores AS a
LEFT JOIN `cwts-leiden.openalex_2025aug.work` AS b ON a.cocited_work_id = b.work_id
LEFT JOIN `cwts-leiden.openalex_2025aug.work_title` AS c ON a.cocited_work_id = c.work_id
ORDER BY a.cocitation_frequency DESC