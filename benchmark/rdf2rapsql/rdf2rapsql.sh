#!/bin/bash

# Input parameter
graphname=$1
memory=$2
cores=$3

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
rdf2pg_jar=$cwd/rdf2pg/rdf2pg.jar
writesql_sh="$rdf2rapsql_dir/writesql.sh"
edgepart_sh="$rdf2rapsql_dir/edgepart.sh"
sqlimport_sh="$rdf2rapsql_dir/sqlimport.sh"
spx_n3="$data_dir"/"$graphname".n3
nres_csv="$data_dir"/nres.csv
nlit_csv="$data_dir"/nlit.csv
nbn_csv="$data_dir"/nbn.csv
edtp_csv="$data_dir"/edtp.csv
eop_csv="$data_dir"/eop.csv
edtp_part_txt="$data_dir"/edtp_part.txt
eop_part_txt="$data_dir"/eop_part.txt
import_sql="$data_dir"/import.sql

# Change directory to data source directory
cd "$data_dir" || exit 0

# Display input instance
echo "RDF2RAPSQL, INSTANCE, $spx_n3"
echo "RDF2RAPSQL, PID, $$"


# Run rdf2pg
# Input: x.n3
# Output: nres.csv, nlit.csv, nbn.csv, edtp.csv, eop.csv
rdf2pg_start=$(get_ts)
echo "RDF2PG, START, $rdf2pg_start"
java -Xmx"$memory"m -XX:ActiveProcessorCount="$cores" -jar "$rdf2pg_jar" -gdm "$spx_n3" > "$measurement_dir"/rdf2pg.txt || exit 1 
# java -Xmx24576m -XX:ActiveProcessorCount="$cores" -jar "$rdf2pg_jar" -gdm "$spx_n3" > "$measurement_dir"/rdf2pg.txt || exit 1 # changed to spx_n3
# java -Xmx24576m -XX:ActiveProcessorCount=8 -jar "$rdf2pg_jar" -gdm "$rdfsp_instance" > "$measurement_dir"/rdf2pg.txt || exit 1
# java -Xmx30720m -XX:ActiveProcessorCount=8 -jar "$rdf2pg_jar" -gdm "$rdfsp_instance" > /dev/null || exit

# Ensure rdf2pg created csv paths
ensure_path "$nres_csv"
ensure_path "$nlit_csv"
ensure_path "$nbn_csv"
ensure_path "$edtp_csv"
ensure_path "$eop_csv"
ensure_path "$edtp_part_txt"
ensure_path "$eop_part_txt"

rdf2pg_end=$(get_ts)
echo "RDF2PG, END, $rdf2pg_end"
$exectime_sh "RDF2PG" "$rdf2pg_start" "$rdf2pg_end" 

# Created init sql file
$writesql_sh "$graphname" "$nres_csv" "$nlit_csv" "$nbn_csv" || exit 1
import_dir="$data_dir"/"import"
init_sql="$import_dir"/init.sql
ensure_path "$init_sql"

# Created node sql files
nodes_dir="$import_dir"/nodes
nres_sql="$nodes_dir"/nres.sql
nlit_sql="$nodes_dir"/nlit.sql
nbn_sql="$nodes_dir"/nbn.sql
ensure_path "$nres_sql"
ensure_path "$nlit_sql"
ensure_path "$nbn_sql"

# Create edge partitions and sql files
# Input: {edtp, eop}.csv
# Output: {edtp, eop}/*.csv, {edtp, eop}/import/*.sql
edgepart_start=$(get_ts)
echo "EDGEPARTITIONING, START, $edgepart_start"
$edgepart_sh "$graphname" "$edtp_csv" "$edtp_part_txt" "$import_sql" || exit 1
$edgepart_sh "$graphname" "$eop_csv" "$eop_part_txt" "$import_sql" || exit 1
edgepart_end=$(get_ts)
echo "EDGEPARTITIONING, END, $edgepart_end"
$exectime_sh "EDGEPARTITIONING" "$edgepart_start" "$edgepart_end"

# Created edge sql files
edges_dir="$import_dir"/edges
edtp_sql="$edges_dir"/edtp.sql
eop_sql="$edges_dir"/eop.sql
ensure_path "$edtp_sql"
ensure_path "$eop_sql"

# Init rapsql graph using init.sql
rapsql_txt="$measurement_dir"/rapsql.txt
# echo "CREATE GRAPH $graphname"
psql -q -U postgres -d rapsql -f "$init_sql" > "$rapsql_txt" || exit 1

# Import nodes in parallel
# Input: import/{nres, nlit, nbn}.sql 
dbimport_nodes_start=$(get_ts)
echo "DBIMPORT-NODES, START, $dbimport_nodes_start"
$sqlimport_sh "$nodes_dir" "$rapsql_txt" || exit 1
dbimport_nodes_end=$(get_ts)
echo "DBIMPORT-NODES, END, $dbimport_nodes_end"
$exectime_sh "DBIMPORT-NODES" "$dbimport_nodes_start" "$dbimport_nodes_end"

# Import edges in parallel
# Input: {edtp, eop}/import/*.sql
dbimport_edges_start=$(get_ts)
echo "DBIMPORT-EDGES, START, $dbimport_edges_start"
$sqlimport_sh "$edges_dir" "$rapsql_txt" || exit 1
# $sqlimport_sh "$edtp_sql_dir" "$rapsql_txt" || exit 1
# $sqlimport_sh "$eop_sql_dir" "$rapsql_txt" || exit 1
dbimport_edges_end=$(get_ts)
echo "DBIMPORT-EDGES, END, $dbimport_edges_end"
$exectime_sh "DBIMPORT-EDGES" "$dbimport_edges_start" "$dbimport_edges_end"

# Input: *.ypg
# Output: *.csv, import.sql
# csv2rapsql_start=$(get_ts)
# echo "CSV2RAPSQL, START, $csv2rapsql_start"
# # taskset -c 0-$(($(nproc)-1)) "$csv2rapsql_sh" "$graphname" "$rdf2pg_nodes" "$rdf2pg_edges" || exit 1
# $csv2rapsql_sh "$graphname" "$nres_csv" "$nlit_csv" "$nbn_csv" "$edtp_csv" "$eop_csv" "$import_sql" "$writesql_sh" "$exectime_sh" "$epart_sh" || exit 1

# taskset -c $(seq -s, 0 $((cores-1))) "$csv2rapsql_sh" "$graphname" "$rdf2pg_nodes" "$rdf2pg_edges" || exit 1
# taskset -c 0-$(($(nproc)-1)) "$csv2rapsql_sh" "$graphname" "$rdf2pg_nodes" "$rdf2pg_edges" || exit 1
# numactl --physcpubind=all --membind=all "$csv2rapsql_sh" "$graphname" "$rdf2pg_nodes" "$rdf2pg_edges" || exit 1
# numactl --physcpubind=all "$csv2rapsql_sh" "$graphname" "$rdf2pg_nodes" "$rdf2pg_edges" || exit 1
# csv2rapsql_end=$(get_ts)
# echo "CSV2RAPSQL, END, $csv2rapsql_end"
# $exectime_sh "CSV2RAPSQL" "$csv2rapsql_start" "$csv2rapsql_end"

# # Run db import
# # Input: import.sql
# dbimport_start=$(get_ts)
# echo "DBIMPORT, START, $dbimport_start"
# # psql -U postgres -d rapsql -f "$data_dir/import.sql" > "$measurement_dir"/rapsql.txt || exit  
# # psql without notices -q
# psql -q -U postgres -d rapsql -f "$import_sql" > "$measurement_dir"/rapsql.txt || exit 1
# # psql -U postgres -d rapsql -f "$data_dir/import.sql" > /dev/null || exit  
# # docker exec -it rapsqldb-container psql "postgres://postgres:postgres@rapsqldb:5432/rapsql" -f "mnt/rdf2rapsql/data/sp100/import.sql"
# dbimport_end=$(get_ts)
# echo "DBIMPORT, END, $dbimport_end"
# $exectime_sh "DBIMPORT" "$dbimport_start" "$dbimport_end"
