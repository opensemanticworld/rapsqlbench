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

graphname=$1
model=$2
transpiler=$3
man_qv67=$4
triples=$5
memory=$6
cores=$7
iterations=$8

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
exectime_sh=$basedir/exectime.sh
cd "$basedir" || exit 0
cwd=$(pwd)

# Create project dirs
data_dir=$cwd/data/"$graphname"
measurement_dir=$cwd/measurement/"$graphname"
measurement_file="$measurement_dir"/measurement.csv
query_dir=$cwd/queries
cypher_dir=$query_dir/cypher/"$graphname"
# Create data, measurement, and cypher dirs by graphname
mkdir -p "$cwd"/{data,measurement}/"$graphname"
mkdir -p "$cypher_dir"

# Create measurement csv
measurement_start=$(get_ts)
echo "Process, Parameter, Value" | tee "$measurement_file"
###########################################

### 0 MEASUREMENT START ###
echo_tee "MEASUREMENT, START, $measurement_start" 
echo_tee "MEASUREMENT, SCRIPT, $real_path"
echo_tee "MEASUREMENT, BASEDIR, $basedir"
echo_tee "MEASUREMENT, CWD, $cwd"
echo_tee "MEASUREMENT, INPUT, $triples" 
echo_tee "MEASUREMENT, PID, $$" 


### 1 SP2B GEN START ###
# Generate -t "X" rdf triples as .n3 file
sp2b=$cwd/sp2b/bin
sp2b_txt=$cwd/measurement/"$graphname"/sp2b.txt
sp2b_start=$(get_ts)
echo_tee "SP2B, START, $sp2b_start"
echo_tee "SP2B, DIR, $sp2b"
# Change to sp2b dir
cd "$sp2b" || exit
# Run sp2b
./sp2b_gen -t "$triples" > "$sp2b_txt" || exit 1
# Change back to cwd
cd "$cwd" || exit
# Move sp2b data to data dir
mv "$sp2b"/sp2b.n3 "$data_dir"/"$graphname".n3
# Read real triple count and file size from sp2b.txt tail
sp2b_triples=$(grep -o 'total triples=[0-9]*$' "$sp2b_txt" | tail -n 1 | cut -d '=' -f 2)
sp2b_filesize=$(grep -o 'total file size=[0-9]*KB$' "$sp2b_txt"| tail -n 1 | cut -d '=' -f 2)
# Output sp2b results
sp2b_end=$(get_ts)
echo_tee "SP2B, TRIPLES, $sp2b_triples"
echo_tee "SP2B, FILESIZE, $sp2b_filesize"
echo_tee "SP2B, END, $sp2b_end"
echo_tee "$("$exectime_sh" "SP2B" "$sp2b_start" "$sp2b_end")"
### 1 SP2B GEN END ###


### 2 RDF2RAPSQL START ###
# Target: rapsql database
echo_tee "RDF2RAPSQL, RAPSQLMODEL, $model"
rdf2rapsql_start=$(get_ts)
echo_tee "RDF2RAPSQL, START, $rdf2rapsql_start"
# Run rdf2rapsql
rdf2rapsql_sh=$(realpath "$cwd/rdf2rapsql/rdf2rapsql.sh")
"$rdf2rapsql_sh" "$graphname" "$model" "$memory" "$cores" | tee -a "$measurement_file" || exit 1
rdf2rapsql_end=$(get_ts)
echo_tee "RDF2RAPSQL, END, $rdf2rapsql_end"
echo_tee "$("$exectime_sh" "RDF2RAPSQL" "$rdf2rapsql_start" "$rdf2rapsql_end")"
### 2 RDF2RAPSQL END ###


### 3 PROVIDE TRANSPILED CYPHER START ###
echo_tee "WRITECYPHER, RAPSQLTRANSPILER, $transpiler"
echo_tee "WRITECYPHER, RAPSQLMANQV67, $man_qv67"
writecypher_start=$(get_ts)
echo_tee "WRITECYPHER, START, $writecypher_start"
# Run writecypher using rapsqltranspiler
writecypher_sh=$(realpath "$cwd/rapsqltranspiler/writecypher.sh")
"$writecypher_sh" "$graphname" "$query_dir" "$model" "$transpiler" "$man_qv67" | tee -a "$measurement_file" || exit 1
writecypher_end=$(get_ts)
echo_tee "WRITECYPHER, END, $writecypher_end"
echo_tee "$("$exectime_sh" "WRITECYPHER" "$writecypher_start" "$writecypher_end")"
### 3 PROVIDE TRANSPILED CYPHER END ###


### 4 WARMUP AND IMPORT VERIFICATION START ###
# Input: rapsqltriples.sql
# Target: rapsql database
# Output: rapsqltriples.txt
rapsqltriples_sql="$data_dir"/import/rapsqltriples.sql
rapsqltriples_txt="$measurement_dir"/rapsqltriples.txt
# Wait for 5 s after rdf2rapsql
sleep 5
# Count of all processed triples from rdf2pg 
rapsqltriples_cnt_start=$(get_ts)
echo_tee "RAPSQLTRIPLES-CNT, START, $rapsqltriples_cnt_start"
sudo -u postgres psql -q -U postgres -d postgres -f "$rapsqltriples_sql" > "$rapsqltriples_txt" || exit 1
rapsqltriples_cnt_end=$(get_ts)
echo_tee "RAPSQLTRIPLES-CNT, END, $rapsqltriples_cnt_end"
echo_tee "$("$exectime_sh" "RAPSQLTRIPLES-CNT" "$rapsqltriples_cnt_start" "$rapsqltriples_cnt_end")"
### 4 WARMUP AND IMPORT VERIFICATION END ###


### 5 RUNQUERIES START ###
# Target: rapsql database
# Wait for 5 s after warmup
sleep 5
runqueries_start=$(get_ts)
echo_tee "RUNQUERIES, START, $runqueries_start"
# Perform queries
runqueries_sh=$(realpath "$basedir/runqueries.sh")
"$runqueries_sh" "$cypher_dir" "$measurement_dir" "$exectime_sh" "$iterations" true | tee -a "$measurement_file" || exit 1
runqueries_end=$(get_ts)
echo_tee "RUNQUERIES, END, $runqueries_end"
echo_tee "$("$exectime_sh" "RUNQUERIES" "$runqueries_start" "$runqueries_end")"
### 5 RUNQUERIES START ###


### 6 CALCULATE PERFORMANCE START ###
# Input: cypher_dir, measurement_dir
# Output: exectimes.csv, performance.csv
calcperformance_start=$(get_ts)
echo_tee "CALCPERFORMANCE, START, $calcperformance_start"
# Run calcperformance
calcperformance_sh=$(realpath "$basedir/calcp.sh")
"$calcperformance_sh" "$cypher_dir" "$measurement_dir" "$iterations" | tee -a "$measurement_file" || exit 1
calcperformance_end=$(get_ts)
echo_tee "CALCPERFORMANCE, END, $calcperformance_end"
echo_tee "$("$exectime_sh" "CALCPERFORMANCE" "$calcperformance_start" "$calcperformance_end")"
### 6 CALCULATE PERFORMANCE END ###


measurement_end=$(get_ts)
echo_tee "MEASUREMENT, END, $measurement_end"
echo_tee "$("$exectime_sh" "MEASUREMENT" "$measurement_start" "$measurement_end")"
### 0 MEASUREMENT END ###

