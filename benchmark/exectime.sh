#!/bin/bash

# Input parameter
process_name=$1
start_ts=$2
end_ts=$3

# Test data
# process_name="RDF2RAPSQL"
# start_ts="2023-11-30 13:52:17.250409+00"
# end_ts="2023-12-01 14:57:12.399830+00"

# Calculate the timestamp differences in human readable format
# Input: start_ts, end_ts
# Output: process info + time difference in days:hours:minutes:seconds.milliseconds
calc_diff() {
  local start_ts="$1"
  local end_ts="$2"
  start_ts_epoch=$(date -d "$start_ts" +%s%N)
  end_ts_epoch=$(date -d "$end_ts" +%s%N)
  diff=$((end_ts_epoch-start_ts_epoch))
  days=$((diff/86400000000000))
  hours=$((diff/3600000000000%24))
  minutes=$((diff/60000000000%60))
  seconds=$((diff/1000000000%60))
  milliseconds=$((diff/1000000%1000))
  echo "$process_name, EXECTIME, d:h:m:s.ms | $days:$hours:$minutes:$seconds.$milliseconds"
}

# calc_diff() {
#   local start_ts="$1"
#   local end_ts="$2"
#   start_ts_epoch=$(date -d "$start_ts" +%s)
#   end_ts_epoch=$(date -d "$end_ts" +%s)
#   diff=$((end_ts_epoch-start_ts_epoch))
#   days=$((diff/86400))
#   hours=$((diff/3600%24))
#   minutes=$((diff/60%60))
#   seconds=$((diff%60))
#   echo "$process_name, EXECTIME, $days:$hours:$minutes:$seconds | d:h:m:s"
# }


# Calculate the timestamp differences in seconds
calc_diff "$start_ts" "$end_ts"

# calc_diff_seconds() {
#   local start_ts="$1"
#   local end_ts="$2"
#   local start_ts_epoch=$(date -d "$start_ts" +%s)
#   local end_ts_epoch=$(date -d "$end_ts" +%s)
#   local diff=$((end_ts_epoch-start_ts_epoch))
#   echo "$diff"
# }

# # Calculate the timestamp differences in seconds
# calc_diff_seconds "$start_ts" "$end_ts"