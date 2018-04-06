/* 
 ***************************************************************************
  adm_pcjupiterxl.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) April 2018
                                 
  -Restoring pcjupiterxl from dump
  -PostGIS extension for spatial data
  -Tablefunc extension for pivot tables
  -Function for converting to lower case column names
  -Role creation and user grants
   
   begin                : 2018-04-06
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

/*
  Restore pcjupiterxl from GEUS dump
*/
-- DROP SCHEMA jupiter CASCADE
-- CREATE SCHEMA jupiter;
-- SET search_path TO jupiter;

-- Restore backup:
--  "C:\PostgreSQL\10\bin\pg_restore" --host=C1400020 --port=5432 --username="postgres" --password -c -d pcjupiterxl "D:\jupiter\pcjupiterxlplus20180405_xl\pcjupiterxlplus20180405_xl.backup"

-- Test age of database and number of records in selected tables:
--SELECT sampledate::DATE, insertdate::DATE FROM pcjupiterxlplus.grwchemsample ORDER BY insertdate DESC LIMIT 10; --2018-01-22, 2018-01-29
--SELECT MAX(to_char(exporttime, 'YYYY-MM-DD HH24:MI:SS.MS')) FROM pcjupiterxlplus.exporttime;
--SELECT count(*) from pcjupiterxlplus.grwchemsample;  --331.762, 332.339
--SELECT count(*) from pcjupiterxlplus.grwchemanalysis;  --7.329.085, 7.347.062

/*
  Move tables from public to jupiter schema. Do not move PostGIS system tables from public schema.
*/
DO
$$
DECLARE
    row record;
BEGIN
    FOR row IN SELECT tablename FROM pg_tables WHERE schemaname = 'pcjupiterxlplus'
    LOOP
        IF row.tablename = ANY( ARRAY['layer_styles', 'spatial_ref_sys']) THEN
          raise notice 'Don''t move PostGIS system tabels: %', row.tablename;
        ELSE
          raise notice 'Moving table: %', row.tablename;

          EXECUTE 'DROP TABLE IF EXISTS jupiter.' || quote_ident(row.tablename)|| ' CASCADE;';
          EXECUTE 'ALTER TABLE pcjupiterxlplus.' || quote_ident(row.tablename) || ' SET SCHEMA jupiter;';
        END IF;
    END LOOP;
END;
$$;

/*
  Extensions - Install and create the extensions PostGIS and tablefunc (pivot).

	Extensions information:	
	SELECT pg_available_extensions();   	--shows extensions available for installation
	SELECT * from pg_extension;				--show installed extensions
	
	Test postgis: SELECT postgis_version();				          --returns version of postgis
	Test tablefunc: SELECT * FROM normal_rand(1000, 5, 3);	--returns 1000 double precision rows
*/
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE EXTENSION IF NOT EXISTS tablefunc;

/*
  Make lower letters of column names of all jupiter tables in schema jupiter.
  Change WHERE c.table_schema = 'public' for other schema use
  Rewritten from: http://www.postgresonline.com/journal/archives/141-Lowercasing-table-and-column-names.html	
*/
DO
$$
DECLARE
    rec RECORD;
BEGIN
  FOR rec IN
    SELECT (c.table_schema), c.table_name, c.column_name
      FROM information_schema.columns As c
      WHERE c.table_schema = 'jupiter'
          AND c.column_name <> lower(c.column_name)
      ORDER BY c.table_schema, c.table_name, c.column_name
    LOOP
      EXECUTE 'ALTER TABLE ' || quote_ident(rec.table_schema) || '.'
      || quote_ident(rec.table_name) || ' RENAME "' || rec.column_name || '" TO ' || quote_ident(lower(rec.column_name)) || ';';
   END LOOP;
END
$$;
