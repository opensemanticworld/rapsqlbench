#!/bin/bash

# TODO: grammer check for graphname

# Function to check if graphname matches the pattern
match_graphname_pattern() {
  local graphname=$1
  local pattern="^[^0-9\W]\w*$"
  if ! [[ $graphname =~ $pattern ]]; then
    echo "ERROR: $graphname contains special characters or begins with digits."
    exit 1
  fi
}
  # # Grammer graph name (experimental)
  # # 1 names beginning with pg_ or ag_ are reserved for system schemas
  # # 2 no white spaces
  # # 3 no special characters
  # # 4 follow lexical rules of postgresql and apache age
  # if [[ "$graph_name" =~ ^pg_.* ]]; then
  #   echo "Graph name must not begin with pg_"
  #   exit 1
  # elif [[ "$graph_name" =~ ^ag_.* ]]; then
  #   echo "Graph name must not begin with ag_"
  #   exit 1
  # elif [[ "$graph_name" =~ [[:space:]] ]]; then
  #   echo "Graph name must not contain white spaces"
  #   exit 1
  # elif [[ "$graph_name" =~ [^a-zA-Z0-9_] ]]; then
  #   echo "Graph name must not contain special characters"
  #   exit 1
  # else
  #   echo "YPG2RAPSQL, GRAPH, $graph_name"
  # fi


# Function to check if rdf2pg model option is valid
match_model_option() {
  local model=$1
  if ! [[ $model =~ ^(yars|rdfid)$ ]]; then
    echo "ERROR: Invalid model arg, must be either yars or rdfid."
    exit 1
  fi
}

# Function to check if rapsqltranspiler option is valid 
match_transpiler_option() {
  local transpiler=$1
  if ! [[ $transpiler =~ ^(plain|cpo1|cpo2|cpo3|mano)$ ]]; then
    echo "ERROR: Invalid transpiler arg, must be either Xplain, Xcpo1, Xcpo2, Xcpo3, Xmano with X = y or r."
    exit 1
  fi
}

# Function to check if a value is a positive integer
is_positive_integer() {
  local input=$1
  local arg=$2
  if ! [[ $input =~ ^[1-9][0-9]*$ ]]; then
    echo "ERROR: Invalid argument for -$arg $input. Please provide a positive integer."
    exit 1
  fi
}

# Function to check if the requested cores resources are available
check_core_resources() {
  local cores=$1
  available_cores=$(grep -c ^processor /proc/cpuinfo)
  if ! [[ $cores -le $available_cores ]]; then
    echo "ERROR: Invalid cores arg, $available_cores available in total."
    exit 1
  fi
}

# Function to check if the requested memory resources are available
check_memory_resources() {
  local mem=$1
  available_memory=$(grep MemAvailable /proc/meminfo | awk '{print int($2/1024)}')
  if ! [[ $mem -le $available_memory ]]; then
    echo "ERROR: Invalid memory arg, $available_memory MB available in total."
    exit 1
  fi
}

# Parse command line arguments
while getopts ":g:l:r:t:m:c:i:" opt; do
  case $opt in
    g)
      if match_graphname_pattern "$OPTARG"; then
        graphname=$OPTARG
      fi
      ;;
    l)
      if match_model_option "$OPTARG"; then
        model=$OPTARG
      fi
      ;;
    r)
      if match_transpiler_option "$OPTARG"; then
        transpiler=$OPTARG
      fi
      ;;
    t)
      if is_positive_integer "$OPTARG" "$opt"; then
        triples=$OPTARG
      fi
      ;;
    m)
      if is_positive_integer "$OPTARG" "$opt"; then
        mem=$OPTARG
      fi
      ;;
    c)
      if is_positive_integer "$OPTARG" "$opt"; then
        cores=$OPTARG
      fi
      ;;
    i)
      if is_positive_integer "$OPTARG" "$opt"; then
        iterations=$OPTARG
      fi
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Check if -g is set, otherwise set default to sp2b
if [[ -z "$graphname" ]]; then
  echo "No graph name provided. Using default graph name sp2b." 
  graphname="sp2b"
fi


# Check if -t is set, otherwise set default to 100
if [[ -z "$triples" ]]; then
  echo "No -t triples input provided. Using default triples 100."
  triples=100
fi

# Check if -m is set, otherwise set default to 1000
if [[ -z "$mem" ]]; then
  echo "No -m memory input provided. Using default memory 1000 MB."
  mem=1000
fi

# Check if -c is set, otherwise set default to 1
if [[ -z "$cores" ]]; then
  echo "No -c cores input provided. Using default core 1."
  cores=1
fi

# Warn if input triple is greater than 1 billion and ask to proceed
if [[ $triples -gt 1000000000 ]]; then
  read -r -p "WARNING: The input triple number is greater than 1 billion, this execution will write a huge amount of data. Do you want to proceed? [y/N] " response
  if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    echo "Proceeding..."
  else
    echo "Aborting..."
    exit 0
  fi
fi

# Check if requested cores resources are available
check_core_resources "$cores"

# Check if requested memory resources are available
check_memory_resources "$mem"

##########################################################
# PERFORM BENCHMARK
real_path=$(realpath "$0")
basedir=$(dirname "$real_path")
spx_sh=$basedir/spx.sh
"$spx_sh" "$graphname" "$model" "$transpiler" "$triples" "$mem" "$cores" "$iterations" || exit 1


##########################################################
# TEST OF ARGUMENTS
# echo "graphname: $graphname"
# echo "model: $model"
# echo "transpiler: $transpiler"
# echo "triples: $triples"
# echo "mem: $mem"
# echo "cores: $cores"
# echo "iterations: $iterations"

# Valid test commands
# ./rapsqlbench.sh -g sp2b -l yars -r plain -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l yars -r cpo1 -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l yars -r cpo2 -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l yars -r cpo3 -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l yars -r mano -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l rdfid -r plain -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l rdfid -r cpo1 -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l rdfid -r cpo2 -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l rdfid -r cpo3 -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l rdfid -r mano -t 100 -m 1000 -c 1 -i 1


# Invalid test commands
# ./rapsqlbench.sh -g sp2b -l yars -r rplain -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l yarss -r plain -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l yars -r rplains -t 100 -m 1000 -c 1 -i 1
# ./rapsqlbench.sh -g sp2b -l srdfid -r cpo3 -t 100 -m 1000 -c 1 -i 1
