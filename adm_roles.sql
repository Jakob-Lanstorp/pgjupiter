/*
 ***************************************************************************
  adm_roles.sql
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c)
  -Create index
   begin                : 2018-04-06
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
  Create dbsync role and change ownership
*/
CREATE ROLE jupiter_dbsync WITH PASSWORD 'synkit' LOGIN;
ALTER DATABASE pcjupiterxl OWNER TO jupiter_dbsync;

GRANT USAGE ON SCHEMA jupiter TO jupiter_dbsync;
GRANT ALL ON SCHEMA jupiter TO jupiter_dbsync;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA jupiter TO jupiter_dbsync;


-- Change ownership of tables in Jupiter schema
DO
$$
DECLARE
    row record;
BEGIN
    FOR row IN SELECT tablename FROM pg_tables WHERE schemaname = 'jupiter'
    LOOP
        IF row.tablename = ANY( ARRAY['layer_styles', 'spatial_ref_sys']) THEN
          raise notice 'Don''t change ownership of: %', row.tablename;
        ELSE
          raise notice 'Changing ownership of: %', row.tablename;

          EXECUTE 'ALTER TABLE jupiter.' || quote_ident(row.tablename) || ' OWNER TO jupiter_dbsync;';
        END IF;
    END LOOP;
END;
$$;


/*
  Jupiter reader role used by all users but postgres
*/
--REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM jupiterrole;
--REVOKE ALL ON ALL TABLES IN SCHEMA public FROM jupiterrole;
--REVOKE USAGE ON SCHEMA public FROM jupiterrole;
--DROP ROLE IF EXISTS jupiterrole;
CREATE ROLE jupiterrole WITH PASSWORD 'mst' NOLOGIN;
GRANT USAGE ON SCHEMA jupiter TO jupiterrole;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO jupiterrole;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA jupiter TO jupiterrole;
--GRANT SELECT ON TABLE public.layer_styles TO jupiterole;      -- if jupiter not in public schema
--GRANT SELECT ON TABLE public.spatial_ref_sys TO jupiterrole;  -- if jupiter not in public schema

--SHOW search_path;
--SELECT CURRENT_USER;
ALTER ROLE jupiterrole SET SEARCH_PATH = "$user, public, jupiter";


--Jakob Lanstorp, jalan
DROP USER IF EXISTS jupiter_jalan;
CREATE USER jupiter_jalan WITH LOGIN PASSWORD 'some_pw';
GRANT jupiterrole TO jupiter_jalan;
--GRANT SELECT ON ALL TABLES IN SCHEMA jupiter TO jupiter_jalan;
--GRANT USAGE ON SCHEMA jupiter TO jupiter_jalan;
