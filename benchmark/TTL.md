# TTL Script

```bash
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/ttl.sh 1 /mnt/rapsqlbench/benchmark/resources/ttl-sparql/w3c_test1/rdf.ttl
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/ttl.sh 2 /mnt/rapsqlbench/benchmark/resources/ttl-sparql/w3c_test2/rdf.ttl
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/ttl.sh 3 /mnt/rapsqlbench/benchmark/resources/ttl-sparql/w3c_test3/rdf.ttl
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/ttl.sh 4 /mnt/rapsqlbench/benchmark/resources/ttl-sparql/w3c_test4/rdf.ttl
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/ttl.sh 5 /mnt/rapsqlbench/benchmark/resources/ttl-sparql/w3c_test5/rdf.ttl
```

```sql
select * from cypher('sp1', $$ MATCH (n) RETURN n $$) AS (n agtype);
rapsql=# select * from cypher('sp1', $$ MATCH (a)-[e]->(b) RETURN e $$) AS (e agtype);

select * from cypher('sp2', $$ MATCH (n) RETURN n $$) AS (n agtype);
rapsql=# select * from cypher('sp2', $$ MATCH (a)-[e]->(b) RETURN e $$) AS (e agtype);

select * from cypher('sp3', $$ MATCH (n) RETURN n $$) AS (n agtype);
rapsql=# select * from cypher('sp3', $$ MATCH (a)-[e]->(b) RETURN e $$) AS (e agtype);

select * from cypher('sp4', $$ MATCH (n) RETURN n $$) AS (n agtype);
rapsql=# select * from cypher('sp4', $$ MATCH (a)-[e]->(b) RETURN e $$) AS (e agtype);

select * from cypher('sp5', $$ MATCH (n) RETURN n $$) AS (n agtype);
rapsql=# select * from cypher('sp5', $$ MATCH (a)-[e]->(b) RETURN e $$) AS (e agtype);
```

```sql
select drop_graph('sp1',true);
select drop_graph('sp2',true);
select drop_graph('sp3',true);
select drop_graph('sp4',true);
select drop_graph('sp5',true);
```
