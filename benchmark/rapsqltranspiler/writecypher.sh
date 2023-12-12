#!/bin/bash

graph_name=$1

# rapsqltranspiler version
# version="v0.1.2-L2L-L2R"
version="v0.1.3-L2L"

# Paths
dir_path=$(dirname "$(realpath "$0")")
sparql_dir="$dir_path/sparql"
cypher_dir="$dir_path/cypher/$version/$graph_name"
q6provider_sh="$dir_path/q6provider.sh"
q7provider_sh="$dir_path/q7provider.sh"
rapsqltranspiler_jar="$dir_path/rapsqltranspiler-$version.jar"

# Target directory
mkdir -p "$cypher_dir"

# Create base file for cypher query as sql file
sql_create_basefile() {
  local sql_file="$1"
  keyword="$(basename "$sql_file" .sql)"
  # Create base file
  echo "-- cypher/$keyword.sql

-- age config
LOAD 'age';
SET search_path TO ag_catalog;
" > "$sql_file"
}

# Provider manual cypher transformation (q6.sparql and q7.sparql)
manual_s2c() {
  local provider_sh="$1"
  local graph_name="$2"
  local file_path="$3"
  sql_create_basefile "$file_path"
  "$provider_sh" "$graph_name" > "$file_path" || exit 1
}

# Provider sparql to cypher transpiled query (all other sparql queries)
transpiler_s2c() {
  local sparql_file="$1"
  local graph_name="$2"
  local file_path="$3"
  sql_create_basefile "$file_path"
  java -jar "$rapsqltranspiler_jar" "$graph_name" "$sparql_file" >> "$file_path" || exit 1
}

# Transform all sparql queries to cypher queries
for sparql_file in "$sparql_dir"/*.sparql; do

  # transform sparql_file name into .sql instead of .sparql
  sql_name=$(basename "$sparql_file" .sparql).sql

  # use manual cypher transformation by providers for q6.sparql and q7.sparql
  if [ "$sparql_file" == "$sparql_dir"/i9-q6.sparql ]; then
    manual_s2c "$q6provider_sh" "$graph_name" "$cypher_dir/$sql_name"
    continue
  fi 
  if [ "$sparql_file" == "$sparql_dir"/j10-q7.sparql ]; then
    manual_s2c "$q7provider_sh" "$graph_name" "$cypher_dir/$sql_name"
    continue
  fi

  # use rapsqltranspiler.jar for all other sparql queries
  transpiler_s2c "$sparql_file" "$graph_name" "$cypher_dir/$sql_name" &

done

wait
