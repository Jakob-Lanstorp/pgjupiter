/* 
 ***************************************************************************
  adm_borehole.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c)
                                 
  -Spatialize borehole table
  -Create indexes for borehole table
  -Add unique integer column for QGIS use
  
   begin                : 2018-02-02
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

BEGIN;

	/*
	  Add spatial geom type to jupiter.borehole table
	*/
	DO $$
	    BEGIN
		BEGIN
		    ALTER TABLE jupiter.borehole ADD COLUMN geom GEOMETRY(POINT, 25832);
		EXCEPTION
		    WHEN duplicate_column THEN RAISE NOTICE 'column geom already exists in jupiter.borehole.';
		END;
	    END;
	$$;

	UPDATE jupiter.borehole SET geom = ST_SetSRID(st_makepoint(xutm,yutm),25832);
	-- [2017-02-15 11:40:08] 299238 rows affected in 19s 655ms

	/*
	  Add gist and btree index to borehole table
	*/
	-- DROP INDEX jupiter.borehole_geom_idx;
	CREATE INDEX IF NOT EXISTS borehole_geom_idx
		ON jupiter.borehole USING gist
		(geom);
	-- [2017-02-15 12:21:50] completed in 6s 707ms

	-- DROP INDEX jupiter.borehole_boreholeno_idx;
	CREATE INDEX IF NOT EXISTS borehole_boreholeno_idx
		ON jupiter.borehole USING btree
		(boreholeno);
	-- [2017-02-15 12:22:22] completed in 3s 176ms


	/*
	  Add unique integer column for opening of borehole in QGIS
	  Update cannot run a windows function row_number(), so wrap in CTE instead.
	*/
		DO $$
	    BEGIN
		BEGIN
		    ALTER TABLE jupiter.borehole ADD COLUMN row_id INTEGER;
		EXCEPTION
		    WHEN duplicate_column THEN RAISE NOTICE 'column row_id already exists in jupiter.borehole.';
		END;
	    END;
	$$;

	with n AS (
		SELECT
		  boreholeno AS current_id,
		  ROW_NUMBER() OVER () AS row_id
		FROM jupiter.borehole
	)
	UPDATE jupiter.borehole
	SET row_id = n.row_id
	FROM n
	WHERE jupiter.borehole.boreholeno = n.current_id;
	--[2017-02-16 09:13:49] 299238 rows affected in 45s 323ms
	
	/*
	  Demo view showing how to add unique integer column for open in QGIS
	*/
	DROP VIEW IF EXISTS jupiter.vw_borehole_demo;
	CREATE OR REPLACE VIEW jupiter.vw_borehole_demo AS (
		SELECT
		  row_number() OVER (ORDER BY boreholeno) AS id,
		  boreholeno,
		  geom
		FROM jupiter.borehole
	);
	
COMMIT;	
