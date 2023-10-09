# RAPSQL Benchmark

- [RAPSQL Benchmark](#rapsql-benchmark)
  - [Measurement Monitoring](#measurement-monitoring)
  - [Usage](#usage)

## Measurement Monitoring

```bash
htop
```

`Watch` some metrics, `tree` (e.g. data/sp1000000) statement and numbers of `df -h` need to be customized to your environment:

```bash
watch -c "printf '\033[1;31m'; df -h | awk 'NR==1 || NR==4'; echo; printf '\033[1;33m'; free -h; echo; printf '\033[1;34m'; du -h data; echo; printf '\033[1;36m'; tree -f -sh -L 2 data/sp1000000 --dirsfirst; echo; printf '\033[1;32m'; vmstat -a -t -S M; printf '\033[0m'"
```

System monitoring:

```bash
htop
```

## Usage

1. Use additional `time` statement right before `docker exec` to measure the execution time of the benchmark using system function.
2. Use additional `tee` statement right after `docker exec` to save the output of the benchmark to a file.

| Short |        Graph |                                                              Bash Script |                          SQL Drop Graph |
| ----: | -----------: | -----------------------------------------------------------------------: | --------------------------------------: |
|    1k |       sp1000 |       docker exec rapsqldb-container mnt/rapsqlbench/rapsqlbench.sh 1000 |       select drop_graph('sp1000',true); |
|    1m |    sp1000000 |    docker exec rapsqldb-container mnt/rapsqlbench/rapsqlbench.sh 1000000 |    select drop_graph('sp1000000',true); |
|  125m |  sp125000000 |  docker exec rapsqldb-container mnt/rapsqlbench/rapsqlbench.sh 125000000 |  select drop_graph('sp125000000',true); |
|  250m |  sp250000000 |  docker exec rapsqldb-container mnt/rapsqlbench/rapsqlbench.sh 250000000 |  select drop_graph('sp250000000',true); |
|  500m |  sp500000000 |  docker exec rapsqldb-container mnt/rapsqlbench/rapsqlbench.sh 500000000 |  select drop_graph('sp500000000',true); |
|   1bn | sp1000000000 | docker exec rapsqldb-container mnt/rapsqlbench/rapsqlbench.sh 1000000000 | select drop_graph('sp1000000000',true); |
```bash
