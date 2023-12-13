#!/bin/bash

# Config
cypher_dir=$1
measurement_dir=$2

responses_dir=$cypher_dir/responses
exectimes_csv=$measurement_dir/exectimes.csv
performance_csv=$measurement_dir/performance.csv


# echo the execution time of a .txt file
# .responses (input_dir) -> subfolders:
#  - loop1/*.txt
#  - loop2/*.txt
#  - loop3/*.txt
#  - loop4/*.txt
#  - loop5/*.txt
#  - loop6/*.txt
#  - loop7/*.txt
#  - loop8/*.txt
#  - loop9/*.txt
#  - loop10/*.txt



# use input_dir as parameter that has subfolders with .txt files to extract all execution times
function execution_times {
    local input_dir=$1
    local csv_file=$2
    for dir in "$input_dir"/*; do
      # extract the exec times of each txt file in the subfolders and append them to a file
      # in an ordered way, the first .txt of each subfolder, then the second .txt of each subfolder, etc.
      # tail -n1 "$dir"/*.txt | sed -n 's/.*Time: \([0-9.]*\) ms.*/\1/p' | paste -s -d, >> "$csv_file"
      # the same but cut all values after the decimal point
      # tail -n1 "$dir"/*.txt | sed -n 's/.*Time: \([0-9]*\).*/\1/p' | paste -s -d, >> "$csv_file"
      # the same but divide by 1000 to get the time in seconds
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





# # extract value between "Time: " and " ms"
# # and save the result in a file called "execution_time.txt"
# #using tail + sed
# tail -n1 /usr/local/docker/masterthesis/rapsql/mnt/rapsqlbench/results/aws/v1/queries/sp125m/responses/loop-1/*.txt | sed -n 's/.*Time: \([0-9.]*\) ms.*/\1/p' > execution_time.txt


# # extract value between "Time: " and " ms"
# # and save the result in a file called "execution_time.txt"
# #using tail + awk
# tail -n1 /usr/local/docker/masterthesis/rapsql/mnt/rapsqlbench/results/aws/v1/queries/sp125m/responses/loop-1/*.txt | awk -F 'Time: | ms' '{print $2}' > execution_time.txt

# # the same with no empty lines
# tail -n1 /usr/local/docker/masterthesis/rapsql/mnt/rapsqlbench/results/aws/v1/queries/sp125m/responses/loop-1/*.txt | awk -F 'Time: | ms' '{print $2}' | sed '/^$/d' > execution_time.txt


# function to extract the execution time of each txt file in all subfolders
# and save the result in a file called "execution_time.txt"
# using tail + sed
# use input_dir as parameter that has subfolders with .txt files
# function execution_times {
#     local input_dir=$1
#     for dir in "$input_dir"/*; do
#       # extract the exec times of each txt file in the subfolders and append them to a file
#       # in an ordered way, the first .txt of each subfolder, then the second .txt of each subfolder, etc.
#       tail -n1 "$dir"/*.txt | sed -n 's/.*Time: \([0-9.]*\) ms.*/\1/p' >> execution_time.txt
        
#     done
# }
