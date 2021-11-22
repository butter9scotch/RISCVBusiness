/*
*   Copyright 2016 Purdue University
*   
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*   
*       http://www.apache.org/licenses/LICENSE-2.0
*   
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*
*
*   Filename:     permutation_unit.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 11/21/2021
*   Description:  Support permutation operation
*/

`include "vector_lane_if.vh"

module permutation_unit (
  vector_lane_if.permutation_unit pu_if
);

  import rv32v_types_pkg::*;

  assign pu_if.wdata_p = pu_if.vs2_data;

endmodule
