/*
 * Copyright (c) 2015-2017 "Neo Technology,"
 * Network Engine for Objects in Lund AB [http://neotechnology.com]
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.opencypher.tools.tck.api

import org.junit.jupiter.api.function.Executable
import org.opencypher.tools.tck.SideEffectOps
import org.opencypher.tools.tck.SideEffectOps._
import org.opencypher.tools.tck.values.CypherValue

import scala.compat.Platform.EOL

case class Scenario(featureName: String, name: String, steps: List[Step]) extends (Graph => Executable) {
  override def toString() = s"""Feature "$featureName": Scenario "$name""""

  override def apply(graph: Graph): Executable = new Executable {
    override def execute(): Unit = executeOnGraph(graph)
  }

  def executeOnGraph(empty: Graph): Unit = {
    steps.foldLeft(ScenarioContext(empty)) {
      case (ctx, Execute(query)) =>
        ctx.execute(query)
      case (ctx, Measure) =>
        ctx.measure
      case (ctx, RegisterProcedure(signature, table)) =>
        ctx.graph match {
          case support: ProcedureSupport =>
            support.registerProcedure(signature, table)
          case _ =>
        }
        ctx
      case (ctx, ExpectResult(expected, sorted)) =>
        val success = if (sorted) {
          expected == ctx.lastResult
        } else {
          expected.equalsUnordered(ctx.lastResult)
        }
        if (!success) {
          val detail = if (sorted) "ordered rows" else "in any order of rows"
          throw new ScenarioFailedException(s"${EOL}Expected ($detail):$EOL$expected${EOL}Actual:$EOL${ctx.lastResult}")
        }
        ctx
      case (ctx, SideEffects(expected)) =>
        val before = ctx.state
        val after = ctx.measure.state
        val diff = before diff after
        if (diff != expected)
          throw new ScenarioFailedException(
            s"${EOL}Expected side effects:$EOL$expected${EOL}Actual side effects:$EOL$diff")
        ctx
      case (_, step) =>
        throw new UnsupportedOperationException(s"Unsupported step: $step")
    }
  }

  implicit def toCypherValueRecords(t: (Graph, Records)): (Graph, CypherValueRecords) =
    t._1 -> t._2.toCypherValues
}

case class ScenarioContext(
    graph: Graph,
    lastResult: CypherValueRecords = CypherValueRecords.empty,
    state: State = State(),
    parameters: Map[String, CypherValue] = Map.empty) {

  def execute(query: String): ScenarioContext = {
    val (g, r) = graph.execute(query, parameters)
    copy(graph = g, lastResult = r.toCypherValues)
  }

  def measure: ScenarioContext = {
    copy(state = SideEffectOps.measureState(graph))
  }
}

class ScenarioFailedException(msg: String) extends Throwable(msg)