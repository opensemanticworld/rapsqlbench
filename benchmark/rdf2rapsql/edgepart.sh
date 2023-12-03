#!/bin/bash

graph_name=$1
raw_file_path=$2
raw_part_file_path=$3
# sql_file=$4

file_name=$(basename "$raw_file_path" .csv)
raw_file_dir=$(dirname "$raw_file_path")
part_dir="$raw_file_dir"/"$file_name"
# sql_dir="$part_dir"/import
sql_dir="$raw_file_dir"/import/edges
mkdir -p "$sql_dir" "$part_dir"

# Create initial sql file
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

SELECT now() AS \"START DBIMPORT $keyword\";
" > "$sql_file"
}

# Create SQL statement functions
sql_create_elabel() {
  local sql_file="$1"
  local graph_name="$2"
  local elabel="$3"
  # Create elabel
  echo "SELECT create_elabel('$graph_name','$elabel');" >> "$sql_file"
}

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

# single sql file
output_sql="${sql_dir}/${file_name}.sql"
sql_create_basefile "$output_sql" "$file_name"


# Read the lines from the text file
while IFS= read -r line; do
  # Execution for each line in parallel
  {
    # Place your command or script here
    # echo "Processing $line"
    keyword=$(echo "$line" | grep -oE '[^/#]+$')
    # echo "keyword: $keyword"
    output_csv="${part_dir}/${keyword}.csv"

    # echo "output_csv: $output_csv"
    echo "start_id,start_vertex_type,end_id,end_vertex_type,iri" > "$output_csv"
    grep ".*$line$" "$raw_file_path" >> "$output_csv"
    # create sql file per edge label
    sql_create_elabel "$output_sql" "$graph_name" "$keyword"
    sql_load_edges_from_file "$output_sql" "$graph_name" "$keyword" "$output_csv"
  } &
done < "$raw_part_file_path"

# Wait for all background processes to finish
wait


# multiple sql files

# # Read the lines from the text file
# while IFS= read -r line; do
#   # Execution for each line in parallel
#   {
#     # Place your command or script here
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
