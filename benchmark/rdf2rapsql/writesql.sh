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
graph_name=$1
rdf2pg_nres=$2
rdf2pg_nlit=$3
rdf2pg_nbn=$4

# Paths
raw_file_dir=$(dirname "$rdf2pg_nres")
init_sql="$raw_file_dir"/import/init.sql
rapsqltriples_sql="$raw_file_dir"/import/rapsqltriples.sql
sql_dir="$raw_file_dir"/import/nodes
nres_sql=$sql_dir/$(basename "$rdf2pg_nres" .csv).sql
nlit_sql=$sql_dir/$(basename "$rdf2pg_nlit" .csv).sql
nbn_sql=$sql_dir/$(basename "$rdf2pg_nbn" .csv).sql
mkdir -p "$sql_dir"


### FUNCTIONS TO CREATE FILE-BASED SQL STATEMENTS START ###
# Function create AGE sql basefiles
sql_create_basefile() {
  local msg="$1"
  local sql_file="$2"
  local keyword="$3"
  # Create base file
  echo "--import/$keyword.sql

-- create extension
CREATE EXTENSION IF NOT EXISTS age;

-- age config
LOAD 'age';
SET search_path TO ag_catalog;

-- disable notices https://stackoverflow.com/a/3531274
SET client_min_messages TO WARNING;

SELECT now() AS \"$msg $keyword\";
" > "$sql_file"
}

# Function AGE create graph statement
sql_create_graph() {
  local sql_file="$1"
  local graph_name="$2"
  # Create graph
  echo "SELECT create_graph('$graph_name');" >> "$sql_file"
}

# Function AGE create vlabel statement (nodes)
sql_create_vlabel() {
  local sql_file="$1"
  local graph_name="$2"
  local vlabel="$3"
  # Create vlabel
  echo "SELECT create_vlabel('$graph_name','$vlabel');" >> "$sql_file"
}

# Function AGE load labels from file statement (nodes)
sql_load_labels_from_file() {
  local sql_file="$1"
  local graph_name="$2"
  local vlabel="$3"
  local csv_path="$4"
  # Append load labels from file statement
  echo "
SELECT load_labels_from_file(
  '$graph_name',
  '$vlabel',
  '$csv_path',
  true
);

SELECT now() AS \"END DBIMPORT $vlabel\";" >> "$sql_file"
}

# Function count rapsqltriples statement
sql_cnt_rapsqltriples() {
  local sql_file="$1"
  local graph_name="$2"
  # Append count rapsqltriples statement
  echo -E "\timing

-- via indexed age labels table of edges
SELECT COUNT(*) AS table_cnt from $graph_name._ag_label_edge;

-- via cypher path
SELECT COUNT(*) AS cypher_cnt FROM cypher('$graph_name', \$\$
MATCH (nl)-[e]->(nr)
RETURN nl, e, nr \$\$)
AS (nl agtype, e agtype, nr agtype);
" >> "$sql_file"
}
### FUNCTIONS TO CREATE FILE-BASED SQL STATEMENTS END ###


### WRITE SQL FILES START ###
# Create sql files
sql_create_basefile "INIT" "$init_sql" "$graph_name"
sql_create_basefile "IMPORT" "$nres_sql" "Resource"
sql_create_basefile "IMPORT" "$nlit_sql" "Literal"
sql_create_basefile "IMPORT" "$nbn_sql" "BlankNode"
sql_create_basefile "COUNT" "$rapsqltriples_sql" "rapsqltriples"

# Append statements to sql files
sql_create_graph "$init_sql" "$graph_name"
sql_create_vlabel "$nres_sql" "$graph_name" "Resource"
sql_create_vlabel "$nlit_sql" "$graph_name" "Literal"
sql_create_vlabel "$nbn_sql" "$graph_name" "BlankNode"
sql_load_labels_from_file "$nres_sql" "$graph_name" "Resource" "$rdf2pg_nres"
sql_load_labels_from_file "$nlit_sql" "$graph_name" "Literal" "$rdf2pg_nlit"
sql_load_labels_from_file "$nbn_sql" "$graph_name" "BlankNode" "$rdf2pg_nbn"
sql_cnt_rapsqltriples "$rapsqltriples_sql" "$graph_name"
### WRITE SQL FILES END ###

