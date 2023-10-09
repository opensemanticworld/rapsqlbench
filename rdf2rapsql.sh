#!/bin/bash

# Usage for 125m triples: 
# /bin/bash "/usr/local/docker/masterthesis/rapsql/mnt/rdf2rapsql/rdf2rapsql.sh" | tee measurement/sp125m/rdf2rapsql.txt

# Function to check if a value is a positive integer
is_positive_integer() {
  if [[ $1 =~ ^[1-9][0-9]*$ ]]; then
    return 0
  else
    return 1
  fi
}

# Prompt for a positive integer if no -t flag was set
if [[ $# -eq 0 ]]; then
  while true; do
    read -p "Please enter a positive integer: " input
    if is_positive_integer "$input"; then
      triples=$input
      break
    else
      echo "Error: Invalid input. Please enter a positive integer."
    fi
  done
else
  # Parse command line arguments
  while getopts ":t:" opt; do
    case $opt in
      t)
        if is_positive_integer "$OPTARG"; then
          triples=$OPTARG
        else
          echo "Error: Invalid argument for -t. Please provide a positive integer." >&2
          exit 1
        fi
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
      :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    esac
  done
fi

# Schema output.txt | TODO: write for each measurement into output.txt
# process name | process type | value


# Function to get the current timestamp
get_ts() {
  # TS nanosecond precision 6 and UTC two digits similar to ISO 8601 and PostgreSQL
  ts=$(date +"%Y-%m-%d %H:%M:%S.%6N%:::z")
  echo "$ts"
}


############################# TEST #############################
# Simulate some system loads:
# https://bash-prompt.net/guides/create-system-load/
# CPU
# echo "CREATE CPU LOAD";dd if=/dev/zero of=/dev/null
################################################################

# Config paths
cwd=$(pwd)
measurement_dir=$cwd/measurement/sp"$triples"
src_path="$cwd"/data/sp"$triples"/sp"$triples".n3
src_dir=$(dirname "$src_path") 
src_dir_name=$(basename "$src_dir") # = graph_name
rdfsp_jar=$cwd/rdfsp/rdfs-processor.jar
rdf2pg_jar=$cwd/rdf2pg/rdf2pg.jar
ypg2rapsql_dir=$cwd/ypg2rapsql
ypg2rapsql_sh="$ypg2rapsql_dir/ypg2rapsql.sh"

# Change directory to data source directory
cd "$src_dir" || exit  

# Display input instance
echo "RDF2RAPSQL, INSTANCE, $src_path"
echo "RDF2RAPSQL, PID, $$"

# Run rdfsp
# input file x.n3
# cd $tmp_rdfsp_dir
echo "RDFSP, START, $(get_ts)"
# java -Xmx30720m -XX:ActiveProcessorCount=8 -jar $rdfsp_jar -d $src_path > output.txt
java -Xmx24576m -XX:ActiveProcessorCount=8 -jar "$rdfsp_jar" -d "$src_path" > "$measurement_dir"/rdfsp.txt || exit 1
rdfsp_instance="$src_dir/instance.nt"
echo "RDFSP, INSTANCE, $rdfsp_instance"
echo "RDFSP, END, $(get_ts)"

# Run rdf2pg
# Input: x.nt
# Output: instance.ypg, schema.ypg
echo "RDF2PG, START, $(get_ts)"
java -Xmx24576m -XX:ActiveProcessorCount=8 -jar "$rdf2pg_jar" -gdm "$rdfsp_instance" > "$measurement_dir"/rdf2pg.txt || exit 1
# java -Xmx30720m -XX:ActiveProcessorCount=8 -jar "$rdf2pg_jar" -gdm "$rdfsp_instance" > /dev/null || exit
rdf2pg_nodes=$src_dir/nodes.ypg
rdf2pg_edges=$src_dir/edges.ypg
echo "RDF2PG, NODES, $rdf2pg_nodes"
echo "RDF2PG, EDGES, $rdf2pg_edges"
echo "RDF2PG, END, $(get_ts)"

# Run ypg2rapsql
# Input: *.ypg
# Output: *.csv, import.sql
ypg2rapsql_start=$(get_ts)
echo "YPG2RAPSQL, START, $ypg2rapsql_start"
$ypg2rapsql_sh "$src_dir_name" "$rdf2pg_nodes" "$rdf2pg_edges" || exit 1
ypg2rapsql_end=$(get_ts)
echo "YPG2RAPSQL, END, $ypg2rapsql_end"

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
