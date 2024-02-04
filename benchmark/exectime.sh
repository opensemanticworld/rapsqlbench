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

# Input parameter
process_name=$1
start_ts=$2
end_ts=$3

# Test data
# start_ts="2023-11-30 13:52:17.250409+00"
# end_ts="2023-12-01 14:57:12.399830+00"

# Calculate postgres format timestamp differences in human readable format
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

# Provide the time difference
calc_diff "$start_ts" "$end_ts"

