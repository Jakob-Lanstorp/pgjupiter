/*
 ***************************************************************************
  adm_pltchemanalysis.sql

  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017

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

BEGIN;

	-- DROP INDEX pltchemanalysis_sampleid_idx;
	CREATE INDEX IF NOT EXISTS pltchemanalysis_sampleid_idx
		ON jupiter.pltchemanalysis
		USING btree
		(sampleid);

COMMIT;
