#!/bin/bash

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

# Run RDF2PG
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

# Created init sql file
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
dbimport_edges_end=$(get_ts)
echo "DBIMPORT-EDGES, END, $dbimport_edges_end"
$exectime_sh "DBIMPORT-EDGES" "$dbimport_edges_start" "$dbimport_edges_end"
