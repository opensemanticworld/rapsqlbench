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

graph_name=$1

q6="-- cypher/i9-q6.sql !MANUALLY CREATED (v1: rdfid, OPTIONAL MATCH)

-- age config
LOAD 'age';
SET search_path TO ag_catalog;
\timing

SELECT yr, name, document FROM ag_catalog.cypher('$graph_name', \$\$
MATCH (class)-[:subClassOf {rdfid:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({rdfid:'http://xmlns.com/foaf/0.1/Document'}), (document)-[:type {rdfid:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class), (document)-[:issued {rdfid:'http://purl.org/dc/terms/issued'}]->(yr), (document)-[:creator {rdfid:'http://purl.org/dc/elements/1.1/creator'}]->(author), (author)-[:name {rdfid:'http://xmlns.com/foaf/0.1/name'}]->(name) 
OPTIONAL MATCH (class2)-[:subClassOf {rdfid:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({rdfid:'http://xmlns.com/foaf/0.1/Document'}), (document2)-[:type {rdfid:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class2), (document2)-[:issued {rdfid:'http://purl.org/dc/terms/issued'}]->(yr2), (document2)-[:creator {rdfid:'http://purl.org/dc/elements/1.1/creator'}]->(author2)
WHERE author.rdfid = author2.rdfid AND yr2.rdfid < yr.rdfid 
RETURN yr.rdfid, name.rdfid, document.rdfid, author2.rdfid \$\$)
AS (yr ag_catalog.agtype, name ag_catalog.agtype, document ag_catalog.agtype, author2 ag_catalog.agtype)
WHERE author2 IS NULL;"

echo "$q6"
