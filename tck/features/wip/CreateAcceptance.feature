#
# Copyright (c) 2015-2019 "Neo Technology,"
# Network Engine for Objects in Lund AB [http://neotechnology.com]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Attribution Notice under the terms of the Apache License 2.0
#
# This work was created by the collective efforts of the openCypher community.
# Without limiting the terms of Section 6, any Derivative Work that is not
# approved by the public consensus process of the openCypher Implementers Group
# should not be described as “Cypher” (and Cypher® is a registered trademark of
# Neo4j Inc.) or as "openCypher". Extensions by implementers or prototypes or
# proposals for change that have been documented or implemented should only be
# described as "implementation extensions to Cypher" or as "proposed changes to
# Cypher that are not yet approved by the openCypher community".
#

#encoding: utf-8

Feature: CreateAcceptance

  Scenario: Create a pattern with multiple hops
    Given an empty graph
    When executing query:
      """
      CREATE (:A)-[:R]->(:B)-[:R]->(:C)
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 3 |
      | +relationships | 2 |
      | +labels        | 3 |
    When executing control query:
      """
      MATCH (a:A)-[:R]->(b:B)-[:R]->(c:C)
      RETURN a, b, c
      """
    Then the result should be:
      | a    | b    | c    |
      | (:A) | (:B) | (:C) |

  Scenario: Create a pattern with multiple hops in the reverse direction
    Given an empty graph
    When executing query:
      """
      CREATE (:A)<-[:R]-(:B)<-[:R]-(:C)
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 3 |
      | +relationships | 2 |
      | +labels        | 3 |
    When executing control query:
      """
      MATCH (a)<-[:R]-(b)<-[:R]-(c)
      RETURN a, b, c
      """
    Then the result should be:
      | a    | b    | c    |
      | (:A) | (:B) | (:C) |

  Scenario: Create a pattern with multiple hops in varying directions
    Given an empty graph
    When executing query:
      """
      CREATE (:A)-[:R]->(:B)<-[:R]-(:C)
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 3 |
      | +relationships | 2 |
      | +labels        | 3 |
    When executing control query:
      """
      MATCH (a:A)-[r1:R]->(b:B)<-[r2:R]-(c:C)
      RETURN a, b, c
      """
    Then the result should be:
      | a    | b    | c    |
      | (:A) | (:B) | (:C) |

  Scenario: Create a pattern with multiple hops with multiple types and varying directions
    Given any graph
    When executing query:
      """
      CREATE ()-[:R1]->()<-[:R2]-()-[:R3]->()
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 4 |
      | +relationships | 3 |
    When executing query:
      """
      MATCH ()-[r1:R1]->()<-[r2:R2]-()-[r3:R3]->()
      RETURN r1, r2, r3
      """
    Then the result should be:
      | r1    | r2    | r3    |
      | [:R1] | [:R2] | [:R3] |

  Scenario: Creating a pattern with multiple hops and changing directions
    Given an empty graph
    When executing query:
      """
      CREATE (:A)<-[:R1]-(:B)-[:R2]->(:C)
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes         | 3 |
      | +relationships | 2 |
      | +labels        | 3 |
    When executing control query:
      """
      MATCH (a:A)<-[r1:R1]-(b:B)-[r2:R2]->(c:C)
      RETURN *
      """
    Then the result should be:
      | a    | b    | c    | r1    | r2    |
      | (:A) | (:B) | (:C) | [:R1] | [:R2] |
