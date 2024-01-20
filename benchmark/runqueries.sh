#!/bin/bash

cypher_dir=$1
measurement_dir=$2
exectime_sh=$3
iterations=$4
skip_tout_queries=$5

# echo "skip: $skip_tout_queries"

# extract graphname from cypher_dir


# Function to get the current timestamp
get_ts() {
  # TS nanosecond precision 6 and UTC two digits similar to ISO 8601 and PostgreSQL
  ts=$(date +"%Y-%m-%d %H:%M:%S.%6N%:::z")
  echo "$ts"
}

penalize_tout_query() {
  local folder="$1"
  local loop_cnt="$2"
  local penalty_file="$3"
  # Find all .txt files in the folder
  files=$(find "$folder" -type f -name "*.txt")
  # Loop through each file and check the last line for the keyword "timeout"
  for file in $files; do
    # last_line=$(tail -n 1 "$file")
    # if [[ $last_line == *timeout* ]]; then
    if grep -q "statement timeout" "$file"; then
      # query name is the filename
      local penalty="3600000.000 ms"
      query=$(basename "$file" .txt).sql
      echo "QUERY-TOUT | loop-$loop_cnt | $query, PENALTY, $penalty"
      # make timeout dir in cypher_dir
      timeouts_dir="$cypher_dir/timeouts/loop-$loop_cnt"
      mkdir -p "$timeouts_dir"

      # add penalty time to response file
      echo -e "\npenalty\nTime: $penalty" >> "$file"
      # add query txt name to penalty list
      echo "$file" >> "$penalty_file"

      # if skip_tout_queries, then move raw timeout files to timeout dir
      if [ "$skip_tout_queries" ]; then
        # move sql file to timeout dir
        mv -f "$cypher_dir"/"$query" "$timeouts_dir"/"$query"
        # move response file to timeout dir
        # mv -f "$file" "$timeouts_dir/"
      fi
    fi
  done
}

# function to create a txt response file for each penality query
create_penalty_responses() {
  local penalty_file="$1"
  local loop_cnt="$2"
  local response_loop_dir="$3"
  local penalty="3600000.000 ms"
  # if found .txt inside of penalty file, then iterate over each line in penalty file and print the filename 
  while IFS= read -r line; do
    file_basename="$(basename "$line" .txt)"
    # echo "file_basename: $file_basename"
    # create a text file with the query name in the response directory
    timeout_penalty_file="$response_loop_dir/$file_basename-skip.txt"
    # echo timeout_penalty_file: "$timeout_penalty_file"
    echo -e "\ntimeout query\npenalty\nTime: $penalty" > "$timeout_penalty_file"
    echo "QUERY-SKIP | loop-$loop_cnt | $file_basename, PENALTY, $penalty"
  done < "$penalty_file"
}

# create penalty list
responses_dir="$cypher_dir/responses"
penalty_txt="$measurement_dir/penalty.txt"
mkdir -p "$responses_dir"
echo -n "" > "$penalty_txt"

# run all cypher queries in cypher_dir
for ((i=1; i<=iterations; i++)) do
  responses_loop_dir="$cypher_dir/responses/loop-$i"
  mkdir -p "$responses_loop_dir"
  for cypher_file in "$cypher_dir"/*.sql; do
  cypher_file_name=$(basename "$cypher_file" .sql)
    cypher_responses_file="$responses_loop_dir/$cypher_file_name".txt
    log_msg="QUERY-EXEC | loop-$i | $cypher_file_name"
    
    # Wait for 3 s before each query
    sleep 3

    start_ts=$(get_ts)
    echo "$log_msg, START, $start_ts"
    # echo "cypher_file: $cypher_file"
    
    # run docker exec and save responses to file
    # docker exec rapsqldb-container psql -U postgres -d rapsql -f /mnt/rapsqlbench/benchmark/queries/cypher/"$graph_name"/"$cypher_file_name.sql" > "$cypher_responses_file" 2>&1
    psql -U postgres -d rapsql -f "$cypher_dir/$cypher_file_name.sql" > "$cypher_responses_file" 2>&1

    end_ts=$(get_ts)
    echo "$log_msg, END, $end_ts"
    $exectime_sh "$log_msg" "$start_ts" "$end_ts"
  done
  # if skip_tout_queries, then create penalty responses
  if [ "$skip_tout_queries" ]; then
    create_penalty_responses "$penalty_txt" "$i" "$responses_loop_dir"
  fi
  penalize_tout_query "$responses_loop_dir" "$i" "$penalty_txt"
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

# prevent EOF error
exit 0
