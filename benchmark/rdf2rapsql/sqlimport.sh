#!/bin/bash

sql_dir=$1
measurement_file=$2

# Get the list of .sql files in the folder
sql_files=$(find "$sql_dir" -name "*.sql")

# Loop through each .sql file and execute it in the background
for file in $sql_files; do
   # Execute all .sql files in the background
  psql -q -U postgres -d rapsql -f "$file" >> "$measurement_file" &
  # psql -q -U postgres -d rapsql -f "$file" >> "$measurement_file" || exit 1
done

# While loop sql_files parallel execution
# while IFS= read -r line; do
#   # Execution for each line in parallel
#   {
#     # Place your command or script here
#     echo "Processing $line"
#     psql -q -U postgres -d rapsql -f "$line" >> "$measurement_file" || exit 1
#   } &
# done < "$sql_files"


# Wait for all background processes to finish
wait
