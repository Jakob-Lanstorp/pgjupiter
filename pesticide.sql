/* 
 ***************************************************************************
  pesticide.sql
  
  Danish Environmental Protection Agency (EPA)
  Jakob Lanstorp, (c) December 2017
                                 
  -Pesticide general list and query

  -DO NOT USE FOR OFFICIAL GOVERNMENT QUERY WITH OUT READING TODOS AND SQL CODE
  
   begin                : 2017-12-14
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
    Pesticider fra seneste drikkevandsbekendtgørelse
      + Pesticider fra overvågningsprogrammet
      + Region Midtjylland Chloridazon og Desphenyl-chloridazon
      + Drikkevandsbekendgørelse Aldrin, dieldrin, heptachlor, heptachlorepoxid
  */
  DROP TABLE jupiter.mst_bekendtgoerelse_pesticide_list;
  CREATE TABLE jupiter.mst_bekendtgoerelse_pesticide_list (
    rowid SERIAL NOT NULL,
    compoundno INTEGER NOT NULL,
    name VARCHAR(60),
    insertdate TIMESTAMP DEFAULT now(),
    CONSTRAINT pk_rowid PRIMARY KEY (rowid)
  );

  INSERT INTO jupiter.mst_bekendtgoerelse_pesticide_list(compoundno)
  VALUES (9943), (2688), (3125), (2712), (4014), (2690), (410), (3011), (4536), (4515),
    (9944), (3754), (3755), (3683), (3505), (421), (422), (3684), (3506), (2627), (4510), (3756), (3685), (2628),
    (3573), (3592), (3597), (3507), (452), (4511), (4512), (3611), (3617), (4719), (4718), (4516);

  UPDATE jupiter.mst_bekendtgoerelse_pesticide_list
    SET name = (SELECT DISTINCT long_text FROM jupiter.compoundlist WHERE compoundno = mst_bekendtgoerelse_pesticide_list.compoundno);

  SELECT * FROM jupiter.mst_bekendtgoerelse_pesticide_list;

  /*
    Baseview for andre udtræk. Indhold
    + Pesticider fra overvågningsprogrammet
    + Region Midtjylland Chloridazon og Desphenyl-chloridazon
    + Drikkevandsbekendgørelse Aldrin, dieldrin, heptachlor, heptachlorepoxid
    Note der er ingen grænseværdier i udtræk - ikke påvist kommer også med ud
  */
  DROP VIEW IF EXISTS jupiter.mstvw_pesticide_raw CASCADE;
  CREATE OR REPLACE VIEW jupiter.mstvw_pesticide_raw AS (
    -- liste af pesticider
    WITH compounds AS (
        SELECT
          cl.compoundno,
          cl.long_text
        FROM jupiter.compoundlist cl
        WHERE cl.compoundno IN (9943, 2688, 3125, 2712, 4014, 2690, 410, 3011, 4536, 4515,
                                9944, 3754, 3755, 3683, 3505, 421, 422, 3684, 3506, 2627, 4510, 3756, 3685, 2628,
                                3573, 3592, 3597, 3507, 452, 4511, 4512, 3611, 3617, 4719, 4718, 4516,
                                4696, 3528, 3503, 3134, 3136, 3137)
    ),
     -- offentlige fælles vandforsyningsanlæg (V01) og Private fælles vandforsyningsanlæg (V02)
     -- boreholeno påført via drwplantintake
    drwplantv01v02 AS (
        SELECT dp.plantid, dp.plantname, dpct.companytype, dpi.boreholeno, dpi.intakeno
        FROM jupiter.drwplant dp
        INNER JOIN jupiter.drwplantintake dpi USING (plantid)
        INNER JOIN jupiter.drwplantcompanytype dpct USING (plantid)
        WHERE dpct.companytype in ('V01', 'V02', 'V03') --hvis udkommenteret stiger den fra 113 til 201 poster
    )
    -- påfør det kemiske analyseresultat
    SELECT
      row_number() OVER (ORDER BY ca.analysisid) AS id,
      dp.plantid,
      dp.plantname,
      dp.companytype,
      cs.boreholeno,
      dp.intakeno,
      ca.compoundno,
      com.long_text pesticid,
      ca.amount,
      ca.attribute,
      cs.sampledate,
      ca.sampleid,
      b.abandondat,
      b.geom
    FROM jupiter.grwchemanalysis ca
      INNER JOIN compounds com USING (compoundno)
      INNER JOIN jupiter.grwchemsample cs USING (sampleid)
      INNER JOIN jupiter.borehole b USING (boreholeno)
      INNER JOIN drwplantv01v02 dp ON dp.boreholeno = b.boreholeno
    WHERE EXTRACT(YEAR FROM cs.sampledate) > 1990);
  --cs.sampledate IS NOT NULL AND


  /*
    Test Glyphosat
  */
  --SELECT *
  --FROM "jupiter"."mstvw_pesticide_raw"
  --WHERE (geom && ST_MakeEnvelope(642035.748576, 6071706.83585, 652761.359312, 6079112.6147, 25832) AND pesticid = 'Glyphosat' AND amount > 0.0);

  /*
    Test all found pesticide
  */
  /*
  --SELECT count(*)
  SELECT *
  FROM jupiter.vw_pesticide_raw
  WHERE attribute IN ('>', 'B', 'C') OR attribute ISNULL
  ORDER BY sampledate;
  --501
  */

  /*
    Pesticider over grænseværdi
    TODO: MISSING accumulated pesticide values
    TODO: DO NOT USE FOR RETRIEVING TRUE LAW FULL EXCEEDANCE
  */
  DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_pesticide_exceedance CASCADE;
  REFRESH MATERIALIZED VIEW jupiter.mstmvw_pesticide_exceedance;

  CREATE MATERIALIZED VIEW jupiter.mstmvw_pesticide_exceedance AS (
    WITH aldrin AS (
        SELECT *
        FROM jupiter.mstvw_pesticide_raw
        WHERE
          (attribute IN ('>', 'B', 'C') OR attribute ISNULL) AND
          pesticid ILIKE 'aldrin' AND amount >= 0.03
    ),
        dieldrin AS (
          SELECT *
          FROM jupiter.mstvw_pesticide_raw
          WHERE
            (attribute IN ('>', 'B', 'C') OR attribute ISNULL) AND
            pesticid ILIKE 'dieldrin' AND amount >= 0.03
      ),
        heptachlor AS (
          SELECT *
          FROM jupiter.mstvw_pesticide_raw
          WHERE
            (attribute IN ('>', 'B', 'C') OR attribute ISNULL) AND
            pesticid ILIKE 'heptachlor' AND amount >= 0.03
      ),
        heptachlorepoxid AS (
          SELECT *
          FROM jupiter.mstvw_pesticide_raw
          WHERE
            (attribute IN ('>', 'B', 'C') OR attribute ISNULL) AND
            pesticid ILIKE 'heptachlorepoxid' AND amount >= 0.03
      ),
        restpesticide AS (
          SELECT *
          FROM jupiter.mstvw_pesticide_raw
          WHERE
            (attribute IN ('>', 'B', 'C') OR attribute ISNULL) AND
            pesticid NOT IN ('aldrin', 'dieldrin', 'heptachlor', 'heptachlorepoxid') AND amount >= 0.1
      ),
        pesticide AS (
        SELECT *
        FROM aldrin
        UNION ALL
        SELECT *
        FROM dieldrin
        UNION ALL
        SELECT *
        FROM heptachlor
        UNION ALL
        SELECT *
        FROM heptachlorepoxid
        UNION ALL
        SELECT *
        FROM restpesticide
      )
    SELECT
      row_number() OVER (ORDER BY p.id) AS id1,
      p.*,
      f.list_io_id
    FROM pesticide p
    LEFT JOIN gvkort.fi f ON st_within(p.geom, f.geom) AND f.list_io_id = 2 -- sfi
  );
  --6034
  --SELECT * FROM jupiter.mvw_pesticide_exceedance;

  /*
    Sløjfede boringer
  */
  DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_sloejfede_vandforsyningsboringer;
  CREATE MATERIALIZED VIEW jupiter.mstmvw_sloejfede_vandforsyningsboringer AS (
    SELECT
      row_number() OVER (ORDER BY b.abandondat) AS id,
      b.boreholeno,
      dpct.companytype,
      b.use,
      b.abandondat,
      b.geom
    FROM jupiter.borehole b
      INNER JOIN jupiter.drwplantintake dpi USING (boreholeno)
      INNER JOIN jupiter.drwplantcompanytype dpct ON dpct.plantid = dpi.plantid
    WHERE
      dpct.companytype IN ('V01', 'V02', 'V03') AND
      b.use = 'S' AND
      EXTRACT(YEAR FROM b.abandondat) > 1990
    ORDER BY b.abandondat ASC
  --8960 alle abandondat
  --4081 abandondat > 1990 og V01, V02
  --4226 abandondat > 1990 og V01, V02, V03
  );


  /*
    Sløjfede boring i sammenfald med pesticid grænseværdi overskridelser
  */
  DROP MATERIALIZED VIEW IF EXISTS jupiter.mstmvw_pesticide_sloejfede_boringer;
  CREATE MATERIALIZED VIEW jupiter.mstmvw_pesticide_sloejfede_boringer AS (
    SELECT
      row_number() OVER (ORDER BY s.abandondat) AS id2,
      p.*,
      s.use
      --s.abandondat
    FROM jupiter.mstmvw_pesticide_exceedance p
      INNER JOIN jupiter.mstmvw_sloejfede_vandforsyningsboringer s ON st_equals(p.geom, s.geom)
    ORDER BY s.abandondat
    --1898
  );

  /*
    Tæl sløjfede boring pr år, som har sammentræf med pesticid overskridelser
  */
  Drop VIEW IF EXISTS jupiter.mstvw_sløjfede_boringer_pr_aar;
  CREATE VIEW jupiter.mstvw_sløjfede_boringer_pr_aar AS (
    WITH count_sfoejfede AS (
      SELECT
        extract(YEAR FROM abandondat)AS year,
        count(*) As count_sloejfede_boringer
      FROM jupiter.mstmvw_pesticide_sloejfede_boringer
      GROUP BY year
      ORDER BY year
  )
    SELECT
      row_number() OVER (ORDER BY year) AS id,
      year,
      count_sloejfede_boringer
    FROM count_sfoejfede
  );

  /*
    Tæl pesticid overskridelser pr. år
  */
  DROP VIEW IF EXISTS jupiter.mstvw_pesticid_exceedance_pr_year;
  CREATE VIEW jupiter.mstvw_pesticid_exceedance_pr_year AS (
    SELECT
      --row_number() OVER (ORDER BY abandondat) AS id,
      extract(YEAR FROM abandondat)::INTEGER AS year,
      count(*) AS pesticide_exceedance_count
    FROM jupiter.mstmvw_pesticide_exceedance
      WHERE abandondat is NOT NULL
    GROUP BY year
    ORDER BY year
  );

COMMIT;
