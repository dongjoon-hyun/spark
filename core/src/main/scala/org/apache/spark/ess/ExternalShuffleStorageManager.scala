/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.spark.ess

import java.io.{File, InputStream}

import org.apache.spark.{MapOutputTrackerMaster, MapOutputTrackerMasterEndpoint, SparkConf}
import org.apache.spark.network.buffer.ManagedBuffer
import org.apache.spark.rpc.{RpcEndpoint, RpcEnv}
import org.apache.spark.shuffle.ShuffleBlockResolver
import org.apache.spark.storage.{BlockId, BlockManager}

private[spark] trait ExternalShuffleStorageManager {

  def upload(
      conf: SparkConf,
      indexFile: File,
      dataFile: File,
      blockManagerUpdater: () => Unit): Unit = {}

  def read(resolver: ShuffleBlockResolver, blockId: BlockId): ManagedBuffer = {
    resolver.getBlockData(blockId)
  }

  def createInputStream(buf: ManagedBuffer, blockId: BlockId): InputStream = {
    buf.createInputStream()
  }

  def delete(conf: SparkConf, file: File): Unit = {}

  def reportBlockStatus(
      blockManager: BlockManager,
      shuffleId: Int,
      mapId: Long,
      indexLength: Long,
      dataLength: Long): Unit = {}

  def getMapOutputTrackerMasterEndpoint(
      rpcEnv: RpcEnv,
      tracker: MapOutputTrackerMaster,
      conf: SparkConf): RpcEndpoint = {
    new MapOutputTrackerMasterEndpoint(rpcEnv, tracker, conf)
  }
}
