# RAPSQL Benchmark

- [RAPSQL Benchmark](#rapsql-benchmark)
  - [Prerequisites](#prerequisites)
  - [System monitoring](#system-monitoring)
  - [Measurement Monitoring](#measurement-monitoring)
  - [Usage](#usage)
    - [SPX2](#spx2)
  - [Postgres](#postgres)
  - [Monitor](#monitor)

## Prerequisites

- docker
- rapsql
- rapsqlbench

## System monitoring

```bash
htop
```

## Measurement Monitoring

`Watch` some metrics, `tree` (e.g. data/sp1000000) statement and numbers of `df -h` need to be customized to your environment:

```bash
watch -c "printf '\033[1;31m'; df -h | awk 'NR==1 || NR==4'; echo; printf '\033[1;33m'; free -h; echo; printf '\033[1;34m'; du -h data; echo; printf '\033[1;36m'; tree -f -sh -L 2 data/sp1000000 --dirsfirst; echo; printf '\033[1;32m'; vmstat -a -t -S M; printf '\033[0m'"
```

## Usage

1. Use additional `time` statement right before `docker exec` to measure the execution time of the benchmark using system function.
2. Use additional `tee` statement right after `docker exec` to save the output of the benchmark to a file.

| Short |        Graph |                                                                Bash Script |                          SQL Drop Graph |
| ----: | -----------: | -------------------------------------------------------------------------: | --------------------------------------: |
|    1k |       sp1000 |       docker exec rapsqldb-container mnt/rapsqlbench/benchmark/spx.sh 1000 |       select drop_graph('sp1000',true); |
|    1m |    sp1000000 |    docker exec rapsqldb-container mnt/rapsqlbench/benchmark/spx.sh 1000000 |    select drop_graph('sp1000000',true); |
|  125m |  sp125000000 |  docker exec rapsqldb-container mnt/rapsqlbench/benchmark/spx.sh 125000000 |  select drop_graph('sp125000000',true); |
|  250m |  sp250000000 |  docker exec rapsqldb-container mnt/rapsqlbench/benchmark/spx.sh 250000000 |  select drop_graph('sp250000000',true); |
|  500m |  sp500000000 |  docker exec rapsqldb-container mnt/rapsqlbench/benchmark/spx.sh 500000000 |  select drop_graph('sp500000000',true); |
|   1bn | sp1000000000 | docker exec rapsqldb-container mnt/rapsqlbench/benchmark/spx.sh 1000000000 | select drop_graph('sp1000000000',true); |

### SPX2

Uses no RDFSP, e.g., 10k dataset:

```bash
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/spx2.sh 10000
```

```sql
select drop_graph('sp10000',true);
```

```bash
./rapsqlbench.sh -g sp125 -t 125 -m 25000 -c 8
```

```bash
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/rapsqlbench.sh -g sp1m -t 1000000 -m 25000 -c 8
```

```bash
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/rapsqlbench.sh -g sp100k -t 100000 -m 25000 -c 8
```

```bash
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/rapsqlbench.sh -g sp100 -t 100 -m 25000 -c 8
```

```bash
sudo rm -rf /usr/local/docker/masterthesis/rapsql/mnt/rapsqlbench/benchmark/data/sp*; sudo rm -rf /usr/local/docker/masterthesis/rapsql/mnt/rapsqlbench/benchmark/measurement/sp*
```

```bash
docker exec rapsqlcontainer /mnt/data/sp1m/rapsqlbench.sh -g sp1m -t 1000000 -m 250000 -c 32
```

```bash
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/rapsqlbench.sh -g sp1mnew1 -t 1000000 -m 25000 -c 8 -i 1
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/rapsqlbench.sh -g sp1mnew1 -t 1000000 -m 15000 -c 8 -i 1
docker exec rapsqldb-container mnt/rapsqlbench/benchmark/rapsqlbench.sh -g sp1m2 -t 1000000 -m 15000 -c 1 -i 1
```

## Postgres

Set `timeout` to 10 seconds:

```bash
docker exec rapsqldb-container psql -U postgres -d rapsql -c "ALTER SYSTEM SET statement_timeout = '5min';"
```

Set execution time information:

```bash
docker exec rapsqldb-container psql -U postgres -d rapsql -c "ALTER SYSTEM SET log_duration = on;"
```

Refresh the configuration:

```bash
docker exec rapsqldb-container psql -U postgres -d rapsql -c "SELECT pg_reload_conf();"
```

## Monitor

Track complete csv file:

```bash
tail -f -n +1 measurement.csv
```
