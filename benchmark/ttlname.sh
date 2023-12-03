#!/bin/bash
# Author:   Andreas Raeder
# License:  Apache License 2.0
# Usage:    /bin/bash <PATH_TO_rapsqlbench.sh" <POSITIVE_INTEGER>

# Provide graph name as first argument
graphname=$1
pattern="^[^0-9\W]\w*$"

if [[ -z "$graphname" ]]; then
  echo "Error: No graph name provided." >&2
  echo "Please provide a graph name without special characters that does not begin with digits." 
  exit 1
fi

if [[ $graphname =~ $pattern ]]; then
  echo "Input is a string without special characters and does not begin with digits."
else
  echo "Input contains special characters or begins with digits."
  exit 1
fi

# Provide rdf file as second argument
rdf=$2

if [[ -z "$rdf" ]]; then
  echo "Error: No rdf file provided." >&2
  echo "Please provide a rdf file." 
  exit 1
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
tgt_name="$graphname"
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
echo_tee "MEASUREMENT, INPUT, $graphname" 
echo_tee "MEASUREMENT, PID, $$" 


# Provide w3c text x
cp -f "$rdf" "$data_dir"/"$tgt_name".n3


### RDF2RAPSQL START ###
# Input: spX.n3
# Target: rapsql database
echo_tee "RDF2RAPSQL, START, $(get_ts)"
# Run rdf2rapsql
rdf2rapsql=$(realpath "$cwd/rdf2rapsql/rdf2rapsql2name.sh")
"$rdf2rapsql" "$graphname" | tee -a "$measurement_file" || exit 1
echo_tee "RDF2RAPSQL, END, $(get_ts)"
### RDF2RAPSQL END ###


### RAPSQL_SPARQL START ###
# Input: X.sparql
# Target: rapsql database
# !TODO

### RAPSQL_SPARQL END ###

### MEASUREMENT END ###
echo_tee "MEASUREMENT, END, $(get_ts)"
