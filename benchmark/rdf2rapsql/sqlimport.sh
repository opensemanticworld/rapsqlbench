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
sql_dir=$1
measurement_file=$2

# Get the list of *.sql files by given directory
sql_files=$(find "$sql_dir" -name "*.sql")


### IMPORT DATA INTO POSTGRES DATABASE START ###
# Loop through each .sql file and execute it in the background
for file in $sql_files; do
   # Execute all .sql files in the background
  sudo -u postgres psql -q -U postgres -d postgres -f "$file" >> "$measurement_file" &
  # psql -q -U postgres -d postgres -f "$file" >> "$measurement_file" || exit 1
done

# Wait for all background processes to finish
wait
### IMPORT DATA INTO POSTGRES DATABASE END ###


### EXPERIMENTAL START ###
# While loop sql_files parallel execution
# while IFS= read -r line; do
#   # Execution for each line in parallel
#   {
#     # Place your command or script here
#     echo "Processing $line"
#     psql -q -U postgres -d postgres -f "$line" >> "$measurement_file" || exit 1
#   } &
# done < "$sql_files"
# wait
# Wait for all background processes to finish
### EXPERIMENTAL END ###

