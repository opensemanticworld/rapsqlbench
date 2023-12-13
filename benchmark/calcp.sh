#!/bin/bash

# Config
cypher_dir=$1
measurement_dir=$2

responses_dir=$cypher_dir/responses
exectimes_csv=$measurement_dir/exectimes.csv
performance_csv=$measurement_dir/performance.csv

# use input_dir as parameter that has subfolders with .txt files to extract all execution times
function execution_times {
    local input_dir=$1
    local csv_file=$2
    for dir in "$input_dir"/*; do
      # extract the exec times of each txt file in the subfolders and append them to a file
      # the values are cut of nanoseconds and are divided by 1000 to get the time in seconds
      tail -n1 "$dir"/*.txt | sed -n 's/.*Time: \([0-9]*\).*/\1/p' | awk '{print $1/1000}' | paste -s -d, >> "$csv_file"
    done
}

# arithmetic mean
function arithmetic_mean {
  local line_input=$1
  local output_csv=$2
  # calculate the arithmetic mean for each row value
  arithmetic_mean=$(echo "$line_input" | awk -F ',' '{sum=0; for(i=1; i<=NF; i++) sum+=$i; print sum/NF}')
  # append the result to the same line in output csv file
  echo -n "$arithmetic_mean" >> "$output_csv"

}

# geometric mean
function geometric_mean {
  local line_input=$1
  local output_csv=$2
  # calculate the geometric mean (the nth root of the product over n number) for each row value
  geometric_mean=$(echo "$line_input" | awk -F ',' '{product=1; for(i=1; i<=NF; i++) product*=$i; print product^(1/NF)}')
  # append the result to a new csv file
  echo "$geometric_mean" >> "$output_csv"
}


# calculate performance metrics
function calc_metrics {
  # read all comma seperated values from a csv file, then calculate the arithmetic and geometric mean for each row value
  local input_csv=$1
  local output_csv=$2
  # read each row of the input csv file except the header
  while IFS= read -r line; do
    arithmetic_mean "$line" "$output_csv"
    echo -n "," >> "$output_csv"
    geometric_mean "$line" "$output_csv"
  done < <(tail -n +2 "$input_csv")
}


# exectimes.csv header
echo "q1,q2,q3a,q3b,q3c,q4,q5a,q5b,q6,q7,q8,q9,q10,q11,q12a,q12b,q12c" > "$exectimes_csv"
# call execution_times for each query
execution_times "$responses_dir" "$exectimes_csv"

# performance.csv header
echo "arithmetic_mean,geometric_mean" > "$performance_csv"
# call performance metrics for each query
calc_metrics "$exectimes_csv" "$performance_csv"

