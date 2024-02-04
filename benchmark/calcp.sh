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

# Input Parameter
cypher_dir=$1
measurement_dir=$2
iterations=$3

# Config Paths
responses_dir=$cypher_dir/responses
exectimes_csv=$measurement_dir/exectimes.csv
performance_csv=$measurement_dir/performance.csv
exectimes_mean_csv=$measurement_dir/exectimes-mean.csv
performance_mean_csv=$measurement_dir/performance-mean.csv
rowcount_csv=$measurement_dir/rowcounts.csv


### FUNCTION DEFINITIONS START ###
# Use input_dir as parameter that has subfolders with .txt files to extract all execution times
function extract_execution_times {
  local input_dir=$1
  local csv_file=$2
  for dir in $(find "$input_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V); do    
    if [[ -d "$input_dir/$dir" ]]; then
      # extract the exec times of each txt file in the subfolders and append them to a file
      # the values are cut of nanoseconds and are divided by 1000 to get the time in seconds
      tail -n1 "$input_dir/$dir"/*.txt | sed -n 's/.*Time: \([0-9]*\).*/\1/p' | awk '{print $1/1000}' | paste -s -d, >> "$csv_file"
    fi
  done
}

# arithmetic mean
function arithmetic_mean {
  local line_input=$1
  local output_csv=$2
  # calculate the arithmetic mean for each row value
  arithmetic_mean=$(echo "$line_input" | awk -F ',' '{sum=0; for(i=1; i<=NF; i++) sum+=$i; printf "%.3f", sum/NF}')
  # append the result to the same line in output csv file
  echo -n "$arithmetic_mean" >> "$output_csv"
}

# geometric mean
function geometric_mean {
  local line_input=$1
  local output_csv=$2
  # calculate the geometric mean (the nth root of the product over n number) for each row value
  geometric_mean=$(echo "$line_input" | awk -F ',' '{product=1; for(i=1; i<=NF; i++) product*=$i; printf "%.3f", product^(1/NF)}')
  # append the result to a new csv file
  echo "$geometric_mean" >> "$output_csv"
}

# caclulate mean of columns
function mean_of_columns {
  local input_csv=$1
  local output_csv=$2
  # calculate mean values of each column in a csv file and append them to a new comma-separated csv file
  awk -F ',' 'NR>1 {for(i=1; i<=NF; i++) sum[i]+=$i; count++} END {for(i=1; i<=NF; i++) printf "%.3f,", sum[i]/count; printf "\n"}' "$input_csv" >> "$output_csv"
}

# calculate performance metrics
function calc_metrics {
  # read all comma seperated values from a csv file, then calculate the arithmetic and geometric mean for each row value
  local input_csv=$1
  local output_csv=$2
  # read each row of the input csv file except the header
  while IFS= read -r line; do
    # calculate the arithmetic mean, append to csv file
    arithmetic_mean "$line" "$output_csv"
    # append a comma to the same line in output csv file
    echo -n "," >> "$output_csv"
    # calculate the arithmetic mean, append to csv file
    geometric_mean "$line" "$output_csv"
  done < <(tail -n +2 "$input_csv")
}

# Use input_dir as parameter that has subfolders with .txt files to extract all row counts detected by buzzword row of tail
# ! Important to sort the output by the folder name, otherwise 10 will be before 2
function extract_row_cnts {
  local input_dir=$1
  local csv_file=$2
  for dir in $(find "$input_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V); 
  do
    dir_name=$(basename "$dir")
    echo -n "$dir_name" >> "$csv_file"
    if [[ -d "$input_dir/$dir" ]]; then
      for file in "$input_dir/$dir"/*.txt; do
        row_cnt=$(tail -n4 "$file" | grep "row")
        if [[ -n "$row_cnt" ]]; then
          echo -n ","
          echo -n "$row_cnt" | sed -n 's/.*(\([0-9]*\) .*/\1/p'
        else
          echo -n ",--"
        fi
      done | paste -s >> "$csv_file"
    fi
  done
}
### FUNCTION DEFINITIONS START ###


### EXTRACT AND CALCULATE BENCHMARK METRICS START ###
# exectimes.csv, exectimes-mean.csv headers
queries_header="q1,q2,q3a,q3b,q3c,q4,q5a,q5b,q6,q7,q8,q9,q10,q11,q12a,q12b,q12c"
# performance.csv, performance-mean.csv headers
performance_header="arithmetic_mean,geometric_mean"
# rowcounts.csv header
rowcount_header="iteration,q1,q2,q3a,q3b,q3c,q4,q5a,q5b,q6,q7,q8,q9,q10,q11,q12a,q12b,q12c"

# call execution times extraction for each query
echo "$queries_header" > "$exectimes_csv"
extract_execution_times "$responses_dir" "$exectimes_csv"

# call performance metrics calculation for each query
echo "$performance_header" > "$performance_csv"
calc_metrics "$exectimes_csv" "$performance_csv"

# if iterations greater than one, calculate the mean of columns
if [[ "$iterations" -gt 1 ]]; then
  # call mean_of_columns for each query in exectimes.csv
  echo "$queries_header" > "$exectimes_mean_csv"
  mean_of_columns "$exectimes_csv" "$exectimes_mean_csv"
  # call mean_of_columns for performance metrics in performance.csv
  echo "$performance_header" > "$performance_mean_csv"
  mean_of_columns "$performance_csv" "$performance_mean_csv"
fi

# provide all row counts for each query and iteration
echo "$rowcount_header" > "$rowcount_csv"
extract_row_cnts "$responses_dir" "$rowcount_csv"
### EXTRACT AND CALCULATE BENCHMARK METRICS END ###

