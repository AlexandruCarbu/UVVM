--================================================================================================================================
-- Copyright 2025 UVVM
-- Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 and in the provided LICENSE.TXT.
--
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
-- an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and limitations under the License.
--================================================================================================================================
-- Note : Any functionality not explicitly described in the documentation is subject to change at any time
----------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
-- Description   : See library quick reference (under 'doc') and README-file(s)
------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

-- We assume the master BFM package is available so we can reuse its types and functions.
use work.axilite_bfm_pkg.all;

package axilite_slave_tb_pkg is
  
  --===============================================================================================
  -- Types and constants for AXILITE BFMs
  --===============================================================================================
  constant scope                    : string := "AXILITE_SLAVE_BFM_TEST_BENCH";
  --constant msg_id_panel             : t_msg_id_panel       := shared_msg_id_panel;
  --constant config                   : t_axilite_slave_bfm_config := C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT;

  constant ADDR_WIDTH               : natural := 32;
  constant DATA_WIDTH               : natural := 32;

  constant TEST_ADDR_VALUE          : unsigned (ADDR_WIDTH - 1 downto 0) := X"00000100";
  constant TEST_DATA_VALUE          : std_logic_vector (DATA_WIDTH - 1 downto 0) := X"CAFEBABE";



end package axilite_slave_tb_pkg;

package body axilite_slave_tb_pkg is
end package body axilite_slave_tb_pkg;
  