#!/bin/bash

cypher_dir=$1
exectime_sh=$2

cypher_response_dir="$cypher_dir"/response
mkdir -p "$cypher_response_dir"

# Function to get the current timestamp
get_ts() {
  # TS nanosecond precision 6 and UTC two digits similar to ISO 8601 and PostgreSQL
  ts=$(date +"%Y-%m-%d %H:%M:%S.%6N%:::z")
  echo "$ts"
}

# run all cypher queries in cypher_dir
for cypher_file in "$cypher_dir"/*.sql; do
  cypher_file_name=$(basename "$cypher_file" .sql)
  cypher_response_file="$cypher_response_dir"/"$cypher_file_name".txt
  start_ts=$(get_ts)
  echo "START, $cypher_file_name, $start_ts"
  # echo "cypher_file: $cypher_file"
  # run docker exec and save response to file
  docker exec rapsqldb-container psql -U postgres -d rapsql -f /mnt/rapsqlbench/benchmark/queries/cypher/sp100k/"$cypher_file_name.sql" > "$cypher_response_file"
  end_ts=$(get_ts)
  echo "END, $cypher_file_name, $end_ts"
  $exectime_sh "$cypher_file_name" "$start_ts" "$end_ts" 
done

# # run all cypher queries in cypher_dir 10 times
# for cypher_file in "$cypher_dir"/*.sql; do
#   cypher_file_name=$(basename "$cypher_file" .sql)
#   for i in {1..10}; do
#     start_ts=$(get_ts)
#     echo "START, $cypher_file_name, $start_ts"
#     echo "cypher_file: $cypher_file"
#     # docker exec rapsqldb-container psql -U postgres -d rapsql -f mnt/rapsqlbench/benchmark/queries/cypher/"$cypher_file"
#     end_ts=$(get_ts)
#     echo "END, $cypher_file_name, $end_ts"
#     $exectime_sh "$cypher_file_name" "$start_ts" "$end_ts" 
#   done
# done