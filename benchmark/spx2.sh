#!/bin/bash
# Author:   Andreas Raeder
# License:  Apache License 2.0
# Usage:    /bin/bash <PATH_TO_rapsqlbench.sh" <POSITIVE_INTEGER>

# Positive input integer to set the number of triples
input=$1

# Function to check if a value is a positive integer
is_positive_integer() {
  if [[ $1 =~ ^[1-9][0-9]*$ ]]; then
    return 0
  else
    return 1
  fi
}

# Check if input exists
if [[ -z "$input" ]]; then
  echo "Error: No input provided. Please provide a positive integer." >&2
  exit 1
else 
  # Check if input is a positive integer
  if is_positive_integer "$input"; then
    triples=$input
  else
    echo "Error: Invalid input. Please provide a positive integer." >&2
    exit 1
  fi
fi

# Function to get the current timestamp
get_ts() {
  # TS nanosecond precision 6 and UTC two digits similar to ISO 8601 and PostgreSQL
  ts=$(date +"%Y-%m-%d %H:%M:%S.%6N%:::z")
  echo "$ts"
}

# Helper function to attach content to measurement file
echo_tee() {
  echo "$1" | tee -a "$measurement_file"
}

################ ENV SETUP ################
# Provide realpath, basedir and set as cwd
real_path=$(realpath "$0")
basedir=$(dirname "$real_path")
cd "$basedir" || exit 0
cwd=$(pwd)
###########################################

### MEASUREMENT START ###
# Create project dirs
tgt_name=sp"$triples"
data_dir=$cwd/data/"$tgt_name"
measurement_dir=$cwd/measurement/"$tgt_name"
measurement_file="$measurement_dir"/measurement.csv
# Create data and measurement dirs by triples
mkdir -p "$cwd"/{data,measurement}/"$tgt_name"

# # Create measurement json from schema
# schema_json="$basedir"/schema.json
# measurement_json="$measurement_dir"/measurement.json
# jsonpointer=$(jq -r '.["measurement.json"]' "$schema_json")

# echo "$jsonpointer"

# Create measurement csv
echo "Process, Parameter, Value" | tee "$measurement_file"
echo_tee "MEASUREMENT, START, $(get_ts)" 
echo_tee "MEASUREMENT, SCRIPT, $real_path"
echo_tee "MEASUREMENT, BASEDIR, $basedir"
echo_tee "MEASUREMENT, CWD, $cwd"
echo_tee "MEASUREMENT, INPUT, $triples" 
echo_tee "MEASUREMENT, PID, $$" 



### SP2B START ###
# Generate "-t X" rdf triples 
# Output: spX.n3
sp2b=$cwd/sp2b/bin
sp2b_txt=$cwd/measurement/"$tgt_name"/sp2b.txt
echo_tee "SP2B, START, $(get_ts)"
echo_tee "SP2B, DIR, $sp2b"

# Change to sp2b dir
cd "$sp2b" || exit
# Run sp2b
./sp2b_gen -t "$triples" > "$sp2b_txt" || exit 1
# Change back to cwd
cd "$cwd" || exit
# Move sp2b data to data dir
mv "$sp2b"/sp2b.n3 "$data_dir"/"$tgt_name".n3
# Read real triple count and file size from sp2b.txt tail
sp2b_triples=$(grep -o 'total triples=[0-9]*$' "$sp2b_txt" | tail -n 1 | cut -d '=' -f 2)
sp2b_filesize=$(grep -o 'total file size=[0-9]*KB$' "$sp2b_txt"| tail -n 1 | cut -d '=' -f 2)
# Output sp2b results
echo_tee "SP2B, TRIPLES, $sp2b_triples"
echo_tee "SP2B, FILESIZE, $sp2b_filesize"
echo_tee "SP2B, END, $(get_ts)"
### SP2B END ###


### RDF2RAPSQL START ###
# Input: spX.n3
# Target: rapsql database
echo_tee "RDF2RAPSQL, START, $(get_ts)"
# Run rdf2rapsql
rdf2rapsql=$(realpath "$cwd/rdf2rapsql/rdf2rapsql2.sh")
"$rdf2rapsql" -t "$triples" | tee -a "$measurement_file" || exit 1
echo_tee "RDF2RAPSQL, END, $(get_ts)"

### RDF2RAPSQL END ###


### RAPSQL_SPARQL START ###
# Input: X.sparql
# Target: rapsql database
# !TODO

### RAPSQL_SPARQL END ###

### MEASUREMENT END ###
echo_tee "MEASUREMENT, END, $(get_ts)"
