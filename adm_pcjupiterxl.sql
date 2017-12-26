/* 
 ***************************************************************************
  adm_pcjupiterxl.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017
                                 
  -Restoring pcjupiterxl from dump
  -PostGIS extension for spatial data
  -Crosstab extension for pivot tables
  -Convert to lower case column names
  -User grants
   
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
	First install the postgis extension either by EnterpriseDB or BigSQL package
	Then create extension postgis
*/
CREATE EXTENSION postgis;

/*
	First install the crosstab extension either by EnterpriseDB or BigSQL package
	Then create extension crosstab
*/
CREATE EXTENSION crosstab;

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
	User grants for reader
*/
GRANT USAGE ON SCHEMA public TO jupiterreader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO jupiterreader;
GRANT SELECT ON TABLE public.layer_styles TO jupiterreader;  -- todo without qgis processing hangs for ever - report it
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO jupiterreader;
