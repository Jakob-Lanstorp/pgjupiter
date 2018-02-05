/* 
 ***************************************************************************
  borehole.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) February 2018
                                 
  -Borehole queries
   
   begin                : 2018-02-05
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
  Canceled wells (Sløjfede boringer)
*/
DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_boring_canceled;

CREATE MATERIALIZED VIEW jupiter.mstmvw_boring_canceled AS (
  SELECT
    row_number() OVER () AS row_id1,
    *
  FROM jupiter.borehole
  WHERE use ILIKE 's'
);

/*
  Vandforsyningsboringer
*/
DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_vandforsyningsboringer;

CREATE MATERIALIZED VIEW jupiter.mstmvw_vandforsyningsboringer AS (
  SELECT
    row_number() OVER () AS row_id1,
    dpct.companytype,
    b.*
    FROM
      jupiter.borehole b
  INNER JOIN jupiter.drwplantintake dpi USING (boreholeno)
  INNER JOIN jupiter.drwplantcompanytype dpct ON  dpct.plantid = dpi.plantid
  WHERE
    dpct.companytype in ('V01', 'V02'));


/*
  GRUMO boringer
*/

DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_grumo_boringer;

CREATE MATERIALIZED VIEW jupiter.mstmvw_grumo_boringer AS (
  WITH grumo AS (
      SELECT DISTINCT
        boreholeno,
        project
      FROM
        jupiter.grwchemsample
      WHERE
        project = 'GRUMO'
  )
  SELECT
    row_number() OVER () AS row_id1,
    g.project,
    b.*
  FROM
    jupiter.borehole b
    INNER JOIN grumo g USING (boreholeno)
);


/*
  GRUMO boringer
*/
/*
DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_grumo_boringer;

CREATE MATERIALIZED VIEW jupiter.mstmvw_grumo_boringer AS (
  SELECT
    row_number() OVER () AS row_id1,
    b.*
  FROM
    jupiter.borehole b
    se code.codetype=852 AND code.code ILIKE 'V%' der er en grumo boring registrering
);
*/

/*
  Priviligies
*/
GRANT SELECT ON ALL TABLES IN SCHEMA jupiter TO jupiterrole;
GRANT USAGE ON SCHEMA jupiter TO jupiterrole;



COMMIT;
