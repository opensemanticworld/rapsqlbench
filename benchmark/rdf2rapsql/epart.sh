#!/bin/bash

# Input parameter
graph_name=$1
raw_file_path=$2
sql_file=$3

# TEST PATH TO EXECTIME.SH (!delete if not needed!)
# echo "pwd: $(pwd)"
# echo "basedir: $(dirname "$0")"
# echo "parent basedir: $(dirname "$(dirname "$0")")"

# Check if graph_name is empty
if [ -z "$graph_name" ]; then
  echo "Graph name must not be empty"
  exit 1
fi

# Check if raw_file_path is a file
if [ ! -f "$raw_file_path" ]; then
  echo "File not found: $raw_file_path"
  exit 1
fi

# Check if sql_file is a file
if [ ! -f "$sql_file" ]; then
  echo "File not found: $sql_file"
  exit 1
fi

output_directory=$(basename "$raw_file_path" .csv)
out_dir_abs=$(realpath "$output_directory")

# Create the output directory if it doesn't exist
mkdir -p "$out_dir_abs"

# Create SQL statement functions
sql_create_elabel() {
  local graph_name="$1"
  local elabel="$2"
  local sql_file="$3"
  # Create elabel
  echo "SELECT create_elabel('$graph_name','$elabel');" >> "$sql_file"
}

sql_load_edges_from_file() {
  local graph_name="$1"
  local elabel="$2"
  local csv_path="$3"
  local sql_file="$4"
  # Append load edges from file statement
  echo "
SELECT load_edges_from_file(
  '$graph_name',
  '$elabel',
  '$csv_path'
);
SELECT now() AS \"IMPORT EDGE $elabel\";
" >> "$sql_file"
}


partition_edges() {
  local raw_file_path="$1"
  local output_directory="$2"
  # Extract the last word after a slash or hash and create a new CSV file for each
  # grep -oE '[^/#]+$' <(grep -oE 'http?://[^,]+' "$raw_file_path" | sort -u) | while read -r word; do
  grep -oE 'http?://[^,]+' "$raw_file_path" | sort -u | while read -r url; do
    # Generate the output filename based on the word
    word=$(echo "$url" | grep -oE '[^/#]+$')
    output_file="${output_directory}/${word}.csv"

    # output_path=$(realpath "$output_file")
    # echo "output_path: $output_path"

    # Create a new CSV file with the word as the filename and add the first line
    echo "start_id,start_vertex_type,end_id,end_vertex_type,iri" > "$output_file"
    # Extract all lines from the raw file that end with the word and append them to the output file
    grep ".*$url$" "$raw_file_path" >> "$output_file"
    # sed -n "/.*$url$/p" "$raw_file_path" >> "$output_file"
    # Append elabels stmt to sql file
    sql_create_elabel "$graph_name" "$word" "$sql_file"
    # Append load edges stmt to sql file
    sql_load_edges_from_file "$graph_name" "$word" "$output_file" "$sql_file"
  done
}

# Call function partition_edges
partition_edges "$raw_file_path" "$out_dir_abs"
capitalized_dirname=$(basename "$out_dir_abs" | tr '[:lower:]' '[:upper:]')
echo "CSV2RAPSQL-EPART, $capitalized_dirname-PART, $out_dir_abs/*.csv"
# count lines of csv file without header
# tail -n +2 eop.csv | wc -l

# count all partitioned csv files
# ls -1q "$output_dir" | wc -l
# find /usr/local/docker/masterthesis/rapsql/mnt/rapsqlbench/benchmark/data/sp100000/edtp -type f -name "*.csv" -exec tail -n +2 {} \; | wc -l