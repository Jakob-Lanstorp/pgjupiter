/* 
 ***************************************************************************
  adm_drwplant.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017
                                 
  -Spatialize drwplant table
  -Create indexes for drwplant table
  -Add unique integer column for QGIS use
   
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

BEGIN;

	/*
	  Add spatial geom type to jupiter.drwplant table
	*/
	ALTER TABLE jupiter.drwplant ADD COLUMN geom GEOMETRY(POINT, 25832);
	UPDATE jupiter.drwplant SET geom = ST_SetSRID(st_makepoint(xutm32euref89,yutm32euref89),25832);
	--[2017-02-17 12:29:21] 95517 rows affected in 2s 891ms

	/*
	  Add gist and btree index to drwplant table
	*/
	-- DROP INDEX jupiter.drwplant_geom_idx;
	CREATE INDEX drwplant_geom_idx
		ON jupiter.drwplant USING gist
		(geom);
	--[2017-02-17 12:29:58] completed in 1s 305ms

	-- DROP INDEX drwplant_plantid_idx;
	CREATE INDEX drwplant_plantid_idx
		ON jupiter.drwplant
		USING btree
		(plantid);
	--[2017-02-17 12:30:27] completed in 162ms

	/*
	  A spatial table in QGIS from PostGIS must have an unique integer column.
	  Update cannot run on a windows function row_number(), so wrap in CTE instead.
	*/
	ALTER TABLE jupiter.drwplant ADD COLUMN row_id INTEGER;

	with n AS (
		SELECT
		  plantid AS current_id,
		  ROW_NUMBER() OVER () AS row_id
		FROM jupiter.drwplant
	)
	UPDATE jupiter.drwplant
	SET row_id = n.row_id
	FROM n
	WHERE jupiter.drwplant.plantid = n.current_id;
	--[2017-02-17 12:31:37] 95517 rows affected in 5s 187ms

COMMIT;	
--Query returned successfully with no result in 11.4 secs.
