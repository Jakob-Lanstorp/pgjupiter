# pgjupiter - copyright Jakob Lanstorp - EPA

PostgreSQL PostGIS SQL scripts for quering The Geological Survey of Denmark and Greenland (GEUS) PCJupiterXL database - Denmark's geological and hydrological database. Scripts made by the Danish Environmental Protection Agency (EPA).

pgJupiter scripts can be used as standalone scripts or as the base of Qupiter a QGIS processing plugin.

pgJupiter SQL requires a hosted PostgreSQL version of PCJupiterXL (soon general available from geus.dk) and
Qupiter - a QGIS processing plugin (soon available from github.com/Jakob-Lanstorp/qjupiter)

READ BEFORE INSTALLATION 

-adm_pcjupiterxl.sql: Restoring backup, move tables gtmo public to jupiter schema, lower case columns names. 

-other adm_ sql files: Creation of geometry column, spatial and non spatial index.

-redoxwatertype.sql: Creation of materialized views for redox water types according to official Danish specification 
(Geovejledning 6)

-ionbalance.sql: Creation of materialized views for ion balance inclusive temporary part calculation

-inorganic_crosstab.sql: Creation of materialized views for for pivot table of inorganic chemical analysis

-combined_chemistry: Creation of materialized views joining ion balance and redox water type on inorganic_crosstab

-waterlevet.sql: Creation of materialized views for water levet measurement of groundwater (pejlinger)

PSQL

pg_restore --host=myhost --port=5432 --username=myuser --password -c -d mydatabase pcjupiterxlplus_full_xl.backup

psql -h myhost -p 5432 -U myuser -d myschema -f adm_pcjupiterxl.sql

psql -h myhost -p 5432 -U myuser -d myschema -f adm_borehole.sql

psql -h myhost -p 5432 -U myuser -d myschema -f adm_drwplant.sql

psql -h myhost -p 5432 -U myuser -d myschema -f adm_grwchemanalysis.sql

psql -h myhost -p 5432 -U myuser -d myschema -f adm_grwchemsample.sql

psql -h myhost -p 5432 -U myuser -d myschema -f adm_pltchemanalysis.sql

psql -h myhost -p 5432 -U myuser -d myschema -f adm_roles.sql

psql -h myhost -p 5432 -U myuser -d myschema -f auxillary_functions.sql

psql -h myhost -p 5432 -U myuser -d myschema -f borehole.sql

psql -h myhost -p 5432 -U myuser -d myschema -f inorganic-crosstab.sql

psql -h myhost -p 5432 -U myuser -d myschema -f ionbalance.sql

psql -h myhost -p 5432 -U myuser -d myschema -f redoxwatertype.sql

psql -h myhost -p 5432 -U myuser -d myschema -f waterlevel.sql

psql -h myhost -p 5432 -U myuser -d myschema -f combined_chemistry.sql

psql -h myhost -p 5432 -U myuser -d myschema -f adm_pcjupiterxl.sql
