#!/bin/bash

function run {
    export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac)))))
    declare -A modules=( ["sql/core"]="sql" )
    for MODULE in "${!modules[@]}"
    do
        for j in $(for i in $(find "$MODULE" -name "*Benchmark-results.txt" | sort); do find . -name $(basename $i | sed 's/-results.txt//').scala; done)
        do
            NAME=$(echo $j | sed 's/^.*scala\///g' | sed 's/\//./g' | sed 's/.scala//g')
            if [ $NAME == "org.apache.spark.sql.execution.ExternalAppendOnlyUnsafeRowArrayBenchmark" ]; then
                SPARK_GENERATE_BENCHMARK_FILES=1 build/sbt ";project sql;set javaOptions in Test += \"-Dspark.memory.debugFill=false\";${modules[$MODULE]}/test:runMain $NAME"
            else
                SPARK_GENERATE_BENCHMARK_FILES=1 build/sbt "${modules[$MODULE]}/test:runMain $NAME"
            fi
        done
    done
}

# JDK8
git clean -fdx
sudo alternatives --config java <<< '2'
sudo alternatives --config javac <<< '1'
run

# JDK11
git clean -fdx
sudo alternatives --config java <<< '1'
sudo alternatives --config javac <<< '2'
run
