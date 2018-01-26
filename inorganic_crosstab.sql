/* 
 ***************************************************************************
  inorganic_crosstab.sql 
  Run from current schema public
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017
                                 
  -Pivot of inorganic compounds versus sample
  
   begin                : 2018-01-14
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

--Test kald nedenstående fra qgis processing
--COPY (SELECT * FROM jupiter.inorganic_compound_crosstab LIMIT 10) TO 'd:\test_inorganic_compounds.csv' DELIMITERS ';' CSV HEADER;

--'SELECT long_text FROM (VALUES (''Calcium''), (''Chlorid''), (''Nitrat''),(''Nitrit'')) s(long_text)'
--'SELECT long_text FROM jupiter.compoundlist WHERE long_text IN ('Nitrat','Nitrit') ORDER BY 1'
--'SELECT distinct long_text FROM jupiter.compoundlist ORDER BY 1'

------------------------------------------------------------------------------------------------------------------------

BEGIN;
/*
  qjupiter production view
*/
DROP VIEW IF EXISTS jupiter.mstvw_inorganic_compound CASCADE;

CREATE OR REPLACE VIEW jupiter.mstvw_inorganic_compound AS (
  with
    borehole_sample as (
      SELECT
        b.boreholeno,
        b.geom,
        i.intakeno,
        cs.sampleid,
        cs.sampledate
      FROM jupiter.borehole b
      INNER JOIN jupiter.grwchemsample cs USING (boreholeno)
      INNER JOIN jupiter.intake i USING (boreholeno)
      INNER JOIN jupiter.code c ON b.use = c.code
      --INNER JOIN kort.lolland v ON st_dwithin(b.geom, v.geom, 100)
      WHERE c.codetype = 17
    ),
    inorganic_crosstab AS (
      SELECT *
      FROM crosstab
           (
            'SELECT
                ca.sampleid,                        --row_name (y.axe)
                --ca.analysisno,                    --extra column - must be between row_name and category
                cl.long_text,                       --category (x-axe)
                concat(ca.attribute, ca.amount)     --value to print
            FROM jupiter.grwchemsample cs
            INNER JOIN jupiter.grwchemanalysis ca ON ca.sampleid = cs.sampleid
            INNER JOIN jupiter.compoundlist cl ON ca.compoundno = cl.compoundno
            ORDER BY 1,2',
            'SELECT long_text FROM (VALUES ' ||
              '(''Alkalinitet,total TA''), ' ||
              '(''Aluminium''), ' ||
              '(''Ammoniak+ammonium''), ' ||
              '(''Ammonium-N''), ' ||
              '(''Anioner, total''), ' ||
              '(''Arsen''), ' ||
              '(''Barium''), ' ||
              '(''Bly''), ' ||
              '(''Bor''), ' ||
              '(''Bromid''), ' ||
              '(''Calcium''), ' ||
              '(''Carbon,org,NVOC''), ' ||
              '(''Carbonat''), ' ||
              '(''Carbondioxid, aggr.''), ' ||
              '(''Chlorid''), ' ||
              '(''Dihydrogensulfid''), ' ||
              '(''Flourid''), ' ||
              '(''Hydrogencarbonat''), ' ||
              '(''Inddampningsrest''), ' ||
              '(''Jern''), ' ||
              '(''Kalium''), ' ||
              '(''Kationer, total''), ' ||
              '(''Kobber''), ' ||
              '(''Kobolt (Co)''), ' ||
              '(''Konduktivitet''), ' ||
              '(''Magnesium''), ' ||
              '(''Mangan''), ' ||
              '(''Methan''), ' ||
              '(''Natrium''), ' ||
              '(''Natriumhydrogencarbonat''), ' ||
              '(''Nikkel''), ' ||
              '(''Nitrat''), ' ||
              '(''Nitrit''), ' ||
              '(''Orthophosphat''), ' ||
              '(''Orthophosphat-P''), ' ||
              '(''Oxygen indhold''), ' ||
              '(''Permanganattal KMnO4''), ' ||
              '(''pH''), ' ||
              '(''Phosphor, total-P''), ' ||
              '(''Redoxpotentiale''), ' ||
              '(''Siliciumdioxid''), ' ||
              '(''Strontium''), ' ||
              '(''Sulfat''), ' ||
              '(''Sulfit-S''), ' ||
              '(''Temperatur''), ' ||
              '(''Tørstof,total''), ' ||
              '(''Zink'')) ' ||
              's(long_text)'
           )
        AS ct(sampleid INTEGER,
              Alkalinitet_total_TA TEXT,
              Aluminium TEXT,
              Ammoniak_ammonium TEXT,
              Ammonium_N TEXT,
              Anioner_total TEXT,
              Arsen TEXT,
              Barium TEXT,
              Bly TEXT,
              Bor TEXT,
              Bromid TEXT,
              Calcium TEXT,
              Carbon_org_NVOC TEXT,
              Carbonat TEXT,
              Carbondioxid_aggr TEXT,
              Chlorid TEXT,
              Dihydrogensulfid TEXT,
              Flourid TEXT,
              Hydrogencarbonat TEXT,
              Inddampningsrest TEXT,
              Jern TEXT,
              Kalium TEXT,
              Kationer_total TEXT,
              Kobber TEXT,
              Kobolt_Co TEXT,
              Konduktivitet TEXT,
              Magnesium TEXT,
              Mangan TEXT,
              Methan TEXT,
              Natrium TEXT,
              Natriumhydrogencarbonat TEXT,
              Nikkel TEXT,
              Nitrat TEXT,
              Nitrit TEXT,
              Orthophosphat TEXT,
              Orthophosphat_P TEXT,
              Oxygen_indhold TEXT,
              Permanganattal_KMnO4 TEXT,
              pH TEXT,
              Phosphor_total_P TEXT,
              Redoxpotentiale TEXT,
              Siliciumdioxid TEXT,
              Strontium TEXT,
              Sulfat TEXT,
              Sulfit_S TEXT,
              Temperatur TEXT,
              Tørstof_total TEXT,
              Zink TEXT
           )
    )
  SELECT
    row_number() OVER () AS row_id,
    b.boreholeno,
    b.intakeno,
    b.sampledate,
    b.geom,
    ic.*
  FROM borehole_sample b
  INNER JOIN inorganic_crosstab ic USING (sampleid)
);

/*
  qjupiter production materialized view - all dates
*/
DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_inorganic_compound_all_dates;

CREATE MATERIALIZED VIEW jupiter.mstmvw_inorganic_compound_all_dates AS (
    SELECT * FROM jupiter.mstvw_inorganic_compound
);
--[2017-12-11 15:14:15] completed in 36s 749ms

--REFRESH MATERIALIZED VIEW jupiter.mstmvw_inorganic_compound_all_dates;

/*
  qjupiter production materialized view - all dates
*/
DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_inorganic_compound_latest_dates;

CREATE MATERIALIZED VIEW jupiter.mstmvw_inorganic_compound_latest_dates AS (
    SELECT
      DISTINCT ON (boreholeno)
      *
    FROM
      jupiter.mstvw_inorganic_compound
    ORDER BY boreholeno, sampledate DESC
);
--[2017-12-11 15:16:31] completed in 38s 770ms

GRANT SELECT ON TABLE jupiter.mstmvw_inorganic_compound_latest_dates TO jupiter_jalan;

--REFRESH MATERIALIZED VIEW jupiter.mstmvw_inorganic_compound_latest_dates;

GRANT SELECT ON ALL TABLES IN SCHEMA jupiter TO jupiterrole;

COMMIT;
