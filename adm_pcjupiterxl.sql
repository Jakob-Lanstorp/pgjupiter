/* 
 ***************************************************************************
  adm_pcjupiterxl.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017
                                 
  -Restoring pcjupiterxl from dump
  -PostGIS extension for spatial data
  -Tablefunc extension for pivot tables
  -Function for converting to lower case column names
  -Role and user grants
   
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
--  "C:\PostgreSQL\pg10\bin\pg_restore" --host=localhost --port=5432 --username="postgres" --password -c -d pcjupiterxl "C:\data\jupiter\pcjupiterxlplus20171206_full_xl\pcjupiterxlplus20171206_full_xl.backup"

/*
  Extensions - Install and create the extensions PostGIS and tablefunc (pivot).

	Extensions information:	
	SELECT pg_available_extensions();   	--shows extensions available for installation
	SELECT * from pg_extension;		--show installed extensions
	
	Test postgis: SELECT postgis_version();	--returns version of postgis
	Test tablefunc: SELECT * FROM normal_rand(1000, 5, 3);	--returns 1000 double precision rows
*/
CREATE EXTENSION postgis;

CREATE EXTENSION tablefunc;

/*
  Make lower letters of column names of all jupiter tables in schema public.
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
      WHERE c.table_schema = 'public'
          AND c.column_name <> lower(c.column_name)
      ORDER BY c.table_schema, c.table_name, c.column_name
    LOOP
      EXECUTE 'ALTER TABLE ' || quote_ident(rec.table_schema) || '.'
      || quote_ident(rec.table_name) || ' RENAME "' || rec.column_name || '" TO ' || quote_ident(lower(rec.column_name)) || ';';
   END LOOP;
END
$$;

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
CREATE USER jupiter_jalan WITH LOGIN PASSWORD '¤%&#¤%&%&&#¤%/&(/&(/&(#&#¤&#&¤%//&(/&(/()%(¤&/#¤/&#';
GRANT jupiterrole TO jupiter_jalan;
