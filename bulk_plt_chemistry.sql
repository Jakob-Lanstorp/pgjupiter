/*
 ***************************************************************************
  bulk_plt_chemistry.sql - drinking water plant chemistry (aka ~rentvand)

  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017

  -Query all groundwater (plt) analysis for a single compound in any borehole

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

  DROP VIEW IF EXISTS jupiter.mstvw_bulk_pltchem CASCADE;

  -- unit returns as part of pseudo record from function mst_compoundname_to_unit
  CREATE OR REPLACE VIEW jupiter.mstvw_bulk_pltchem AS (
    SELECT
      row_number() OVER (ORDER BY dp.plantid, s.sampledate) AS row_id,
      dp.plantid,
      s.sampleid,
      s.sampledate::DATE,
      a.compoundno,
      a.attribute,
      a.amount,
      (SELECT jupiter.mst_compoundno_to_unit(s.sampleid::INTEGER, a.compoundno::INTEGER)) AS unit,
      current_date AS last_refresh,
      dp.geom
    FROM
      jupiter.drwplant dp
      INNER JOIN jupiter.pltchemsample s USING (plantid)
      INNER JOIN jupiter.pltchemanalysis a ON a.sampleid = s.sampleid
    ORDER BY dp.plantid, s.sampledate
  );

  CREATE MATERIALIZED VIEW jupiter.mstmvw_bulk_pltchem_alldates AS (
      SELECT * FROM jupiter.mstvw_bulk_pltchem
  );
  -- [2018-02-20 13:58:12] completed in 7m 38s 210ms

	-- Add gist and btree index to mstmvw_bulk_pltchem_alldates
  DROP INDEX IF EXISTS mstmvw_bulk_pltchem_alldates_idx_compoundno;
  CREATE INDEX IF NOT EXISTS mstmvw_bulk_pltchem_alldates_idx_compoundno
    ON jupiter.mstmvw_bulk_pltchem_alldates USING BTREE (compoundno);
  -- [2018-02-20 13:58:33] completed in 20s 802ms

  DROP INDEX IF EXISTS mstmvw_bulk_pltchem_alldates_idx_geom;
  CREATE INDEX IF NOT EXISTS mstmvw_bulk_pltchem_alldates_idx_geom
    ON jupiter.mstmvw_bulk_pltchem_alldates USING GIST (geom);
  -- 2018-02-20 14:00:35] completed in 2m 2s 36ms

  CREATE MATERIALIZED VIEW jupiter.mstmvw_bulk_pltchem_latestdates AS (
      SELECT
        DISTINCT ON (plantid)
        *
      FROM jupiter.mstvw_bulk_pltchem
      ORDER BY plantid, sampledate
  );
  -- [2018-02-20 14:08:20] completed in 7m 44s 254ms

	-- Add gist and btree index to mstmvw_bulk_pltchem_latestdates
  DROP INDEX IF EXISTS mstmvw_bulk_pltchem_latestdates_idx_compoundno;
  CREATE INDEX IF NOT EXISTS mstmvw_bulk_pltchem_latestdates_idx_compoundno
    ON jupiter.mstmvw_bulk_pltchem_latestdates USING BTREE (compoundno);
  -- [2018-02-20 14:08:20] completed in 93ms

  DROP INDEX IF EXISTS mstmvw_bulk_pltchem_latestdates_idx_geom;
  CREATE INDEX IF NOT EXISTS mstmvw_bulk_pltchem_latestdates_idx_geom
    ON jupiter.mstmvw_bulk_pltchem_latestdates USING GIST (geom);
  -- [2018-02-20 14:08:20] completed in 328ms

  GRANT SELECT ON ALL TABLES IN SCHEMA jupiter TO jupiterrole;

COMMIT;
