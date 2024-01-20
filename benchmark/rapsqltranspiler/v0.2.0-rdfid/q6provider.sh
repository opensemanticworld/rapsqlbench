#!/bin/bash

graph_name=$1

q6="-- cypher/i9-q6.sql !MANUALLY CREATED

-- age config
LOAD 'age';
SET search_path TO ag_catalog;
\timing

SELECT yr, name, document FROM ag_catalog.cypher('$graph_name', \$\$
MATCH (class)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
MATCH (document)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class)
MATCH (document)-[:issued {iri:'http://purl.org/dc/terms/issued'}]->(yr)
MATCH (document)-[:creator {iri:'http://purl.org/dc/elements/1.1/creator'}]->(author)
MATCH (author)-[:name {iri:'http://xmlns.com/foaf/0.1/name'}]->(name) 
RETURN yr.rdfid, name.rdfid, document.rdfid \$\$) 
AS (yr ag_catalog.agtype, name ag_catalog.agtype, document ag_catalog.agtype)
WHERE NOT EXISTS (
  SELECT yr_1, name_1, document_1 FROM ag_catalog.cypher('$graph_name', \$\$
  MATCH (class)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
  MATCH (document)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class)
  MATCH (document)-[:issued {iri:'http://purl.org/dc/terms/issued'}]->(yr)
  MATCH (document)-[:creator {iri:'http://purl.org/dc/elements/1.1/creator'}]->(author)
  MATCH (author)-[:name {iri:'http://xmlns.com/foaf/0.1/name'}]->(name)
  MATCH (class2)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
  MATCH (document2)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class2)
  MATCH (document2)-[:issued {iri:'http://purl.org/dc/terms/issued'}]->(yr2)
  MATCH (document2)-[:creator {iri:'http://purl.org/dc/elements/1.1/creator'}]->(author2) 
  WHERE (author.rdfid = author2.rdfid) AND (yr2.rdfid < yr.rdfid)
  RETURN yr.rdfid, name.rdfid, document.rdfid \$\$) 
  AS (yr_1 ag_catalog.agtype, name_1 ag_catalog.agtype, document_1 ag_catalog.agtype)
  WHERE yr=yr_1 AND name=name_1 AND document=document_1
);"

echo "$q6"

