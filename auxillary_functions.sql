/* 
 ***************************************************************************
  auxillary_functions.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) April 2018
                                 
  -Misc function calls used by Qupiter QGIS Procesing plugins
  -Update schema name if not schema is public
   
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
	  Some numeric values are placed in text colum types
	  The function test is value is numeric
	*/
	CREATE OR REPLACE FUNCTION jupiter.isnumeric(text) RETURNS BOOLEAN AS $$
	DECLARE x NUMERIC;
	BEGIN
		x = $1::NUMERIC;
		RETURN TRUE;
	EXCEPTION WHEN others THEN
		RETURN FALSE;
	END;
	$$
	STRICT
	LANGUAGE plpgsql IMMUTABLE;


	/*
		Get unit of sample and compound
	*/
	DROP FUNCTION IF EXISTS jupiter.db_age_in_days();
	CREATE OR REPLACE FUNCTION jupiter.db_age_in_days()
	  RETURNS INT AS $$
	DECLARE
	  rec RECORD;
		/*
			Example:
			SELECT jupiter.db_age_in_days();
		*/
	BEGIN
		SELECT extract(DAYS FROM now() - grwchemsample.insertdate) AS days_old
    FROM jupiter.grwchemsample
    ORDER BY sampledate DESC
    LIMIT 1
	  INTO rec;

	  RETURN rec.days_old;

	END; $$

	LANGUAGE plpgsql;


	/*
		Get unit of sample and compoundid
	*/
	DROP FUNCTION IF EXISTS jupiter.mst_compoundno_to_unit(INTEGER, INTEGER);

	CREATE OR REPLACE FUNCTION jupiter.mst_compoundno_to_unit(sample_id INTEGER, compound_no INTEGER)
	  RETURNS TEXT
  LANGUAGE plpgsql AS
  $$
	DECLARE
		rec RECORD;
	  /*
	  Call like:
	  SELECT jupiter.mst_compoundno_to_unit(212887, 1511);  -- Arsen
	  SELECT jupiter.mst_compoundno_to_unit(212887, 1176); -- Nitrat
	  */
	BEGIN
    SELECT
      gca.compoundno,
      c.longtext AS unit
    FROM
      jupiter.grwchemanalysis gca
    INNER JOIN jupiter.code c ON c.code::NUMERIC = gca.unit AND c.codetype = 752
    WHERE
      gca.sampleid = sample_id AND gca.compoundno = compound_no
    INTO rec;

    RETURN rec.unit;
	END
	$$;

--select * from jupiter.mst_compoundname_to_no('Kobber');

	/*
		Get unit of sample and compoundname
	*/
	DROP FUNCTION IF EXISTS jupiter.mst_compoundname_to_unit(INTEGER, TEXT);
	CREATE OR REPLACE FUNCTION jupiter.mst_compoundname_to_unit(sample_id INTEGER, compound_name text)
	  RETURNS TABLE (
		sampleid integer,
		compoundname text,
		unit CHARACTER VARYING(500)
	  )
	LANGUAGE plpgsql
	AS $$
	DECLARE
		rec RECORD;
	  /*
	  Call like:
	  SELECT * FROM jupiter.mst_compoundname_to_unit(212887, 'arsen');
	  SELECT unit FROM jupiter.mst_compoundname_to_unit(212887, 'arsen');
	  */
	BEGIN
	  FOR rec IN
	  (
		WITH
		compound AS (
		  SELECT
			compoundno
		  FROM jupiter.compoundlist
		  WHERE
			long_text ILIKE compound_name
		)
		SELECT
		  c.longtext AS unit
		FROM
		  jupiter.grwchemanalysis gca
		INNER JOIN compound USING (compoundno)
		INNER JOIN jupiter.code c ON c.code::NUMERIC = gca.unit AND c.codetype = 752
		WHERE gca.sampleid = sample_id
	  )
	  LOOP
			sampleid := sample_id;
			compoundname = compound_name;
			unit :=  rec.unit;
			RETURN NEXT;
	  END LOOP;
	END
	$$;

	/*
		Counts units for a given compound
	*/
	DROP FUNCTION IF EXISTS jupiter.mst_count_compound_units(TEXT);
	CREATE OR REPLACE FUNCTION jupiter.mst_count_compound_units(compound_name text)
	  RETURNS TABLE(
		stof CHARACTER VARYING(500),
		unit CHARACTER VARYING(500),
		antal BIGINT) AS $$
	DECLARE
		rec RECORD;
	  /*
		Example:
		SELECT * from jupiter.mst_count_compound_units('bly');
		SELECT * from  jupiter.mst_count_compound_units('arsen');
	  */
	BEGIN
	  FOR rec IN (
		WITH
		compound AS (
		  SELECT
			compoundno
		  FROM jupiter.compoundlist
		  WHERE
			long_text ILIKE compound_name
		)
		SELECT
		  c.longtext, count(*) AS count_units
		FROM
		  jupiter.grwchemanalysis gca
		INNER JOIN compound USING (compoundno)
		INNER JOIN jupiter.code c ON c.code::NUMERIC = gca.unit AND c.codetype = 752
		GROUP BY c.longtext
	  )
	  LOOP
		stof := INITCAP(compound_name);
		unit := rec.longtext;
		antal := rec.count_units;
		RETURN NEXT;
	  END LOOP;
	END; $$

	LANGUAGE plpgsql;

	/*
		Get compoundno from compoundname
	*/
	DROP FUNCTION IF EXISTS jupiter.mst_compoundname_to_no(TEXT);
	CREATE OR REPLACE FUNCTION jupiter.mst_compoundname_to_no(compound_name text)
	  RETURNS INT AS $$
	DECLARE
	  rec RECORD;
		/*
			Example:
			SELECT jupiter.mst_compoundname_to_no('bly');
			SELECT jupiter.mst_compoundname_to_no('arsen');
		*/
	BEGIN
		SELECT
		  compoundno
		FROM
		  jupiter.compoundlist
		WHERE
		  long_text ILIKE compound_name
	  INTO rec;

	  RETURN rec.compoundno;

	END; $$

	LANGUAGE plpgsql;

	/*
		Get compoundname from compoundno
	*/
	DROP FUNCTION IF EXISTS jupiter.mst_compoundno_to_name(INT);
	CREATE OR REPLACE FUNCTION jupiter.mst_compoundno_to_name(compound_no INT)
	  RETURNS TEXT AS $$
	DECLARE
	  rec RECORD;
		/*
			Example:
			SELECT jupiter.mst_compoundno_to_name(1531);
		*/
	BEGIN
		SELECT
		  long_text AS compountname
		FROM
		  jupiter.compoundlist
		WHERE
		  compoundlist.compoundno = compound_no
	  INTO rec;

	  RETURN rec.compountname;

	END; $$

	LANGUAGE plpgsql;

COMMIT;
--Query returned successfully with no result in 31 msec.
