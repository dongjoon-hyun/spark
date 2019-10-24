#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Run benchmark scripts for both JDK8/11.
# Usage:
#
#     Run a single benchmark:
#        dev/dev/benchmark.sh org.apache.spark.serializer.KryoBenchmark
#        dev/dev/benchmark.sh KryoBenchmark   # When name are unique
#
#     Run all benchmarks:
#        dev/dev/benchmark.sh

set -e

# Go to the Spark project root directory
FWDIR="$(cd "`dirname "$0"`"/..; pwd)"
cd "$FWDIR"

# By default, this will match benchmarks.
BENCHMARK_NAME=${1:-Benchmark}

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
else
    ID=mac
fi

function set_jdk8 {
    case $ID in
    centos)
        sudo alternatives --config java <<< '2'
        sudo alternatives --config javac <<< '1'
        export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac)))))
        ;;

    mac)
        export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
        ;;

    ubuntu)
        sudo update-alternatives --config java <<< '2'
        sudo update-alternatives --config javac <<< '2'
        export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac)))))
        ;;

    *)
        echo "Unknown OS"
        ;;
    esac
    echo $JAVA_HOME
    java -version
}

function set_jdk11 {
    case $ID in
    centos)
        sudo alternatives --config java <<< '1'
        sudo alternatives --config javac <<< '2'
        export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac)))))
        ;;

    mac)
        export JAVA_HOME=$(/usr/libexec/java_home -v 11)
        ;;

    ubuntu)
        sudo update-alternatives --config java <<< '2'
        sudo update-alternatives --config javac <<< '2'
        export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which javac)))))
        ;;

    *)
        echo "Unknown OS"
        ;;

    esac
    echo $JAVA_HOME
    java -version
}

function run_benchmark {
    declare -A modules=(
        ["core"]="core"
        ["mllib"]="mllib"
        ["sql/catalyst"]="catalyst"
        ["sql/core"]="sql"
        ["sql/hive"]="hive"
        ["external/avro"]="avro"
    )

    for MODULE in "${!modules[@]}"
    do
        for j in $(for i in $(find "$MODULE" -name "*Benchmark-results.txt" | sort); do find . -name $(basename $i | sed 's/-results.txt//').scala; done)
        do
            NAME=$(echo $j | sed 's/^.*scala\///g' | sed 's/\//./g' | sed 's/.scala//g')
            if [[ $NAME == *"$1"* ]]; then
                if [ $NAME == "org.apache.spark.sql.execution.ExternalAppendOnlyUnsafeRowArrayBenchmark" ]; then
                    echo SPARK_GENERATE_BENCHMARK_FILES=1 build/sbt ";project sql;set javaOptions in Test += \"-Dspark.memory.debugFill=false\";${modules[$MODULE]}/test:runMain $NAME"
                else
                    echo SPARK_GENERATE_BENCHMARK_FILES=1 build/sbt "${modules[$MODULE]}/test:runMain $NAME"
                fi
            fi
        done
    done
}

git clean -fdx
set_jdk8
run_benchmark $BENCHMARK_NAME

git clean -fdx
set_jdk11
run_benchmark $BENCHMARK_NAME
