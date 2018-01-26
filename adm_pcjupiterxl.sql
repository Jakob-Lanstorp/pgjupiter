/* 
 ***************************************************************************
  adm_pcjupiterxl.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017
                                 
  -Restoring pcjupiterxl from dump
  -PostGIS extension for spatial data
  -Tablefunc extension for pivot tables
  -Function for converting to lower case column names
  -Role creation and user grants
   
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

/*
  Restore pcjupiterxl from GEUS dump
*/
-- Try to resore data to a schema named jupiter:
-- CREATE SCHEMA jupiter;
-- SET search_path TO myschema;


-- Restore backup:
--  "C:\PostgreSQL\10\bin\pg_restore" --host=localhost --port=5432 --username="postgres" --password -c -d pcjupiterxl "D:\jupiter\pcjupiterxlplus_full_xl_2018jan24\pcjupiterxlplus_full_xl.backup"
-- Test age of database: SELECT "SAMPLEDATE", "INSERTDATE" from public.grwchemsample ORDER BY "INSERTDATE" DESC;
-- Backup restore version from 2018-01-22 had "WARNING: error ignored on restore: 520"


/*
  If database wrongly ended up in public schema.
  Do not move PostGIS system tables from public schema.
*/
DO
$$
DECLARE
    row record;
BEGIN
    FOR row IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' -- and other conditions, if needed
    LOOP
        IF row.tablename = ANY( ARRAY['layer_styles', 'spatial_ref_sys']) THEN
          raise notice 'Don''t move PostGIS system tabels: %', row.tablename;
        ELSE
          raise notice 'Moving table: %', row.tablename;
          EXECUTE 'ALTER TABLE public.' || quote_ident(row.tablename) || ' SET SCHEMA jupiter;';
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
CREATE EXTENSION postgis;

CREATE EXTENSION tablefunc;

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

/*
	User grants for reader
	DELETE Role used instead ...
*/
--REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM jupiterreader;
--REVOKE ALL ON ALL TABLES IN SCHEMA public FROM jupiterreader;
--REVOKE USAGE ON SCHEMA public FROM jupiterreader;
--DROP USER IF EXISTS jupiterreader;
--CREATE USER jupiterreader WITH PASSWORD 'mst';                --login default for user not for role creation
--GRANT USAGE ON SCHEMA public TO jupiterreader;
--GRANT SELECT ON ALL TABLES IN SCHEMA public TO jupiterreader;
--GRANT SELECT ON TABLE public.layer_styles TO jupiterreader;  -- TODO without qgis processing hangs for ever - report it
--GRANT SELECT ON TABLE public.spatial_ref_sys TO jupiterreader;
--GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO jupiterreader;


/*
  Jupiter reader role used by all users but postgres
*/
--REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM jupiterrole;
--REVOKE ALL ON ALL TABLES IN SCHEMA public FROM jupiterrole;
--REVOKE USAGE ON SCHEMA public FROM jupiterrole;
--DROP ROLE IF EXISTS jupiterrole;
CREATE ROLE jupiterrole WITH PASSWORD 'mst' NOLOGIN;
GRANT USAGE ON SCHEMA public TO jupiterrole;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO jupiterrole;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO jupiterrole;
--GRANT SELECT ON TABLE public.layer_styles TO jupiterole;      -- if jupiter not in public schema
--GRANT SELECT ON TABLE public.spatial_ref_sys TO jupiterrole;  -- if jupiter not in public schema

--Jakob Lanstorp, jalan
DROP USER IF EXISTS jupiter_jalan;
CREATE USER jupiter_jalan WITH LOGIN PASSWORD 'setyourpasswordhere';
GRANT jupiterrole TO jupiter_jalan;
