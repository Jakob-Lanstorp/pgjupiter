/*
 ***************************************************************************
  adm_roles.sql

  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c)

  -Create index

   begin                : 2018-02-01
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
  Jupiter reader role used by all users but postgres
*/
--REVOKE ALL ON ALL FUNCTIONS IN SCHEMA jupiter FROM jupiterrole;
--REVOKE ALL ON ALL TABLES IN SCHEMA jupiter FROM jupiterrole;
--REVOKE USAGE ON SCHEMA jupiter FROM jupiterrole;
--DROP ROLE IF EXISTS jupiterrole;

CREATE ROLE jupiterrole WITH PASSWORD 'xxxxx' NOLOGIN;

GRANT SELECT ON TABLE public.layer_styles TO jupiterole;      
GRANT SELECT ON TABLE public.spatial_ref_sys TO jupiterrole;  
GRANT SELECT ON ALL TABLES IN SCHEMA public TO jupiterrole;
GRANT USAGE ON SCHEMA jupiter TO jupiterrole;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA jupiter TO jupiterrole;

--Example on one user adopting a role
DROP USER IF EXISTS jupiter_jalan;
CREATE USER jupiter_jalan WITH LOGIN PASSWORD '123456789';
GRANT jupiterrole TO jupiter_jalan;
