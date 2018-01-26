/*
 ***************************************************************************
  combined_chemistry.sql

  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017

  -Joining ionbalance, redoxwatertype on inorganic chemical measurement values

   begin                : 2018-01-14
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

--Test kald nedenstående fra qgis processing
--COPY (SELECT * FROM jupiter.inorganic_compound_crosstab LIMIT 10) TO 'd:\test_inorganic_compounds.csv' DELIMITERS ';' CSV HEADER;

--'SELECT long_text FROM (VALUES (''Calcium''), (''Chlorid''), (''Nitrat''),(''Nitrit'')) s(long_text)'
--'SELECT long_text FROM jupiter.compoundlist WHERE long_text IN ('Nitrat','Nitrit') ORDER BY 1'
--'SELECT distinct long_text FROM jupiter.compoundlist ORDER BY 1'

------------------------------------------------------------------------------------------------------------------------
BEGIN;

DROP VIEW IF EXISTS jupiter.mstvw_combined_chemestry CASCADE;

CREATE OR REPLACE VIEW jupiter.mstvw_combined_chemestry AS (
    WITH
      ionbalance AS (
        SELECT DISTINCT
          boreholeno,
          intakeno,
          sampleid,
          ionbalance
        FROM jupiter.mstmvw_ionbalance_all_dates
    ),
      watertype AS (
        SELECT DISTINCT
          boreholeno,
          intakeno,
          sampleid,
          vandtype
        FROM jupiter.mstmvw_watertype4_alldates
    )
    SELECT
      ior.*,
      ion.ionbalance,
      wt.vandtype
    FROM
      jupiter.mstmvw_inorganic_compound_all_dates ior
    LEFT OUTER JOIN ionbalance ion USING (boreholeno, intakeno, sampleid)
    LEFT OUTER JOIN watertype wt USING (boreholeno, intakeno, sampleid)
);

DROP MATERIALIZED VIEW if EXISTS jupiter.mstmvw_combined_chemestry_alldates;

CREATE MATERIALIZED VIEW jupiter.mstmvw_combined_chemestry_alldates AS (
    SELECT * FROM jupiter.mstvw_combined_chemestry
);

DROP MATERIALIZED VIEW if EXISTS jupiter.mstmvw_combined_chemestry_latestdates;

CREATE MATERIALIZED VIEW jupiter.mstmvw_combined_chemestry_latestdates AS (
  SELECT
    DISTINCT ON (boreholeno)
      *
    FROM jupiter.mstvw_combined_chemestry
  ORDER BY boreholeno, sampledate DESC
);

GRANT SELECT ON ALL TABLES IN SCHEMA jupiter TO jupiterrole;

COMMIT;
