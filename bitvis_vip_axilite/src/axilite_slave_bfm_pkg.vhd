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

library bitvis_vip_axilite;
use bitvis_vip_axilite.axilite_bfm_pkg.all;

package axilite_slave_bfm_pkg is
  
  --===============================================================================================
  -- Types and constants for AXILITE BFMs
  --===============================================================================================
  constant C_BFM_SCOPE : string := "AXILITE_SLAVE_BFM";

  -- EXOKAY not supported for AXI-Lite, will raise TB_FAILURE
  type t_xresp is (
    OKAY,
    SLVERR,
    DECERR,
    EXOKAY
  );

  type t_axprot is (
    UNPRIVILEGED_NONSECURE_DATA,
    UNPRIVILEGED_NONSECURE_INSTRUCTION,
    UNPRIVILEGED_SECURE_DATA,
    UNPRIVILEGED_SECURE_INSTRUCTION,
    PRIVILEGED_NONSECURE_DATA,
    PRIVILEGED_NONSECURE_INSTRUCTION,
    PRIVILEGED_SECURE_DATA,
    PRIVILEGED_SECURE_INSTRUCTION
  );

  ------------------------------------------------------------------
  -- In many cases master’s configuration record can be reused.
  ------------------------------------------------------------------
  -- Configuration record to be assigned in the test harness.
  type t_axilite_slave_bfm_config is record
    max_wait_cycles            : natural; -- Used for setting the maximum cycles to wait before an alert is issued when waiting for ready and valid signals from the DUT.
    max_wait_cycles_severity   : t_alert_level; -- The above timeout will have this severity
    clock_period               : time;  -- Period of the clock signal.
    clock_period_margin        : time;  -- Input clock period margin to specified clock_period
    clock_margin_severity      : t_alert_level; -- The above margin will have this severity
    setup_time                 : time;  -- Setup time for generated signals, set to clock_period/4
    hold_time                  : time;  -- Hold time for generated signals, set to clock_period/4
    bfm_sync                   : t_bfm_sync; -- Synchronisation of the BFM procedures, i.e. using clock signals, using setup_time and hold_time.
    match_strictness           : t_match_strictness; -- Matching strictness for std_logic values in check procedures.
    expected_response          : t_xresp; -- Sets the expected response for both read and write transactions.
    expected_response_severity : t_alert_level; -- A response mismatch will have this severity.
    protection_setting         : t_axprot; -- Sets the AXI access permissions (e.g. write to data/instruction, privileged and secure access).
    num_aw_pipe_stages         : natural; -- Write Address Channel pipeline steps.
    num_w_pipe_stages          : natural; -- Write Data Channel pipeline steps.
    num_ar_pipe_stages         : natural; -- Read Address Channel pipeline steps.
    num_r_pipe_stages          : natural; -- Read Data Channel pipeline steps.
    num_b_pipe_stages          : natural; -- Response Channel pipeline steps.
    id_for_bfm                 : t_msg_id; -- The message ID used as a general message ID in the AXI-Lite BFM
    id_for_bfm_wait            : t_msg_id; -- The message ID used for logging waits in the AXI-Lite BFM
    id_for_bfm_poll            : t_msg_id; -- The message ID used for logging polling in the AXI-Lite BFM
  end record;

  constant C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT : t_axilite_slave_bfm_config := (
    -- TODO: Make up my own on the way, do not copy paste master config
    max_wait_cycles            => 10,
    max_wait_cycles_severity   => TB_FAILURE,
    clock_period               => -1 ns,
    clock_period_margin        => 0 ns,
    clock_margin_severity      => TB_ERROR,
    setup_time                 => -1 ns,
    hold_time                  => -1 ns,
    bfm_sync                   => SYNC_ON_CLOCK_ONLY,
    match_strictness           => MATCH_EXACT,
    expected_response          => OKAY,
    expected_response_severity => TB_FAILURE,
    protection_setting         => UNPRIVILEGED_NONSECURE_DATA,
    num_aw_pipe_stages         => 1,
    num_w_pipe_stages          => 1,
    num_ar_pipe_stages         => 1,
    num_r_pipe_stages          => 1,
    num_b_pipe_stages          => 1,
    id_for_bfm                 => ID_BFM,
    id_for_bfm_wait            => ID_BFM_WAIT,
    id_for_bfm_poll            => ID_BFM_POLL
  );

  ------------------------------------------
  -- axilite_slave_await_write
  ------------------------------------------
  -- This procedure waits for a write request to be received in the
  -- write address channel and write data channel
  -- TODO: Consider adding other outputs like t_axprot
  procedure axilite_slave_await_write(
    signal addr_value     : out unsigned;
    signal data_value     : out std_logic_vector;
    constant msg          : in string;
    signal   clk          : in std_logic;
    signal   axilite_if   : inout t_axilite_if;
    constant scope        : in string               := C_BFM_SCOPE;
    constant msg_id_panel : in t_msg_id_panel       := shared_msg_id_panel;
    constant config       : in t_axilite_slave_bfm_config := C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT
  );

  
  ------------------------------------------
  -- axilite_slave_await_read
  ------------------------------------------
  -- This procedure waits for a read request to be received in the
  -- read address channel
  -- TODO: Consider adding other outputs like t_axprot
  procedure axilite_slave_await_read(
    signal   addr_value   : out unsigned;
    constant msg          : in string;
    signal   clk          : in std_logic;
    signal   axilite_if   : inout t_axilite_if;
    constant scope        : in string                     := C_BFM_SCOPE;
    constant msg_id_panel : in t_msg_id_panel             := shared_msg_id_panel;
    constant config       : in t_axilite_slave_bfm_config := C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT
  );


  ------------------------------------------
  -- axilite_slave_send_write_response
  ------------------------------------------
  -- This procedure sends the write response status
  procedure axilite_slave_send_write_response(
    constant axilite_response_status : in t_xresp                    := OKAY;
    constant msg                     : in string;
    signal   clk                     : in std_logic;
    signal   axilite_if              : inout t_axilite_if;
    constant scope                   : in string                     := C_BFM_SCOPE;
    constant msg_id_panel            : in t_msg_id_panel             := shared_msg_id_panel;
    constant config                  : in t_axilite_slave_bfm_config := C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT
  );

  
  ------------------------------------------
  -- axilite_slave_send_read_response
  ------------------------------------------
  -- This procedure sends the read data and response status
  procedure axilite_slave_send_read_response(
    constant data_value              : in std_logic_vector;
    constant axilite_response_status : in t_xresp                    := OKAY;
    constant msg                     : in string;
    signal   clk                     : in std_logic;
    signal   axilite_if              : inout t_axilite_if;
    constant scope                   : in string                     := C_BFM_SCOPE;
    constant msg_id_panel            : in t_msg_id_panel             := shared_msg_id_panel;
    constant config                  : in t_axilite_slave_bfm_config := C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT
  );

  ----------------------------------------------------
  -- Support procedures
  ----------------------------------------------------
  function axprot_to_slv(
    axprot : t_axprot
  ) return std_logic_vector;

  function xresp_to_slv(
    constant axilite_response_status : in t_xresp        := OKAY;
    constant scope                   : in string         := C_BFM_SCOPE;
    constant msg_id_panel            : in t_msg_id_panel := shared_msg_id_panel
  ) return std_logic_vector;

  function init_axilite_slave_if_signals(
    addr_width : natural;
    data_width : natural
  ) return t_axilite_if;
  
end package axilite_slave_bfm_pkg;

package body axilite_slave_bfm_pkg is

  function axprot_to_slv(
    axprot : t_axprot
  ) return std_logic_vector is
    variable v_axprot_slv : std_logic_vector(2 downto 0);
  begin
    case axprot is
      when UNPRIVILEGED_SECURE_DATA =>
        v_axprot_slv := "000";
      when PRIVILEGED_SECURE_DATA =>
        v_axprot_slv := "001";
      when UNPRIVILEGED_NONSECURE_DATA =>
        v_axprot_slv := "010";
      when PRIVILEGED_NONSECURE_DATA =>
        v_axprot_slv := "011";
      when UNPRIVILEGED_SECURE_INSTRUCTION =>
        v_axprot_slv := "100";
      when PRIVILEGED_SECURE_INSTRUCTION =>
        v_axprot_slv := "101";
      when UNPRIVILEGED_NONSECURE_INSTRUCTION =>
        v_axprot_slv := "110";
      when PRIVILEGED_NONSECURE_INSTRUCTION =>
        v_axprot_slv := "111";
    end case;
    return v_axprot_slv;
  end function axprot_to_slv;

  function xresp_to_slv(
    constant axilite_response_status : in t_xresp        := OKAY;
    constant scope                   : in string         := C_BFM_SCOPE;
    constant msg_id_panel            : in t_msg_id_panel := shared_msg_id_panel
  ) return std_logic_vector is
    variable v_axilite_response_status_slv : std_logic_vector(1 downto 0);
  begin
    check_value(axilite_response_status /= EXOKAY, TB_FAILURE, "EXOKAY response status is not supported in AXI-Lite", scope, ID_NEVER, msg_id_panel);

    case axilite_response_status is
      when OKAY =>
        v_axilite_response_status_slv := "00";
      when SLVERR =>
        v_axilite_response_status_slv := "10";
      when DECERR =>
        v_axilite_response_status_slv := "11";
      when EXOKAY =>
        v_axilite_response_status_slv := "01";
    end case;
    return v_axilite_response_status_slv;
  end function;

  function init_axilite_slave_if_signals(
    addr_width : natural;
    data_width : natural
  ) return t_axilite_if is
    variable init_if : t_axilite_if(write_address_channel(awaddr(addr_width - 1 downto 0)),
                                    write_data_channel(wdata(data_width - 1 downto 0),
                                                       wstrb((data_width / 8) - 1 downto 0)),
                                    read_address_channel(araddr(addr_width - 1 downto 0)),
                                    read_data_channel(rdata(data_width - 1 downto 0)));
  begin
    -- Write Address Channel
    init_if.write_address_channel.awaddr  := (init_if.write_address_channel.awaddr'range => 'Z');
    init_if.write_address_channel.awvalid := 'Z';
    init_if.write_address_channel.awprot  := (init_if.write_address_channel.awprot'range => 'Z');
    init_if.write_address_channel.awready := '0';
    -- Write Data Channel
    init_if.write_data_channel.wdata      := (init_if.write_data_channel.wdata'range => 'Z');
    init_if.write_data_channel.wstrb      := (init_if.write_data_channel.wstrb'range => 'Z');
    init_if.write_data_channel.wvalid     := 'Z';
    init_if.write_data_channel.wready     := '0';
    -- Write Response Channel
    init_if.write_response_channel.bready := 'Z';
    init_if.write_response_channel.bresp  := (init_if.write_response_channel.bresp'range => '0');
    init_if.write_response_channel.bvalid := '0';
    -- Read Address Channel
    init_if.read_address_channel.araddr   := (init_if.read_address_channel.araddr'range => 'Z');
    init_if.read_address_channel.arvalid  := 'Z';
    init_if.read_address_channel.arprot   := (init_if.read_address_channel.arprot'range => 'Z');
    init_if.read_address_channel.arready  := '0';
    -- Read Data Channel
    init_if.read_data_channel.rready      := 'Z';
    init_if.read_data_channel.rdata       := (init_if.read_data_channel.rdata'range => '0');
    init_if.read_data_channel.rresp       := (init_if.read_data_channel.rresp'range => '0');
    init_if.read_data_channel.rvalid      := '0';
    return init_if;
  end function;
  

  procedure axilite_slave_await_write(
    signal addr_value     : out unsigned;
    signal data_value     : out std_logic_vector;
    constant msg          : in string;
    signal   clk          : in std_logic;
    signal   axilite_if   : inout t_axilite_if;
    constant scope        : in string               := C_BFM_SCOPE;
    constant msg_id_panel : in t_msg_id_panel       := shared_msg_id_panel;
    constant config       : in t_axilite_slave_bfm_config := C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT

  ) is
    constant proc_call              : string := "";  --"axilite_write(A:" & to_string(addr_value, HEX, AS_IS, INCL_RADIX) & ", " & to_string(data_value, HEX, AS_IS, INCL_RADIX) & ")";
    variable v_time_of_rising_edge  : time := -1 ns; -- time stamp for clk period checking
    variable v_time_of_falling_edge : time := -1 ns; -- time stamp for clk period checking
    variable v_wvalid               : std_logic;
    variable v_awvalid              : std_logic;
    variable v_await_wvalid         : boolean := true;
    variable v_await_awvalid        : boolean := true;
  begin
    -- Wait until both the write address and write data are valid.
    for cycle in 0 to config.max_wait_cycles loop
      --log(config.id_for_bfm, "Waiting for AWVALID" & "(" & to_string(axilite_if.write_address_channel.awvalid) & ") and WVALID" & "(" & to_string(axilite_if.write_data_channel.wvalid) & ")", scope, msg_id_panel);
      wait_on_bfm_sync_start(clk, config.bfm_sync, config.setup_time, config.clock_period, v_time_of_falling_edge, v_time_of_rising_edge);
      -- Sample valid signals
      v_wvalid  := axilite_if.write_data_channel.wvalid;
      v_awvalid := axilite_if.write_address_channel.awvalid;
      
      if v_wvalid = '1' and v_awvalid = '1' then
        -- Assert ready signals to complete the handshake.
        -- TODO: Add delay ?
        log(config.id_for_bfm, "Setting AWREADY and WREADY", scope, msg_id_panel);
        axilite_if.write_address_channel.awready <= '1';
        axilite_if.write_data_channel.wready  <= '1';

        -- Hold ready for one clock cycle
        wait_on_bfm_sync_start(clk, config.bfm_sync, config.setup_time, config.clock_period, v_time_of_falling_edge, v_time_of_rising_edge);

        -- Capture the incoming address and data. Not needed for now
        addr_value <= unsigned(axilite_if.write_address_channel.awaddr);
        data_value <= axilite_if.write_data_channel.wdata;
        
        -- Deassert the ready signals.
        log(config.id_for_bfm, "Clearing AWREADY and WREADY", scope, msg_id_panel);
        axilite_if.write_address_channel.awready <= '0';
        axilite_if.write_data_channel.wready  <= '0';
        
        v_await_wvalid := false;
        v_await_awvalid := false;

        exit;
      end if;

    end loop;
    
    check_value(not v_await_wvalid, config.max_wait_cycles_severity, ": Timeout waiting for WVALID", scope, ID_NEVER, msg_id_panel, proc_call);
    check_value(not v_await_awvalid, config.max_wait_cycles_severity, ": Timeout waiting for AWVALID", scope, ID_NEVER, msg_id_panel, proc_call);

  end procedure;

  procedure axilite_slave_await_read(
    signal   addr_value   : out unsigned;
    constant msg          : in string;
    signal   clk          : in std_logic;
    signal   axilite_if   : inout t_axilite_if;
    constant scope        : in string                     := C_BFM_SCOPE;
    constant msg_id_panel : in t_msg_id_panel             := shared_msg_id_panel;
    constant config       : in t_axilite_slave_bfm_config := C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT
  ) is
  begin
    -- Wait until a read address is provided by the master.
    -- TODO: Add timeout
    while not (axilite_if.read_address_channel.arvalid = '1') loop
      wait until rising_edge(clk);
    end loop;

    -- Assert the read ready signal.
    -- TODO: Add delay
    axilite_if.read_address_channel.arready <= '1';

    wait until rising_edge(clk);  -- Wait one cycle for the handshake

    -- Capture the read address.
    addr_value <= unsigned(axilite_if.read_address_channel.araddr);

    -- Deassert the ready signal.
    axilite_if.read_address_channel.arready <= '0';
  end procedure;
  

  procedure axilite_slave_send_write_response(
    constant axilite_response_status : in t_xresp                   := OKAY;
    constant msg                     : in string;
    signal   clk                     : in std_logic;
    signal   axilite_if              : inout t_axilite_if;
    constant scope                   : in string                     := C_BFM_SCOPE;
    constant msg_id_panel            : in t_msg_id_panel             := shared_msg_id_panel;
    constant config                  : in t_axilite_slave_bfm_config := C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT
  ) is
  begin
    -- Drive the response signals.
    axilite_if.write_response_channel.bresp  <= xresp_to_slv(axilite_response_status);
    axilite_if.write_response_channel.bvalid <= '1';

    -- Wait until the master asserts bready.
    -- TODO: Add timeout
    while not (axilite_if.write_response_channel.bready = '1') loop
      wait until rising_edge(clk);
    end loop;

    -- Deassert the valid signal after the handshake.
    axilite_if.write_response_channel.bvalid <= '0';
    wait until rising_edge(clk);
  end procedure;
  

  procedure axilite_slave_send_read_response(
    constant data_value              : in std_logic_vector;
    constant axilite_response_status : in t_xresp                    := OKAY;
    constant msg                     : in string;
    signal   clk                     : in std_logic;
    signal   axilite_if              : inout t_axilite_if;
    constant scope                   : in string                     := C_BFM_SCOPE;
    constant msg_id_panel            : in t_msg_id_panel             := shared_msg_id_panel;
    constant config                  : in t_axilite_slave_bfm_config := C_AXILITE_SLAVE_BFM_CONFIG_DEFAULT
  ) is
  begin
    -- Set the read data and response.
    axilite_if.read_data_channel.rdata  <= data_value;
    axilite_if.read_data_channel.rresp  <= xresp_to_slv(axilite_response_status);
    axilite_if.read_data_channel.rvalid <= '1';

    -- Wait until the master asserts rready.
    -- TODO: Add timeout
    while not (axilite_if.read_data_channel.rready = '1') loop
      wait until rising_edge(clk);
    end loop;

    -- Deassert the valid signal.
    axilite_if.read_data_channel.rvalid <= '0';
    wait until rising_edge(clk);
  end procedure;

end package body axilite_slave_bfm_pkg;
  