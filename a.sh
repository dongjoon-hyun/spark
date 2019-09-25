#!/usr/local/bin/bash

declare -A modules=( ["core"]="core" ["sql/catalyst"]="catalyst" ["sql/core"]="sql" ["sql/hive"]="hive" ["external/avro"]="avro" ["mllib"]="mllib" )
for MODULE in "${!modules[@]}"
do
    for j in $(for i in $(find "$MODULE" -name "*Benchmark-results.txt" | sort); do find . -name $(basename $i | sed 's/-results.txt//').scala; done)
    do
        NAME=$(echo $j | sed 's/^.*scala\///g' | sed 's/\//./g' | sed 's/.scala//g')
        echo "SPARK_GENERATE_BENCHMARK_FILES=1 build/sbt \"${modules[$MODULE]}/test:runMain $NAME\""
    done
done
