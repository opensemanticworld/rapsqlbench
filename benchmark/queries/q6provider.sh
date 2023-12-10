#!/bin/bash

graph_name=$1

q6="-- cypher/i9-q6.sql !MANUALLY CREATED

-- age config
LOAD 'age';
SET search_path TO ag_catalog;

SELECT yr, name, document FROM ag_catalog.cypher('$graph_name', \$\$
MATCH (class)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
MATCH (yr)<-[:issued {iri:'http://purl.org/dc/terms/issued'}]-(document)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class)
MATCH (document)-[:creator {iri:'http://purl.org/dc/elements/1.1/creator'}]->(author)
MATCH (author)-[:name {iri:'http://xmlns.com/foaf/0.1/name'}]->(name) 
OPTIONAL MATCH (class2)-[:subClassOf {iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (yr2)<-[:issued {iri:'http://purl.org/dc/terms/issued'}]-(document2)-[:type {iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class2), (document2)-[:creator {iri:'http://purl.org/dc/elements/1.1/creator'}]->(author2) 
WHERE (coalesce(author.iri, author.bnid, author.value) = coalesce(author2.iri, author2.bnid, author2.value)) AND (coalesce(yr2.iri, yr2.bnid, yr2.value) < coalesce(yr.iri, yr.bnid, yr.value)) 
RETURN coalesce(yr.iri, yr.bnid, yr.value), coalesce(name.iri, name.bnid, name.value), coalesce(document.iri, document.bnid, document.value), coalesce(author2.iri, author2.bnid, author2.value) \$\$) 
AS (yr ag_catalog.agtype, name ag_catalog.agtype, document ag_catalog.agtype, author2 ag_catalog.agtype)
WHERE author2 IS NULL;"

echo "$q6"

# q6="

# SELECT yr, name, document FROM ag_catalog.cypher('$graph_name', \$\$
# MATCH (class)-[:subClassOf{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'})
# MATCH (document)-[:type{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class)
# MATCH (document)-[:issued{iri:'http://purl.org/dc/terms/issued'}]->(yr)
# MATCH (document)-[:creator{iri:'http://purl.org/dc/elements/1.1/creator'}]->(author)
# MATCH (author)-[:name{iri:'http://xmlns.com/foaf/0.1/name'}]->(name) 
# OPTIONAL MATCH (class2)-[:subClassOf{iri:'http://www.w3.org/2000/01/rdf-schema#subClassOf'}]->({iri:'http://xmlns.com/foaf/0.1/Document'}), (document2)-[:type{iri:'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'}]->(class2), (document2)-[:issued{iri:'http://purl.org/dc/terms/issued'}]->(yr2), (document2)-[:creator{iri:'http://purl.org/dc/elements/1.1/creator'}]->(author2)
# WHERE coalesce(author.iri, author.bnid, author.value) = coalesce(author2.iri, author2.bnid, author2.value) AND coalesce(yr2.iri, yr2.bnid, yr2.value) < coalesce(yr.iri, yr.bnid, yr.value) 
# RETURN coalesce(yr.iri, yr.bnid, yr.value), coalesce(name.iri, name.bnid, name.value), coalesce(document.iri, document.bnid, document.value), coalesce(author2.iri, author2.bnid, author2.value) \$\$)
# AS (yr ag_catalog.agtype, name ag_catalog.agtype, document ag_catalog.agtype, author2 ag_catalog.agtype)
# WHERE author2 IS NULL;"


