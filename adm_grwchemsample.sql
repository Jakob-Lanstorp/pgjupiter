/* 
 ***************************************************************************
  adm_grwchemsample.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017
                                 
  -Create index
   
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

	-- DROP INDEX grwchemsample_boreholeno_idx;
	CREATE INDEX  grwchemsample_boreholeno_idx
		ON jupiter.grwchemsample
		USING btree
		(boreholeno);
	--[2017-03-30 14:04:50] completed in 2s 711ms
	
COMMIT;	
--Query returned successfully with no result in 2.3 secs.
