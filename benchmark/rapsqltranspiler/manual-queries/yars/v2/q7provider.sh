#!/bin/bash

graph_name=$1

q7="-- cypher/j10-q7.sql !MANUALLY CREATED (v2: yars, multiple MATCH)

-- age config
LOAD 'age';
SET search_path TO ag_catalog;
\timing

SELECT title FROM ag_catalog.cypher('$graph_name', \$\$
MATCH (class)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
MATCH (title)<-[:title {iri:'http://purl.org/dc/elements/1.1/title'}]-(doc)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class)
MATCH (bag2)-[member2]->(doc)
MATCH (doc2)-[:references {iri:'http://purl.org/dc/terms/references'}]->(bag2) 
RETURN DISTINCT coalesce(title.iri, title.bnid, title.value), coalesce(doc.iri, doc.bnid, doc.value) \$\$) 
AS (title ag_catalog.agtype, doc ag_catalog.agtype) 
WHERE NOT EXISTS (
  SELECT doc_1 FROM ag_catalog.cypher('$graph_name', \$\$
  MATCH (class)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
  MATCH (title)<-[:title {iri:'http://purl.org/dc/elements/1.1/title'}]-(doc)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class)
  MATCH (bag2)-[member2]->(doc)
  MATCH (doc2)-[:references {iri:'http://purl.org/dc/terms/references'}]->(bag2)
  MATCH (class3)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
  MATCH (bag3)<-[:references {iri:'http://purl.org/dc/terms/references'}]-(doc3)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class3)
  MATCH (bag3)-[member3]->(doc) 
  RETURN DISTINCT coalesce(doc.iri, doc.bnid, doc.value), coalesce(doc3.iri, doc3.bnid, doc3.value) \$\$) 
  AS (doc_1 ag_catalog.agtype, doc3_1 ag_catalog.agtype)
  WHERE doc = doc_1 AND NOT EXISTS (
    SELECT doc3_2 FROM ag_catalog.cypher('$graph_name', \$\$
    MATCH (class)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
    MATCH (title)<-[:title {iri:'http://purl.org/dc/elements/1.1/title'}]-(doc)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class)
    MATCH (bag2)-[member2]->(doc)
    MATCH (doc2)-[:references {iri:'http://purl.org/dc/terms/references'}]->(bag2)
    MATCH (class3)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
    MATCH (bag3)<-[:references {iri:'http://purl.org/dc/terms/references'}]-(doc3)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class3)
    MATCH (bag3)-[member3]->(doc)
    MATCH (class4)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
    MATCH (bag4)<-[:references {iri:'http://purl.org/dc/terms/references'}]-(doc4_2)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class4)
    MATCH (bag4)-[member4]->(doc3) 
    RETURN DISTINCT coalesce(doc3.iri, doc3.bnid, doc3.value), coalesce(doc4_2.iri, doc4_2.bnid, doc4_2.value) \$\$) 
    AS (doc3_2 ag_catalog.agtype, doc4_2 ag_catalog.agtype)
    WHERE doc3_1 = doc3_2 
  )
);"

echo "$q7"
