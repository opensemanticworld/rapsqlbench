#!/bin/bash

# Author:  Andreas Raeder
# License: Apache License 2.0

# Input
graph_name=$1
nres_csv=$2
nlit_csv=$3
nbn_csv=$4
edtp_csv=$5
eop_csv=$6
import_sql=$7
writesql_sh=$8
exectime_sh=$9
epart_sh=${10}

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


# Write nodes to sql file
$writesql_sh "$graph_name" "$nres_csv" "$nlit_csv" "$nbn_csv" || exit 1

# Partion edges and append to sql file
epart_start=$(get_ts)
echo "CSV2RAPSQL-EPART, START, $epart_start"
taskset -c 0-$(($(nproc)-1)) "$epart_sh" "$graph_name" "$edtp_csv" "$import_sql" || exit 1
taskset -c 0-$(($(nproc)-1)) "$epart_sh" "$graph_name" "$eop_csv" "$import_sql" || exit 1
# numactl --physcpubind=all --membind=all "$epart_sh" "$graph_name" "$edtp_csv" "$import_sql" || exit 1
# numactl --physcpubind=all --membind=all "$epart_sh" "$graph_name" "$eop_csv" "$import_sql" || exit 1
# numactl --physcpubind=all "$epart_sh" "$graph_name" "$edtp_csv" "$import_sql" || exit 1
# numactl --physcpubind=all "$epart_sh" "$graph_name" "$eop_csv" "$import_sql" || exit 1
# Append timestamp creation for end of import from rapsql
echo "SELECT now() AS \"IMPORT END\";" >> "$import_sql"
epart_end=$(get_ts)
echo "CSV2RAPSQL-EPART, END, $epart_end"
$exectime_sh "CSV2RAPSQL-EPART" "$epart_start" "$epart_end"
# Write SQL import file path to stdout
echo "CSV2RAPSQL, SCRIPT, $import_sql"
