/*
 ***************************************************************************
  redoxwatertype.sql

  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017

  Redox water type query workflow split for simplicity:

  -1 View mstvw_watertype1_redox_compounds:             Extracts redox compounds
  -2 Materialized mstmvw_watertype1_redox_compounds:    Materialize
  -3 View mstvw_watertype2_deconcat:                    Split concat attribute and amount from pivot
  -4 Materialized view mstmvw_watertype2_deconcat:      Materialize
  -5 View mstvw_watertype3_redox_calc:                  Calculate redox type of sample
  -6 Materialized view mstmvw_watertype4_alldates       Materialize all dates
  -7 Materialized view mstmvw_watertype4_latestdates    Materialize only latest dates

   begin                : 2018-01-16
   copyright            : (C) 2018 EPA
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

/*
  REFRESH MATERIALIZED VIEW jupiter.mstmvw_vandtype1;
  REFRESH MATERIALIZED VIEW jupiter.mstmvw_vandtype2;
  REFRESH MATERIALIZED VIEW jupiter.mstmvw_vandtype3; --? CASCADING UPDATE ?
  --DROP VIEW IF EXISTS jupiter.mstvw_vandtype1 CASCADE;
*/

BEGIN;

/*
  Water type pivot query
*/
DROP VIEW IF EXISTS jupiter.mstvw_watertype1_redox_compounds CASCADE;

CREATE VIEW jupiter.mstvw_watertype1_redox_compounds AS (
  WITH
      borehole_sample AS (
        SELECT
          b.boreholeno,
          b.geom,
          i.intakeno,
          scr.screenno AS filterno,
          scr.top AS filter_top,
          scr.bottom AS filter_bund,
          cs.sampleid,
          cs.sampledate
        FROM jupiter.borehole b
          INNER JOIN jupiter.grwchemsample cs USING (boreholeno)
          INNER JOIN jupiter.intake i USING (boreholeno)
          INNER JOIN jupiter.screen scr ON i.boreholeno = scr.boreholeno
          INNER JOIN jupiter.code c ON b.use = c.code
        WHERE c.codetype = 17
      --[2017-04-07 10:27:57] 323 rows retrieved starting from 1 in 124ms (execution: 90ms, fetching: 34ms)
    ),
      vandtype_crosstab AS (
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
                 'SELECT long_text FROM (VALUES (''Nitrat''), (''Jern''), (''Oxygen indhold''), (''Sulfat'')) s(long_text)'
             )
          AS ct(sampleid INTEGER,
                Nitrat TEXT,
                Jern TEXT,
                "Oxygen indhold" TEXT,
                Sulfat TEXT
             )
      --[2017-04-07 10:29:58] 500 rows retrieved starting from 1 in 1m 28s 137ms (execution: 1m 28s 73ms, fetching: 64ms)
    )
    SELECT
      row_number() OVER () AS row_id,
      b.boreholeno,
      b.intakeno,
      b.sampledate,
      b.filterno,
      b.filter_top,
      b.filter_bund,
      b.geom,
      vt.sampleid,
      vt.Nitrat AS "nitrat",
      vt.Jern AS "jern",
      vt."Oxygen indhold" AS "oxygen",
      vt.Sulfat AS "sulfat"
  FROM borehole_sample b
    INNER JOIN vandtype_crosstab vt USING (sampleid)
  WHERE vt.Nitrat IS NOT NULL AND vt.Jern IS NOT NULL AND vt."Oxygen indhold" IS NOT NULL AND vt.Sulfat IS NOT NULL
  ORDER BY b.boreholeno, b.sampledate, b.intakeno, b.filterno, b.filter_top
);

/*
  Materialized vandtype calculation - jalan/trini 30-11-2017
  --WHERE ca.amount NOT IN ( '<', '>', 'D', '!', 'B0')
*/
DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_watertype1_redox_compounds;

CREATE MATERIALIZED VIEW jupiter.mstmvw_watertype1_redox_compounds AS (
  SELECT * FROM jupiter.mstvw_watertype1_redox_compounds
);
--[2017-11-29 14:53:28] completed in 42s 389ms

/*
  Separate concat attribute and amount column on all four compounds
*/
DROP VIEW IF EXISTS jupiter.mstvw_watertype2_deconcat CASCADE;
CREATE OR REPLACE VIEW jupiter.mstvw_watertype2_deconcat AS (
  SELECT
    *,
    CASE
    WHEN left(nitrat, 1) = '<'
      THEN '<'
    END AS "attr_nitrat",
    CASE
    WHEN left(nitrat, 1) = '<'
      THEN to_number(right(nitrat, -1), '9999.99')
    ELSE to_number(nitrat, '9999.99')
    END AS "amount_nitrat",
    CASE
    WHEN left(jern, 1) = '<'
      THEN '<'
    END AS "attr_jern",
    CASE
    WHEN left(jern, 1) = '<'
      THEN to_number(right(jern, -1), '9999.99')
    ELSE to_number(jern, '9999.99')
    END AS "amount_jern",
    CASE
    WHEN left(oxygen, 1) = '<'
      THEN '<'
    END AS "attr_oxygen",
    CASE
    WHEN left(oxygen, 1) = '<'
      THEN to_number(right(oxygen, -1), '9999.99')
    ELSE to_number(oxygen, '9999.99')
    END AS "amount_oxygen",
    CASE
    WHEN left(sulfat, 1) = '<'
      THEN '<'
    END AS "attr_sulfat",
    CASE
    WHEN left(sulfat, 1) = '<'
      THEN to_number(right(sulfat, -1), '9999.99')
    ELSE to_number(sulfat, '9999.99')
    END AS "amount_sulfat"
  FROM jupiter.mstvw_watertype1_redox_compounds
);

--SELECT to_number('12.73', '9999.99');

DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_watertype2_deconcat;

CREATE MATERIALIZED VIEW jupiter.mstmvw_watertype2_deconcat AS (
  SELECT * FROM jupiter.mstvw_watertype2_deconcat
);

/*
  Perform the final redox vandtype query
*/
DROP VIEW IF EXISTS jupiter.mstvw_watertype3_redox_calc;

CREATE OR REPLACE VIEW jupiter.mstvw_watertype3_redox_calc AS (
  SELECT
    *,
    CASE
      -- Oxyderet
      WHEN amount_nitrat > 1 AND amount_jern >= 0.2 THEN 'X'
      WHEN amount_nitrat > 1 AND amount_jern < 0.2 AND amount_oxygen <= 1 THEN 'B'
      WHEN amount_nitrat > 1 AND amount_jern < 0.2 AND amount_oxygen > 1 THEN 'A'
      -- reduceret
      WHEN amount_nitrat <= 1 AND amount_jern < 0.2 THEN 'Y'
      WHEN amount_nitrat <= 1 AND amount_jern > 0.2 AND amount_sulfat <= 20 THEN 'D'
      WHEN amount_nitrat <= 1 AND amount_jern > 0.2 AND amount_sulfat >= 20 AND amount_sulfat < 70 THEN 'C1'
      WHEN amount_nitrat <= 1 AND amount_jern > 0.2 AND amount_sulfat >= 70 THEN 'C2'
    END AS "vandtype"
  FROM jupiter.mstmvw_watertype2_deconcat
);

DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_watertype4_alldates;

CREATE MATERIALIZED VIEW jupiter.mstmvw_watertype4_alldates AS (
  SELECT * FROM jupiter.mstvw_watertype3_redox_calc
);

DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_watertype4_latestdate;

CREATE MATERIALIZED VIEW jupiter.mstmvw_watertype4_latestdate AS (
  SELECT DISTINCT ON (boreholeno)
    *
  FROM jupiter.mstvw_watertype3_redox_calc
  ORDER BY boreholeno, sampledate DESC
);

GRANT SELECT ON ALL TABLES IN SCHEMA jupiter TO jupiterrole;

COMMIT;
