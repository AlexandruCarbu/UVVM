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

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_clock_generator;
context bitvis_vip_clock_generator.vvc_context;

library bitvis_vip_axilite;
context bitvis_vip_axilite.vvc_context;

use work.axilite_slave_tb_pkg.all;

-- hdlregression:tb
-- Test bench entity
entity axilite_slave_bfm_tb is
end entity axilite_slave_bfm_tb;

architecture sim of axilite_slave_bfm_tb is

  constant      vvc_instance_idx           : integer              := 1;
  
  signal        clk                        : std_logic            := '0';
  signal        arst                       : std_logic            := '0';
  
  ------------------------------------------------------------------------------
  -- Create a common AXI‑Lite interface signal. We initialize it using the master’s
  -- helper function (assumed to be compatible with the slave’s view).
  ------------------------------------------------------------------------------
  signal axi_if : t_axilite_if(write_address_channel(awaddr(ADDR_WIDTH - 1 downto 0)),
  write_data_channel(wdata(DATA_WIDTH - 1 downto 0),
                     wstrb((DATA_WIDTH / 8) - 1 downto 0)),
  read_address_channel(araddr(ADDR_WIDTH - 1 downto 0)),
  read_data_channel(rdata(DATA_WIDTH - 1 downto 0)));

  -- slave has a differen signal init
  signal axislv_if : t_axilite_if(write_address_channel(awaddr(ADDR_WIDTH - 1 downto 0)),
  write_data_channel(wdata(DATA_WIDTH - 1 downto 0),
                     wstrb((DATA_WIDTH / 8) - 1 downto 0)),
  read_address_channel(araddr(ADDR_WIDTH - 1 downto 0)),
  read_data_channel(rdata(DATA_WIDTH - 1 downto 0))) := init_axilite_slave_if_signals(ADDR_WIDTH, DATA_WIDTH);

  signal          read_addr                  : unsigned         (ADDR_WIDTH - 1 downto 0);
  signal          read_data                  : std_logic_vector (DATA_WIDTH - 1 downto 0); 
  


begin
  -----------------------------------------------------------------------------
  -- Instantiate test harness, containing DUT and Executors
  -----------------------------------------------------------------------------
  i_test_harness : entity work.axi_lite_bfm_th
                  port map (
                    clk         => clk,         -- Connect clock
                    arst        => arst,        -- Connect reset
                    axilite_if  => axi_if  -- Connect axi_if
                  );

  axislv_if.write_address_channel.awvalid <= axi_if.write_address_channel.awvalid;
  axislv_if.write_data_channel.wvalid     <= axi_if.write_data_channel.wvalid    ;
  

  ----------------------------------------------------------------------------
  -- AXI Lite Sequencer
  ----------------------------------------------------------------------------
  p_sequencer : process
    constant        proc_call                  : string := "";  --"axilite_write(A:" & to_string(addr_value, HEX, AS_IS, INCL_RADIX) & ", " & to_string(data_value, HEX, AS_IS, INCL_RADIX) & ")";
  begin
    -- Wait for UVVM to finish initialization
    await_uvvm_initialization(VOID);

    -- Print the configuration to the log
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);
    enable_log_msg(ALL_MESSAGES);
    enable_log_msg(ID_LOG_HDR);
    enable_log_msg(ID_SEQUENCER);
    enable_log_msg(ID_UVVM_SEND_CMD);
    log(ID_LOG_HDR, "Starting simulation of TB AXI Slave", C_SCOPE);

    -- Init the axi interface
    axi_if <= init_axilite_slave_if_signals(ADDR_WIDTH, DATA_WIDTH);
    
    -- Start the clk
    start_clock(CLOCK_GENERATOR_VVCT, 0, "Start clock generator");

    -- Wait for reset
    log(ID_LOG_HDR, "Queueing write transaction", C_SCOPE);

    -- Master starts the write transaction
    axilite_write(AXILITE_VVCT, 1, TEST_ADDR_VALUE, TEST_DATA_VALUE, "Master write");
    --axilite_write(
    --  msg                 => "Master write",
    --  VVCT                => AXILITE_VVCT,
    --  vvc_instance_idx    => vvc_instance_idx,
    --  addr                => TEST_ADDR_VALUE,
    --  data                => TEST_DATA_VALUE
    --);
    
    log(ID_LOG_HDR, "Starting slave process", C_SCOPE);

    -- Slave waits for a write transaction
    axilite_slave_await_write(
      msg                 => "Slave wait for write",
      clk                 => clk,
      axilite_if          => axi_if,
      addr_value          => read_addr,
      data_value          => read_data
    );

    log(ID_LOG_HDR, "read_addr: " & to_string(read_addr), C_SCOPE);
    log(ID_LOG_HDR, "read_data: " & to_string(read_data), C_SCOPE);
    check_value(read_addr = TEST_ADDR_VALUE, C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT.max_wait_cycles_severity, ": Address value", scope, ID_NEVER, shared_msg_id_panel, proc_call);
    check_value(read_data = TEST_DATA_VALUE, C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT.max_wait_cycles_severity, ": Data value", scope, ID_NEVER, shared_msg_id_panel, proc_call);

    -- Slave sends write response
    axilite_slave_send_write_response(
      msg                 => "Slave sending write response",
      clk                 => clk,
      axilite_if          => axi_if
    );

    -- Master starts the read transaction
    axilite_read(
      msg                 => "Master read",
      VVCT                => AXILITE_VVCT,
      vvc_instance_idx    => vvc_instance_idx,
      addr                => TEST_ADDR_VALUE
    );

    -- Slave waits for a read transaction
    axilite_slave_await_read(
      msg                 => "Slave waiting for read",
      clk                 => clk,
      axilite_if          => axi_if,
      addr_value          => read_addr
    );

    log(ID_LOG_HDR, "read_addr: " & to_string(read_addr), C_SCOPE);
    check_value(read_addr = TEST_ADDR_VALUE, C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT.max_wait_cycles_severity, ": Address value", scope, ID_NEVER, shared_msg_id_panel, proc_call);  

    -- Slave sends read response
    axilite_slave_send_read_response(
      msg                 => "Slave sending read response",
      clk                 => clk,
      axilite_if          => axi_if,
      data_value          => TEST_DATA_VALUE
    );

    -- Master check after read
    axilite_check(
      msg                 => "Master check",
      VVCT                => AXILITE_VVCT,
      vvc_instance_idx    => vvc_instance_idx,
      addr                => TEST_ADDR_VALUE,
      data                => TEST_DATA_VALUE
    );
  
    wait; -- End process
  end process p_sequencer;

end architecture sim;
