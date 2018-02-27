/*
 ***************************************************************************
  bulk_grw_chemistry.sql

  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017

  -Query all groundwater (grw) analysis for a single compound in any borehole

   begin                : 2018-02-14
   copyright            : (C) 2018 EPA
   email                : jalan@mst.dk

 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************
*/

BEGIN;

  DROP VIEW IF EXISTS jupiter.mstvw_bulk_grwchem CASCADE;

  -- unit returns as part of pseudo record from function mst_compoundname_to_unit
  CREATE OR REPLACE VIEW jupiter.mstvw_bulk_grwchem AS (
    SELECT
      row_number() OVER (ORDER BY b.boreholeno, s.sampledate) AS row_id,
      b.boreholeno,
      b.use AS bore_use,
      i.intakeno,
      s.sampleid,
      s.sampledate::DATE,
      a.compoundno,
      a.attribute,
      a.amount,
      (SELECT jupiter.mst_compoundno_to_unit(s.sampleid::INTEGER, a.compoundno::INTEGER)) AS unit,
      current_date AS last_refresh,
      b.geom
    FROM
      jupiter.borehole b
      INNER JOIN jupiter.intake i USING (boreholeno)
      INNER JOIN jupiter.grwchemsample s USING (boreholeno)
      INNER JOIN jupiter.grwchemanalysis a ON a.sampleid = s.sampleid
    ORDER BY b.boreholeno, s.sampledate
  );

  --SELECT count(*) FROM jupiter.mstvw_bulk_grwchem;  --13.376.002
  --SELECT count(*) FROM jupiter.mstvw_bulk_grwchem WHERE compoundno = 1176;  --467.768
  --SELECT * FROM jupiter.mstvw_bulk_grwchem WHERE compoundno = 1176 LIMIT 100;
  SELECT count(row_id) AS counter, row_id FROM jupiter.mstvw_bulk_grwchem GROUP BY row_id;


  CREATE MATERIALIZED VIEW jupiter.mstmvw_bulk_grwchem_alldates AS (
      SELECT * FROM jupiter.mstvw_bulk_grwchem
  );
  -- [2018-02-19 13:57:22] completed in 53m 53s 567ms

	-- Add gist and btree index to mstmvw_bulk_grwchem_alldates
  DROP INDEX IF EXISTS mstmvw_bulk_grwchem_alldates_idx_compoundno;
  CREATE INDEX IF NOT EXISTS mstmvw_bulk_grwchem_alldates_idx_compoundno
    ON jupiter.mstmvw_bulk_grwchem_alldates USING BTREE (compoundno);
  -- [2018-02-19 14:28:00] completed in 33s 359ms

  DROP INDEX IF EXISTS mstmvw_bulk_grwchem_alldates_idx_geom;
  CREATE INDEX IF NOT EXISTS mstmvw_bulk_grwchem_alldates_idx_geom
    ON jupiter.mstmvw_bulk_grwchem_alldates USING GIST (geom);
  -- [2018-02-19 14:32:39] completed in 3m 9s 11ms

  --SELECT * FROM jupiter.mstvw_bulk_grwchem WHERE compoundno = 1176;
  --[2018-02-19 14:34:43] 500 rows retrieved starting from 1 in 1m 11s 556ms (execution: 1m 11s 468ms, fetching: 88ms)

  CREATE MATERIALIZED VIEW jupiter.mstmvw_bulk_grwchem_latestdates AS (
      SELECT
        DISTINCT ON (boreholeno)
        *
      FROM jupiter.mstvw_bulk_grwchem
      ORDER BY boreholeno, sampledate
  );
  -- [2018-02-19 15:32:51] completed in 56m 16s 886ms

	-- Add gist and btree index to mstmvw_bulk_grwchem_latestdates
  DROP INDEX IF EXISTS mstmvw_bulk_grwchem_latestdates_idx_compoundno;
  CREATE INDEX IF NOT EXISTS mstmvw_bulk_grwchem_latestdates_idx_compoundno
    ON jupiter.mstmvw_bulk_grwchem_latestdates USING BTREE (compoundno);
  -- [2018-02-20 09:56:16] completed in 78ms

  DROP INDEX IF EXISTS mstmvw_bulk_grwchem_latestdates_idx_geom;
  CREATE INDEX IF NOT EXISTS mstmvw_bulk_grwchem_latestdates_idx_geom
    ON jupiter.mstmvw_bulk_grwchem_latestdates USING GIST (geom);
  -- [2018-02-20 09:56:59] completed in 312ms

  GRANT SELECT ON ALL TABLES IN SCHEMA jupiter TO jupiterrole;

COMMIT;

SELECT count(*) FROM jupiter.mstmvw_bulk_grwchem_alldates;    --13.376.002
SELECT count(*) FROM jupiter.mstmvw_bulk_grwchem_latestdates; --35.968

