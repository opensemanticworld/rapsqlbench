#!/bin/bash

graph_name=$1

# v1: Comma seperated
q7="-- cypher/j10-q7.sql !MANUALLY CREATED (v1: yars, Comma seperated)

-- age config
LOAD 'age';
SET search_path TO ag_catalog;
\timing

SELECT title FROM ag_catalog.cypher('$graph_name', \$\$
MATCH (class)-[{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (doc)-[{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class), (doc)-[{iri:'http://purl.org/dc/elements/1.1/title'}]->(title), (bag2)-[member2]->(doc), (doc2)-[{iri:'http://purl.org/dc/terms/references'}]->(bag2)
RETURN DISTINCT coalesce(title.iri, title.bnid, title.value), coalesce(doc.iri, doc.bnid, doc.value) \$\$) 
AS (title ag_catalog.agtype, doc ag_catalog.agtype) 
WHERE NOT EXISTS (
  SELECT doc_1 FROM ag_catalog.cypher('$graph_name', \$\$
  MATCH (class)-[{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (doc)-[{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class), (doc)-[{iri:'http://purl.org/dc/elements/1.1/title'}]->(title), (bag2)-[member2]->(doc), (doc2)-[{iri:'http://purl.org/dc/terms/references'}]->(bag2), (class3)-[{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (doc3)-[{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class3), (doc3)-[{iri:'http://purl.org/dc/terms/references'}]->(bag3), (bag3)-[member3]->(doc)
  RETURN DISTINCT coalesce(doc.iri, doc.bnid, doc.value), coalesce(doc3.iri, doc3.bnid, doc3.value) \$\$) 
  AS (doc_1 ag_catalog.agtype, doc3_1 ag_catalog.agtype)
  WHERE doc = doc_1 AND NOT EXISTS (
    SELECT doc_2 FROM ag_catalog.cypher('$graph_name', \$\$
    MATCH (class)-[{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (doc)-[{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class), (doc)-[{iri:'http://purl.org/dc/elements/1.1/title'}]->(title), (bag2)-[member2]->(doc), (doc2)-[{iri:'http://purl.org/dc/terms/references'}]->(bag2), (class3)-[{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (doc3)-[{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class3), (doc3)-[{iri:'http://purl.org/dc/terms/references'}]->(bag3), (bag3)-[member3]->(doc), (class4)-[{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (doc4)-[{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class4), (doc4)-[{iri:'http://purl.org/dc/terms/references'}]->(bag4), (bag4)-[member4]->(doc3)
    RETURN DISTINCT coalesce(doc3.iri, doc3.bnid, doc3.value), coalesce(doc4.iri, doc4.bnid, doc4.value) \$\$) 
    AS (doc_2 ag_catalog.agtype, doc4 ag_catalog.agtype)
    WHERE doc3_1 = doc_2 
  )
);"

echo "$q7"
