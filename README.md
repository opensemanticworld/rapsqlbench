# RDF2RAPSQL

- [RDF2RAPSQL](#rdf2rapsql)
  - [Measurement Monitoring](#measurement-monitoring)

## Measurement Monitoring

```bash
watch -c "printf '\033[1;31m'; df -h | awk 'NR==1 || NR==4'; echo; printf '\033[1;33m'; free -h; echo; printf '\033[1;34m'; du -h data; echo; printf '\033[1;36m'; tree -f -sh -L 2 data/sp1000000 --dirsfirst; echo; printf '\033[1;32m'; vmstat -a -t -S M; printf '\033[0m'"
```

```bash
htop
```

Setup

| Short |        Graph |                         Bash Script |                          SQL Drop Graph |
| ----: | -----------: | ----------------------------------: | --------------------------------------: |
|    1k |       sp1000 |       time ./measurement.sh -t 1000 |       select drop_graph('sp1000',true); |
|    1m |    sp1000000 |    time ./measurement.sh -t 1000000 |    select drop_graph('sp1000000',true); |
|   10m |   sp10000000 |   time ./measurement.sh -t 10000000 |   select drop_graph('sp10000000',true); |
|  125m |  sp125000000 |  time ./measurement.sh -t 125000000 |  select drop_graph('sp125000000',true); |
|  250m |  sp250000000 |  time ./measurement.sh -t 250000000 |  select drop_graph('sp250000000',true); |
|  500m |  sp500000000 |  time ./measurement.sh -t 500000000 |  select drop_graph('sp500000000',true); |
|   1bn | sp1000000000 | time ./measurement.sh -t 1000000000 | select drop_graph('sp1000000000',true); |
