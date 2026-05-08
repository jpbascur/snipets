-- =============================================================
-- CO-CITATION SEARCH BASED ON JANSSENS & GWINN (2015)
-- =============================================================
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
-- WHERE TO RUN IT:
-- Google BigQuery console (https://console.cloud.google.com/bigquery)
-- The dataset is publicly available at no cost to query under
-- Google's free tier (1 TB/month free).
-- Project: cwts-leiden
-- Dataset: openalex_2025aug
--
-- HOW TO RUN IT:
-- 1. Open the BigQuery console and create or select a project.
-- 2. Paste this query into the query editor.
-- 3. In the seed_papers CTE, replace the example work_id
--    values with the integer IDs of your seed papers.
--    IDs can be found in the `work` table (work_id column)
--    or derived from OpenAlex IDs (e.g. W2741809807 -> 2741809807).
-- 4. Add or remove seeds by adding/removing lines in the
--    UNNEST([...]) array.
-- 5. Click "Run". Results are ranked by co-citation frequency,
--    highest first.
-- =============================================================


WITH seed_papers AS (
    SELECT work_id
    FROM UNNEST([
        2150220236        --  <- Replace this with your paper
        --,2755950973     --  <- You can add any number of papers
        --,...
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
