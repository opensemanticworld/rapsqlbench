#!/bin/bash

# /* 
#    Copyright 2023 Andreas Raeder, https://github.com/raederan
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
# */

# Input parameter
graphname=$1
model=$2
memory=$3
cores=$4

# Function to get the current timestamp
get_ts() {
  # TS nanosecond precision 6 and UTC two digits similar to ISO 8601 and PostgreSQL
  ts=$(date +"%Y-%m-%d %H:%M:%S.%6N%:::z")
  echo "$ts"
}

# Function to ensure paths 
ensure_path() {
  local path=$1
  if [ ! -f "$path" ]; then
    echo "File not found: $path"
    exit 1
  fi
}

# Directory paths
cwd=$(pwd)
rdf2rapsql_dir=$cwd/rdf2rapsql
data_dir=$cwd/data/"$graphname"
measurement_dir=$cwd/measurement/"$graphname"

# File paths
exectime_sh="$cwd/exectime.sh"
rdf2pg_jar=$cwd/rdf2pg/$model/rdf2pg.jar
writesql_sh="$rdf2rapsql_dir/writesql.sh"
edgepart_sh="$rdf2rapsql_dir/edgepart.sh"
sqlimport_sh="$rdf2rapsql_dir/sqlimport.sh"
spx_n3="$data_dir"/"$graphname".n3
nres_csv="$data_dir"/nres.csv
nlit_csv="$data_dir"/nlit.csv
nbn_csv="$data_dir"/nbn.csv
edtp_csv="$data_dir"/edtp.csv
eop_csv="$data_dir"/eop.csv
rapsql_txt="$measurement_dir"/rapsql.txt
edtp_part_txt="$data_dir"/edtp_part.txt
eop_part_txt="$data_dir"/eop_part.txt

# Change directory to data source directory
cd "$data_dir" || exit 0

# Display input instance
echo "RDF2RAPSQL, INSTANCE, $spx_n3"
echo "RDF2RAPSQL, PID, $$"


### i Run RDF2PG START ###
# Input: x.n3, x.ttl, x.nt
# Output: nres.csv, nlit.csv, nbn.csv, edtp.csv, eop.csv, edtp_part.txt, eop_part.txt
rdf2pg_start=$(get_ts)
echo "RDF2PG, START, $rdf2pg_start"
java -Xmx"$memory"m -XX:ActiveProcessorCount="$cores" -jar "$rdf2pg_jar" -gdm "$spx_n3" > "$measurement_dir"/rdf2pg.txt || exit 1 
rdf2pg_end=$(get_ts)
echo "RDF2PG, END, $rdf2pg_end"
$exectime_sh "RDF2PG" "$rdf2pg_start" "$rdf2pg_end" 

# Ensure rdf2pg created csv paths
ensure_path "$nres_csv"
ensure_path "$nlit_csv"
ensure_path "$nbn_csv"
ensure_path "$edtp_csv"
ensure_path "$eop_csv"
ensure_path "$edtp_part_txt"
ensure_path "$eop_part_txt"
### i Run RDF2PG END ###


### ii WRITESQL START ###
# Create init sql file
$writesql_sh "$graphname" "$nres_csv" "$nlit_csv" "$nbn_csv" || exit 1
import_dir="$data_dir"/"import"
init_sql="$import_dir"/init.sql
ensure_path "$init_sql"
# Init rapsql graph using init.sql
sudo -u postgres psql -q -U postgres -d postgres -f "$init_sql" > "$rapsql_txt" || exit 1

# Created node sql files
nodes_dir="$import_dir"/nodes
nres_sql="$nodes_dir"/nres.sql
nlit_sql="$nodes_dir"/nlit.sql
nbn_sql="$nodes_dir"/nbn.sql
ensure_path "$nres_sql"
ensure_path "$nlit_sql"
ensure_path "$nbn_sql"
### ii WRITESQL START ###


### iii EDGEPART START ###
# Create edge partitions and sql files
# Input: {edtp, eop}.csv
# Output: {edtp, eop}/*.csv, {edtp, eop}/import/*.sql
edgepart_start=$(get_ts)
echo "EDGEPARTITIONING, START, $edgepart_start"
"$edgepart_sh" "$graphname" "$model" "$edtp_csv" "$edtp_part_txt" || exit 1
"$edgepart_sh" "$graphname" "$model" "$eop_csv" "$eop_part_txt" || exit 1
edgepart_end=$(get_ts)
echo "EDGEPARTITIONING, END, $edgepart_end"
$exectime_sh "EDGEPARTITIONING" "$edgepart_start" "$edgepart_end"

# Created edge sql files
edges_dir="$import_dir"/edges
edtp_sql="$edges_dir"/edtp.sql
eop_sql="$edges_dir"/eop.sql
ensure_path "$edtp_sql"
ensure_path "$eop_sql"
### iii EDGEPART START ###


### iv SQLIMPORT START ###
# Import nodes in parallel
# Input: import/nodes/{nres,nlit,nbn}.sql 
dbimport_nodes_start=$(get_ts)
echo "DBIMPORT-NODES, START, $dbimport_nodes_start"
$sqlimport_sh "$nodes_dir" "$rapsql_txt" || exit 1
dbimport_nodes_end=$(get_ts)
echo "DBIMPORT-NODES, END, $dbimport_nodes_end"
$exectime_sh "DBIMPORT-NODES" "$dbimport_nodes_start" "$dbimport_nodes_end"

# !        Important note             !
# ! First import nodes and then edges !

# Import edges in parallel
# Input: import/edges/{edtp,eop}/.sql
dbimport_edges_start=$(get_ts)
echo "DBIMPORT-EDGES, START, $dbimport_edges_start"
$sqlimport_sh "$edges_dir" "$rapsql_txt" || exit 1
dbimport_edges_end=$(get_ts)
echo "DBIMPORT-EDGES, END, $dbimport_edges_end"
$exectime_sh "DBIMPORT-EDGES" "$dbimport_edges_start" "$dbimport_edges_end"
### iv SQLIMPORT END ###

