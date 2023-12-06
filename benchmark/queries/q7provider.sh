#!/bin/bash

graph_name=$1

q7="SELECT title FROM ag_catalog.cypher('$graph_name', \$\$
MATCH (class)-[:subClassOf{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (doc)-[:type{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class), (doc)-[{iri:'http://purl.org/dc/elements/1.1/title'}]->(title), (bag2)-[member2]->(doc), (doc2)-[{iri:'http://purl.org/dc/terms/references'}]->(bag2)
RETURN DISTINCT coalesce(title.iri, title.bnid, title.value) \$\$) 
AS (title ag_catalog.agtype)
WHERE NOT EXISTS (
  SELECT title_2 FROM ag_catalog.cypher('$graph_name', \$\$
  MATCH (class)-[:subClassOf{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (doc)-[:type{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class), (doc)-[{iri:'http://purl.org/dc/elements/1.1/title'}]->(title), (bag2)-[member2]->(doc), (doc2)-[{iri:'http://purl.org/dc/terms/references'}]->(bag2)
  OPTIONAL MATCH (class3)-[:subClassOf{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (doc3)-[:type{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class3), (doc3)-[{iri:'http://purl.org/dc/terms/references'}]->(bag3), (bag3)-[member3]->(doc)
  OPTIONAL MATCH (class4)-[:subClassOf{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (doc4)-[:type{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class4), (doc4)-[{iri:'http://purl.org/dc/terms/references'}]->(bag4), (bag4)-[member4]->(doc3)
  RETURN DISTINCT coalesce(doc4.iri, doc4.bnid, doc4.value), coalesce(title.iri, title.bnid, title.value) \$\$) 
  AS (doc4_2 ag_catalog.agtype, title_2 ag_catalog.agtype)
  WHERE doc4_2 IS NULL AND title = title_2
);"

echo "$q7"
