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

# Config paths
cwd=$(pwd)
measurement_dir=$cwd/measurement/"$graphname"
src_path="$cwd"/data/"$graphname"/"$graphname".n3
src_dir=$(dirname "$src_path") 
# rdfsp_jar=$cwd/rdfsp/rdfs-processor.jar
rdf2pg_jar=$cwd/rdf2pg/rdf2pg.jar
# rdf2pg_jar=$cwd/rdf2pg/rdf2pg-v0.1.0-jar-with-dependencies.jar
rdf2rapsql_dir=$cwd/rdf2rapsql
ypg2rapsql_sh="$rdf2rapsql_dir/ypg2rapsql2.sh"
exectime_sh="$cwd/exectime.sh"

# Change directory to data source directory
cd "$src_dir" || exit 0

# Display input instance
echo "RDF2RAPSQL, INSTANCE, $src_path"
echo "RDF2RAPSQL, PID, $$"


# Run rdf2pg
# Input: x.nt
# Output: nodes.ypg, edges.ypg, nodes_schema.ypg, edges_schema.ypg
rdf2pg_start=$(get_ts)
echo "RDF2PG, START, $rdf2pg_start"
java -Xmx"$memory"m -XX:ActiveProcessorCount="$cores" -jar "$rdf2pg_jar" -gdm "$src_path" > "$measurement_dir"/rdf2pg.txt || exit 1 
# java -Xmx24576m -XX:ActiveProcessorCount="$cores" -jar "$rdf2pg_jar" -gdm "$src_path" > "$measurement_dir"/rdf2pg.txt || exit 1 # changed to src_path
# java -Xmx24576m -XX:ActiveProcessorCount=8 -jar "$rdf2pg_jar" -gdm "$rdfsp_instance" > "$measurement_dir"/rdf2pg.txt || exit 1
# java -Xmx30720m -XX:ActiveProcessorCount=8 -jar "$rdf2pg_jar" -gdm "$rdfsp_instance" > /dev/null || exit
rdf2pg_nodes=$src_dir/nodes.ypg
rdf2pg_edges=$src_dir/edges.ypg
echo "RDF2PG, NODES, $rdf2pg_nodes"
echo "RDF2PG, EDGES, $rdf2pg_edges"
rdf2pg_end=$(get_ts)
echo "RDF2PG, END, $rdf2pg_end"
$exectime_sh "RDF2PG" "$rdf2pg_start" "$rdf2pg_end" 

# Run ypg2rapsql
# Input: *.ypg
# Output: *.csv, import.sql
ypg2rapsql_start=$(get_ts)
echo "YPG2RAPSQL, START, $ypg2rapsql_start"
# taskset -c $(seq -s, 0 $((cores-1))) "$ypg2rapsql_sh" "$graphname" "$rdf2pg_nodes" "$rdf2pg_edges" || exit 1
taskset -c 0-$(($(nproc)-1)) "$ypg2rapsql_sh" "$graphname" "$rdf2pg_nodes" "$rdf2pg_edges" || exit 1
# numactl --physcpubind=all --membind=all "$ypg2rapsql_sh" "$graphname" "$rdf2pg_nodes" "$rdf2pg_edges" || exit 1
# numactl --physcpubind=all "$ypg2rapsql_sh" "$graphname" "$rdf2pg_nodes" "$rdf2pg_edges" || exit 1
ypg2rapsql_end=$(get_ts)
echo "YPG2RAPSQL, END, $ypg2rapsql_end"
$exectime_sh "YPG2RAPSQL" "$ypg2rapsql_start" "$ypg2rapsql_end"

# Run db import
# Input: import.sql
echo "IMPORT, START, $(get_ts)"
# psql -U postgres -d rapsql -f "$src_dir/import.sql" > "$measurement_dir"/rapsql.txt || exit  
# psql without notices -q
psql -q -U postgres -d rapsql -f "$src_dir/import.sql" > "$measurement_dir"/rapsql.txt || exit 1
# psql -U postgres -d rapsql -f "$src_dir/import.sql" > /dev/null || exit  
# docker exec -it rapsqldb-container psql "postgres://postgres:postgres@rapsqldb:5432/rapsql" -f "mnt/rdf2rapsql/data/sp100/import.sql"
rdf2rapsql_end=$(get_ts)
echo "IMPORT, END, $rdf2rapsql_end"
$exectime_sh "IMPORT" "$ypg2rapsql_end" "$rdf2rapsql_end"
