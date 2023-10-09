#!/bin/bash

# Input parameters
graph_name="$1"
resource_file="$2"
literal_file="$3"
blanknode_file="$4"
datatypeproperty_file="$5"
objectproperty_file="$6"

# ensure file paths
if [ ! -f "$resource_file" ]; then
  echo "File not found: $resource_file"
  exit 1
fi
if [ ! -f "$literal_file" ]; then
  echo "File not found: $literal_file"
  exit 1
fi
if [ ! -f "$blanknode_file" ]; then
  echo "File not found: $blanknode_file"
  exit 1
fi
if [ ! -f "$datatypeproperty_file" ]; then
  echo "File not found: $datatypeproperty_file"
  exit 1
fi
if [ ! -f "$objectproperty_file" ]; then
  echo "File not found: $objectproperty_file"
  exit 1
fi

sql="
SELECT now() AS \"IMPORT CONFIG\";

-- age config
LOAD 'age';
SET search_path TO ag_catalog;

-- disable notices https://stackoverflow.com/a/3531274
SET client_min_messages TO WARNING;

-- create graph
SELECT create_graph('$graph_name');


-- create vlabels (vertices = nodes)
SELECT create_vlabel('$graph_name','Resource');
SELECT create_vlabel('$graph_name','Literal');
SELECT create_vlabel('$graph_name','BlankNode');


-- create elabels
SELECT create_elabel('$graph_name','DatatypeProperty');
SELECT create_elabel('$graph_name','ObjectProperty');


-- import nodes (important -> first nodes)
SELECT now() AS \"IMPORT START\";
SELECT load_labels_from_file(
  '$graph_name',
  'Resource',
  '$resource_file',
  true
);
SELECT now() AS \"IMPORT RESOURCE\";

SELECT load_labels_from_file(
  '$graph_name',
  'Literal',
  '$literal_file',
  true
);
SELECT now() AS \"IMPORT LITERAL\";

SELECT load_labels_from_file(
  '$graph_name',
  'BlankNode',
  '$blanknode_file',
  true
);
SELECT now() AS \"IMPORT BLANKNODE\";


-- import edges
SELECT load_edges_from_file(
  '$graph_name',
  'DatatypeProperty',
  '$datatypeproperty_file'
);
SELECT now() AS \"IMPORT DATATYPEPROPERTY\";

SELECT load_edges_from_file(
  '$graph_name',
  'ObjectProperty',
  '$objectproperty_file'
);
SELECT now() AS \"IMPORT OBJECTPROPERTY\";

SELECT now() AS \"IMPORT END\";
"
echo "$sql" > import.sql
# echo "$sql" > "$graph_name".sql
