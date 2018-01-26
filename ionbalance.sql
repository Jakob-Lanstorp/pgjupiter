/* 
 ***************************************************************************
  ionbalance.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017
                                 
  -Materialized view handling ion balance of drinkwaterplant boreholes
  
   begin                : 2017-03-14
   copyright            : (C) 2017 EPA
   email                : jalan@mst.dk
 
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************
*/

BEGIN;

/*
  View for qjupiter to access ionbalance
*/
DROP VIEW IF EXISTS jupiter.mstvw_ionbalance CASCADE;

CREATE OR REPLACE VIEW jupiter.mstvw_ionbalance AS (
  WITH
      borehole_sample AS (
        SELECT
          b.boreholeno,
          b.geom,
          i.intakeno,
          cs.sampleid,
          cs.sampledate
        FROM jupiter.borehole b
          INNER JOIN jupiter.grwchemsample cs USING (boreholeno)
          INNER JOIN jupiter.intake i USING (boreholeno)
          INNER JOIN jupiter.code c ON b.use = c.code
        --INNER JOIN kort.osd_vordingborg v ON st_dwithin(b.geom, v.geom, 100)
        WHERE c.codetype = 17
      --[2017-04-07 10:27:57] 323 rows retrieved starting from 1 in 124ms (execution: 90ms, fetching: 34ms)
    ),
      inorganic_crosstab AS (
        SELECT *
        FROM crosstab
             (
                 'SELECT
                   ca.sampleid,
                   cl.long_text,
                   concat(ca.attribute, ca.amount)
               FROM jupiter.grwchemsample cs
               INNER JOIN jupiter.grwchemanalysis ca ON ca.sampleid = cs.sampleid
               INNER JOIN jupiter.compoundlist cl ON ca.compoundno = cl.compoundno
               ORDER BY 1,2',
                 'SELECT long_text FROM (VALUES ' ||
                 '(''Chlorid''), ' ||
                 '(''Hydrogencarbonat''), ' ||
                 '(''Sulfat''), ' ||
                 '(''Nitrat''), ' ||
                 '(''Calcium''), ' ||
                 '(''Magnesium''), ' ||
                 '(''Natrium''), ' ||
                 '(''Kalium'')) ' ||
                 's(long_text)'
             )
          AS ct(sampleid INTEGER,
             Chlorid TEXT,
             Hydrogencarbonat TEXT,
             Sulfat TEXT,
             Nitrat TEXT,
             Calcium TEXT,
             Magnesium TEXT,
             Natrium TEXT,
             Kalium TEXT
             )
      --[2017-04-07 10:29:58] 500 rows retrieved starting from 1 in 1m 28s 137ms (execution: 1m 28s 73ms, fetching: 64ms)
    ),
      analysis_pivot AS (
        SELECT
          row_number()
          OVER () AS row_id,
          b.boreholeno,
          b.intakeno,
          b.sampledate,
          b.geom,
          ic.*
        FROM borehole_sample b
          INNER JOIN inorganic_crosstab ic USING (sampleid)
    ),
      anion AS (
        SELECT
          boreholeno,
          intakeno,
          geom,
          sampleid,
          sampledate :: DATE,
          round(
              chlorid :: NUMERIC / 35.5 +
              hydrogencarbonat :: NUMERIC / 61.0 +
              sulfat :: NUMERIC * 2 / 96.1 +
              nitrat :: NUMERIC / 62.0, 2) sum_anion
        FROM
          analysis_pivot
        WHERE
          --left(chlorid, 1) NOT IN ('<', '>', '!', 'B') AND chlorid IS NOT NULL AND
          --left(hydrogencarbonat, 1) NOT IN ('<', '>', '!', 'B') AND hydrogencarbonat IS NOT NULL AND
          --left(sulfat, 1) NOT IN ('<', '>', '!', 'B') AND sulfat IS NOT NULL AND
          --left(nitrat, 1) NOT IN ('<', '>', 'D', '!', 'B') AND nitrat IS NOT NULL --what does D mean in column attribute of grwchemanalysis?
          jupiter.isnumeric(chlorid) AND jupiter.isnumeric(hydrogencarbonat) AND jupiter.isnumeric(sulfat) AND jupiter.isnumeric(nitrat)
    ),
      cation AS (
        SELECT
          sampleid,
          round(
              calcium :: NUMERIC * 2 / 40.1 +
              magnesium :: NUMERIC * 2 / 24.3 +
              natrium :: NUMERIC / 23.0 +
              kalium :: NUMERIC / 39.1, 2) sum_cation
        FROM
          analysis_pivot
        WHERE
          --LEFT (calcium, 1) NOT IN ('<', '>', '!', 'B') AND calcium IS NOT NULL AND
          --LEFT (magnesium, 1) NOT IN ('<', '>', '!', 'B') AND magnesium IS NOT NULL AND
          --LEFT (natrium, 1) NOT IN ('<', '>', '!', 'B') AND natrium IS NOT NULL AND
          --LEFT (kalium, 1) NOT IN ('<', '>', 'D', '!', 'B') AND kalium IS NOT NULL
          jupiter.isnumeric(calcium) AND jupiter.isnumeric(magnesium) AND jupiter.isnumeric(natrium) AND jupiter.isnumeric(kalium)
    )
  SELECT
    row_number() OVER () AS row_id,
    a.*,
    c.sum_cation,
    round((c.sum_cation - a.sum_anion) / (c.sum_cation + a.sum_anion) * 100) ionbalance
  FROM
    anion a
    INNER JOIN cation c USING (sampleid)
  WHERE a.sum_anion > 0 AND c.sum_cation > 0
);

/*
  Materialized ionbalance calculation for all sample dates
  --WHERE ca.amount NOT IN ( '<', '>', 'D', '!', 'B0')
*/
DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_ionbalance_all_dates;

CREATE MATERIALIZED VIEW jupiter.mstmvw_ionbalance_all_dates AS (
  SELECT * FROM jupiter.mstvw_ionbalance
);
--[2017-12-11 14:57:12] completed in 44s 948ms
REFRESH MATERIALIZED VIEW jupiter.mstmvw_ionbalance_all_dates;

/*
  Materialized ionbalance calculation for only latest sample dates
  --WHERE ca.amount NOT IN ( '<', '>', 'D', '!', 'B0')
*/
DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_ionbalance_latest_dates;

CREATE MATERIALIZED VIEW jupiter.mstmvw_ionbalance_latest_dates AS (
  SELECT
    DISTINCT ON (boreholeno)
    *
  FROM
    jupiter.mstvw_ionbalance
  ORDER BY boreholeno, sampledate DESC
);
--[2017-12-11 14:58:33] completed in 46s 359ms
--REFRESH MATERIALIZED VIEW jupiter.mstmvw_ionbalance_latest_dates;

GRANT SELECT ON ALL TABLES IN SCHEMA jupiter TO jupiterrole;

COMMIT;
