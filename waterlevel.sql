/* 
 ***************************************************************************
  waterlevel.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017
                                 
  -Materialized view handling water levels (pejlinger)
  
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

/*
  Pejling - waterlevel
*/
BEGIN;

DROP VIEW IF EXISTS jupiter.mstvw_waterlevel CASCADE;

CREATE OR REPLACE VIEW jupiter.mstvw_waterlevel AS (
  SELECT
    b.boreholeno,
    wl.intakeno,
    wl.pejlingsid,
    wl.watlevgrsu AS vandst_mut, --Det målte vandspejl beregnet som meter under terrænoverfladen
    wl.watlevmsl AS vandstkote,  --Det målte vandspejl beregnet som meter over havniveau (online DVR90 ved download det valgt kotesystem)
    wl.timeofmeas::DATE AS pejledato,
    b.geom
FROM
  jupiter.borehole b
INNER JOIN jupiter.watlevel wl USING (boreholeno)
);

DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_waterlevel;

CREATE MATERIALIZED VIEW jupiter.mstmvw_waterlevel_all_dates AS (
  SELECT
    row_number() OVER () AS row_id,
    *
  FROM jupiter.mstvw_waterlevel
);
--[2017-12-12 18:49:09] completed in 17s 266ms

DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_waterlevel_latest_dates;

CREATE MATERIALIZED VIEW jupiter.mstmvw_waterlevel_latest_dates AS (
  SELECT
    DISTINCT ON (boreholeno)
    row_number() OVER () AS row_id,
    *
  FROM jupiter.mstvw_waterlevel
  ORDER BY boreholeno, pejledato DESC
);
--[2017-12-12 18:51:04] completed in 1m 19s 913ms

GRANT SELECT ON ALL TABLES IN SCHEMA jupiter TO jupiterrole;

COMMIT;

-----------------------------------------------------------------------------------------

/*
TEST
--http://data.geus.dk/JupiterWWW/borerapport.jsp?atlasblad=0&loebenr=0&bogstav=&dgunr=38.770&submit=Vis+boringsdata
SELECT * FROM jupiter.watlevel
  WHERE boreholeno =' 38.  770';

--http://data.geus.dk/JupiterWWW/borerapport.jsp?atlasblad=0&loebenr=0&bogstav=&dgunr=58.553&submit=Vis+boringsdata
SELECT * FROM jupiter.watlevel
  WHERE boreholeno =' 58.  553';
*/
