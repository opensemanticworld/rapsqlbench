#!/bin/bash

graph_name=$1
query_dir=$2
model=$3
transpiler=$4

### Rapsqltranspiler version ###
# Provide manual written q6 and q7 (unsupported by rapsqltranspiler)
manual_version="v1"
# Provide transpiler version 
# Version grammer: vMAJOR.MINOR.PATCH
# Major is hardcoded yet
major=0
# Model sets minor version
if [[ $model == "yars" ]]; then
  minor=3
elif [[ $model == "rdfid" ]]; then
  minor=4
fi
# Transpiler sets patch version
if [[ $transpiler == "plain" ]]; then
  patch=0
elif [[ $transpiler == "cpo1" ]]; then
  patch=1
elif [[ $transpiler == "cpo2" ]]; then
  patch=2
elif [[ $transpiler == "cpo3" ]]; then
  patch=3
fi
# Set version
version="v$major.$minor.$patch"

### Paths ###
sparql_dir="$query_dir/sparql"
cypher_dir="$query_dir/cypher/$graph_name"
dir_path=$(dirname "$(realpath "$0")")
transpiler_dir="$dir_path/$version-$model-$transpiler"
q6provider_sh="$dir_path/manual-queries/$model/$manual_version/q6provider.sh"
q7provider_sh="$dir_path/manual-queries/$model/$manual_version/q7provider.sh"
rapsqltranspiler_jar="$transpiler_dir/rapsqltranspiler-$version-jar-with-dependencies.jar"


### Create base file for cypher query as sql file ###
sql_create_basefile() {
  local sql_file="$1"
  keyword="$(basename "$sql_file" .sql)"
  # Create base file
  echo -E "-- cypher/$keyword.sql

-- age config
LOAD 'age';
SET search_path TO ag_catalog;
\timing
" > "$sql_file"
}

### Provider manual cypher transformation (q6.sparql and q7.sparql) ###
manual_s2c() {
  local provider_sh="$1"
  local graph_name="$2"
  local file_path="$3"
  sql_create_basefile "$file_path"
  "$provider_sh" "$graph_name" > "$file_path" || exit 1
}

### Provider sparql to cypher transpiled query (all other sparql queries) ###
transpiler_s2c() {
  local sparql_file="$1"
  local graph_name="$2"
  local file_path="$3"
  sql_create_basefile "$file_path"
  java -jar "$rapsqltranspiler_jar" "$graph_name" "$sparql_file" >> "$file_path" || exit 1
}

### Transform all sparql queries to cypher queries ###
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
