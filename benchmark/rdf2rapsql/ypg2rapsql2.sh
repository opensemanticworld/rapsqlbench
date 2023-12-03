#!/bin/bash

# Author:  Andreas Raeder
# License: Apache License 2.0

# Input
graph_name="$1"
rdf2pg_nodes="$2"
rdf2pg_edges="$3"
# graph_name becomes a schema in rapsql as age graph
# https://age.apache.org/age-manual/master/intro/graphs.html
# https://www.postgresql.org/docs/current/ddl-schemas.html
# https://www.postgresql.org/docs/9.2/sql-syntax-lexical.html

# Ensure graph name
if [ -z "$graph_name" ]; then
  echo "Graph name must not be empty"
  exit 1
fi
# Grammer graph name
# 1 names beginning with pg_ or ag_ are reserved for system schemas
# 2 no white spaces
# 3 no special characters
# 4 follow lexical rules of postgresql and apache age
if [[ "$graph_name" =~ ^pg_.* ]]; then
  echo "Graph name must not begin with pg_"
  exit 1
elif [[ "$graph_name" =~ ^ag_.* ]]; then
  echo "Graph name must not begin with ag_"
  exit 1
elif [[ "$graph_name" =~ [[:space:]] ]]; then
  echo "Graph name must not contain white spaces"
  exit 1
elif [[ "$graph_name" =~ [^a-zA-Z0-9_] ]]; then
  echo "Graph name must not contain special characters"
  exit 1
else
  echo "YPG2RAPSQL, GRAPH, $graph_name"
fi

# Ensure nodes path
if [ ! -f "$rdf2pg_nodes" ]; then
  echo "File not found: $rdf2pg_nodes"
  exit 1
fi

# Ensure edges path
if [ ! -f "$rdf2pg_edges" ]; then
  echo "File not found: $rdf2pg_edges"
  exit 1
fi

# Function to get the current timestamp
get_ts() {
  # TS nanosecond precision 6 and UTC two digits similar to ISO 8601 and PostgreSQL
  ts=$(date +"%Y-%m-%d %H:%M:%S.%6N%:::z")
  echo "$ts"
}


# TODO! CHANGE SRC_DIR TO BASENAME AND DOCKER PATH!!!!

# Config paths
src_dir=$(dirname "$rdf2pg_nodes")
nres_instance=$src_dir/nres.csv
nlit_instance=$src_dir/nlit.csv
nbn_instance=$src_dir/nbn.csv
edtp_instance=$src_dir/edtp.csv
eop_instance=$src_dir/eop.csv

# I. Start ypg to rapsql parser
# Split node types 
grep '^Resource'         "$rdf2pg_nodes" > "$nres_instance"
grep '^Literal'          "$rdf2pg_nodes" > "$nlit_instance"
grep '^BlankNode'        "$rdf2pg_nodes" > "$nbn_instance"
# Split edge types
grep '^DatatypeProperty' "$rdf2pg_edges" > "$edtp_instance"
grep '^ObjectProperty'   "$rdf2pg_edges" > "$eop_instance"
# 1 Copy head to tail
sed -i '1p;' "$src_dir"/*.csv
# 2 -> rm data head -> rm data tail
sed -i '1s/;[^,]*//g;1n; s/,[^;]*;/,/g' "$src_dir"/*.csv
# 3 -> rm type node or edge 
sed -i 's/^[^,]*,//' "$src_dir"/*.csv
# End ypg to rapsql parser

# Output parser
echo "YPG2RAPSQL, RESOURCE, $nres_instance"
echo "YPG2RAPSQL, LITERAL,  $nlit_instance"
echo "YPG2RAPSQL, BLANKNODE, $nbn_instance"
echo "YPG2RAPSQL, DATATYPEPROPERTY, $edtp_instance"
echo "YPG2RAPSQL, OBJECTPROPERTY, $eop_instance"

# Write SQL import file by dir path of this script
BASEDIR="$(dirname "$0")"
WRITESQL="$BASEDIR/writesql2.sh"
# FILE ABS PATH
WRIETESQL_ABS=$(realpath "$WRITESQL")
# realpath of basedir as single line
# BASEDIR=$(dirname "$EXEC")
$WRIETESQL_ABS "$graph_name" "$nres_instance" "$nlit_instance" "$nbn_instance" || exit 1
echo "YPG2RAPSQL, SCRIPT, $WRIETESQL_ABS" 

# Output SQL import file
sql_file="$src_dir/import.sql"

# II. Partion edges and append to sql file
# Run edge partitioning script
exectime_sh=$(dirname "$BASEDIR")/exectime.sh
EPART_ABS=$(realpath "$BASEDIR/epart.sh")
echo "YPG2RAPSQL, SCRIPT, $EPART_ABS"
epart_start=$(get_ts)
echo "YPG2RAPSQL-EPART, START, $epart_start"
taskset -c 0-$(($(nproc)-1)) "$EPART_ABS" "$graph_name" "$edtp_instance" "$sql_file" || exit 1
taskset -c 0-$(($(nproc)-1)) "$EPART_ABS" "$graph_name" "$eop_instance" "$sql_file" || exit 1
# numactl --physcpubind=all --membind=all "$EPART_ABS" "$graph_name" "$edtp_instance" "$sql_file" || exit 1
# numactl --physcpubind=all --membind=all "$EPART_ABS" "$graph_name" "$eop_instance" "$sql_file" || exit 1
# numactl --physcpubind=all "$EPART_ABS" "$graph_name" "$edtp_instance" "$sql_file" || exit 1
# numactl --physcpubind=all "$EPART_ABS" "$graph_name" "$eop_instance" "$sql_file" || exit 1
# Append timestamp creation for end of import from rapsql
echo "SELECT now() AS \"IMPORT END\";" >> "$sql_file"
epart_end=$(get_ts)
echo "YPG2RAPSQL-EPART, END, $epart_end"
$exectime_sh "YPG2RAPSQL-EPART" "$epart_start" "$epart_end"
# Write SQL import file path to stdout
echo "YPG2RAPSQL, SCRIPT, $sql_file"
