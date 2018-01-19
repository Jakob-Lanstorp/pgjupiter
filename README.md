# pgjupiter - copyright Jakob Lanstorp

PostgreSQL PostGIS SQL scripts for quering The Geological Survey of Denmark and Greenland (GEUS) PCJupiterXL database - Denmark's geological and hydrological database.

pgJupiter scripts can be used as standalone scripts or as the base of Qupiter a QGIS processing plugin.

pgJupiter SQL requires:

  -A hosted PostgreSQL version of PCJupiterXL (soon general available from geus.dk) 
  -Qupiter a QGIS processing plugin (soon available from github.com/Jakob-Lanstorp/qjupiter)

Installation

Read and run adm_pcjupiterxl.sql

Run the other adm_* sql files for spatial enabling and / or index creation.

Run redoxwatertype.sql for quering the different redox water types according to official Danish specification 
(Geovejledning 6)

Run ionbalance.sql for ion balance inclusive part calculation.

Run inorganic_crosstab for pivot table of inorganic chemical analysis.

Run combined_chemistry for joining ion balance and redox water type on inorganic_crosstab

Run waterlevet.sql for water levet measurement of groundwater (pejlinger)
