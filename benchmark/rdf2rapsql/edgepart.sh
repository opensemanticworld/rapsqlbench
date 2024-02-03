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

# Input parameters
graph_name=$1
model=$2
raw_file_path=$3
raw_part_file_path=$4

# Paths
file_name=$(basename "$raw_file_path" .csv)
raw_file_dir=$(dirname "$raw_file_path")
part_dir="$raw_file_dir"/"$file_name"
# sql_dir="$part_dir"/import
sql_dir="$raw_file_dir"/import/edges
mkdir -p "$sql_dir" "$part_dir"

### FUNCTIONS TO CREATE FILE-BASED SQL STATEMENTS START ###
# Function create AGE sql basefiles
sql_create_basefile() {
  local sql_file="$1"
  local keyword="$2"
  # Create base file
  echo "--import/$keyword.sql

-- age config
LOAD 'age';
SET search_path TO ag_catalog;

-- disable notices https://stackoverflow.com/a/3531274
SET client_min_messages TO WARNING;

SELECT now() AS \"START DBIMPORT $keyword\";" > "$sql_file"
}

# Function AGE create elabel statement (edges)
sql_create_elabel() {
  local sql_file="$1"
  local graph_name="$2"
  local elabel="$3"
  # Create elabel
  echo "
-- $elabel   
SELECT create_elabel('$graph_name','$elabel');" >> "$sql_file"
}

# Function AGE load labels from file statement (edges)
sql_load_edges_from_file() {
  local sql_file="$1"
  local graph_name="$2"
  local elabel="$3"
  local csv_path="$4"
  # Append load edges from file statement
  echo "
SELECT load_edges_from_file(
  '$graph_name',
  '$elabel',
  '$csv_path'
);

SELECT now() AS \"END DBIMPORT $elabel\";" >> "$sql_file"
}
### FUNCTIONS TO CREATE FILE-BASED SQL STATEMENTS END ###


### EDGE PARTITIONING START ###
# Init sql file (edtp and eop are called separately)
output_sql="${sql_dir}/${file_name}.sql"
sql_create_basefile "$output_sql" "$file_name"

# Header model set edge property name
if [ "$model" == "rdfid" ]; then
  property_name="rdfid"
elif [ "$model" == "yars" ]; then
  property_name="iri"
fi

# Create edge partition CSV files in parallel
while IFS= read -r line; do
  # Execution for each line in parallel
  {
    keyword=$(echo "$line" | grep -oE '[^/#]+$')
    output_csv="${part_dir}/${keyword}.csv"
    echo "start_id,start_vertex_type,end_id,end_vertex_type,$property_name" > "$output_csv"
    grep ".*$line$" "$raw_file_path" >> "$output_csv"
  } &
done < "$raw_part_file_path"

# Wait for all background processes to finish
wait

# Create sql files and append statements sequentially (keep order)
while IFS= read -r line; do
  keyword=$(echo "$line" | grep -oE '[^/#]+$')
  # echo "keyword: $keyword"
  output_csv="${part_dir}/${keyword}.csv"
  # create sql file per edge label
  sql_create_elabel "$output_sql" "$graph_name" "$keyword"
  sql_load_edges_from_file "$output_sql" "$graph_name" "$keyword" "$output_csv"
done < "$raw_part_file_path"
### EDGE PARTITIONING END ###


####### EXPERIMENTAL START ######
# multiple sql files in parallel

# # Read the lines from the text file
# while IFS= read -r line; do
#   # Execution for each line in parallel
#   {
#     # echo "Processing $line"
#     keyword=$(echo "$line" | grep -oE '[^/#]+$')
#     # echo "keyword: $keyword"
#     output_csv="${part_dir}/${keyword}.csv"
#     output_sql="${sql_dir}/${keyword}.sql"

#     # echo "output_csv: $output_csv"
#     echo "start_id,start_vertex_type,end_id,end_vertex_type,iri" > "$output_csv"
#     grep ".*$line$" "$raw_file_path" >> "$output_csv"
#     # create sql file per edge label
#     sql_create_basefile "$output_sql" "$keyword"
#     sql_create_elabel "$output_sql" "$graph_name" "$keyword"
#     sql_load_edges_from_file "$output_sql" "$graph_name" "$keyword" "$output_csv"
#   } &
# done < "$raw_part_file_path"

# # Wait for all background processes to finish
# wait
####### EXPERIMENTAL END ######
