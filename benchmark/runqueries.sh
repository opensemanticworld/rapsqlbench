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
cypher_dir=$1
measurement_dir=$2
exectime_sh=$3
iterations=$4
skip_penalized_queries=$5


### FUNCTION DEFINITIONS START ###
# Function to get the current timestamp
get_ts() {
  # TS nanosecond precision 6 and UTC two digits similar to ISO 8601 and PostgreSQL
  ts=$(date +"%Y-%m-%d %H:%M:%S.%6N%:::z")
  echo "$ts"
}

# Function to penalize queries with timeout or error
penalize_query() {
  local folder="$1"
  local loop_cnt="$2"
  local penalty_file="$3"
  # Find all .txt files in the folder
  files=$(find "$folder" -type f -name "*.txt")
  # Loop through each file and check the last line for the keyword "timeout" or "ERROR"
  for file in $files; do
    # last_line=$(tail -n 1 "$file")
    # if [[ $last_line == *timeout* ]]; then
    # if grep -q "statement timeout" "$file"; then  # only timeout
    if grep -q "statement timeout" "$file" || grep -q "ERROR" "$file"; then  # timeout and error
      # query name is the filename
      local penalty="3600000.000 ms"
      query=$(basename "$file" .txt).sql
      echo "QUERY-PENALTY | loop-$loop_cnt | $query, PENALTY-TIME, $penalty"
      # make penalty dir in cypher_dir
      timeouts_dir="$cypher_dir/penalty/loop-$loop_cnt"
      mkdir -p "$timeouts_dir"

      # add penalty time to response file
      echo -e "\npenalty\nTime: $penalty" >> "$file"
      # add query txt name to penalty list
      echo "$file" >> "$penalty_file"

      # if skip_penalized_queries, then move raw penalty files to penalty dir
      if [ "$skip_penalized_queries" ]; then
        # move sql file to penalty dir
        mv -f "$cypher_dir"/"$query" "$timeouts_dir"/"$query"
        # move response file to penalty dir
        # mv -f "$file" "$timeouts_dir/"
      fi
    fi
  done
}

# Function to create a txt response file for each penality query
create_penalty_responses() {
  local penalty_file="$1"
  local loop_cnt="$2"
  local response_loop_dir="$3"
  local penalty="3600000.000 ms"
  # If found .txt inside of penalty file, then iterate over each line in penalty file and print the filename 
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
### FUNCTION DEFINITIONS END ###


# Create penalty list
responses_dir="$cypher_dir/responses"
penalty_txt="$measurement_dir/penalty.txt"
mkdir -p "$responses_dir"
echo -n "" > "$penalty_txt"


### RUN ALL CYPHER QUERIES IN CYPHER DIRECTORY ###
# Outer loop for iterations
for ((i=1; i<=iterations; i++)) do
  responses_loop_dir="$cypher_dir/responses/loop-$i"
  # Create responses directory
  mkdir -p "$responses_loop_dir"
  # Inner loop for each cypher file that has not been penalized
  for cypher_file in "$cypher_dir"/*.sql; do
    # Define the response file name
    cypher_file_name=$(basename "$cypher_file" .sql)
    cypher_responses_file="$responses_loop_dir/$cypher_file_name".txt
    # Provide log message
    log_msg="QUERY-EXEC | loop-$i | $cypher_file_name"
    # Wait for 3 s before each query
    sleep 3
    start_ts=$(get_ts)
    echo "$log_msg, START, $start_ts"
    # echo "cypher_file: $cypher_file"
    
    # Run psql exec and save responses to file
    sudo -u postgres psql -U postgres -d postgres -f "$cypher_dir/$cypher_file_name.sql" > "$cypher_responses_file" 2>&1

    end_ts=$(get_ts)
    echo "$log_msg, END, $end_ts"
    $exectime_sh "$log_msg" "$start_ts" "$end_ts"
  done

  # If skip_penalized_queries, then create penalty responses
  if [ "$skip_penalized_queries" ]; then
    create_penalty_responses "$penalty_txt" "$i" "$responses_loop_dir"
  fi
  # Penalize queries with timeout or error, and move to penalty dir to skip next iteration
  penalize_query "$responses_loop_dir" "$i" "$penalty_txt"
done
### RUN ALL CYPHER QUERIES IN CYPHER DIRECTORY ###


# Prevent EOF error
exit 0
