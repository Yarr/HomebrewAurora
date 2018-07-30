-------------------------------------------------------------------------------------
-- Company:        LBNL / HEIA-FR
-- Engineer:       Queiroz Maic
-- E-Mail:         mqueiroz at lbl.gov
--                 maic.queiroz at edu.hefr.ch
-- Create Date:    00:32:09 07/10/2018
-- Design Name:
-- Module Name:    comparator - Behavioral
-- Project Name:   Pixel data-stream aggregator
-- Target Devices: Xilinx Kintex-7 KC705
-- Tool versions:  Xilinx Vivado v2017.4
-- Description:    The purpose of this VHDL component is to implement a test module
--                 that is able to detect the errors during an incrementing value
--                 data transmission.
--
-- Additional Comments:  -
--
-------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity comparator is
  port (
    -- Sys connect
    rst_i            : in  std_logic;
    clk_i            : in  std_logic;
    -- Inputs
    data66_i         : in  std_logic_vector(65 downto 0);
    data66_valid_i   : in  std_logic;
    -- Outputs
    ok_o             : out std_logic
  );
end comparator;

architecture Behavioral of comparator is
  ----------------------------
  -- Types
  ----------------------------  
  type     state is (Init, Ready, Save, Error, Finished);                 -- FSM State definition

  ----------------------------
  -- Signals
  ----------------------------  
  signal   current_state, future_state  : state;
  signal   last_data_s                  : std_logic_vector(63 downto 0);  -- Current and future state
  signal   old_last_data_s              : std_logic_vector(63 downto 0);  -- Buffer for last data
  
  ----------------------------
  -- Signals
  ----------------------------  
  -- Max possible value
  constant MAXDATA                      : std_logic_vector(63 downto 0) := x"FFFFFFFFFFFFFFFF";

begin

  ----------------------------------------------------------------------------------
  -- ProcessName: processClockSignal
  -- Description: Used to store the last valid data
  ----------------------------------------------------------------------------------
  processClockSignal: process (rst_i, clk_i)
  begin
    if (rst_i = '1') then
      old_last_data_s <= x"0000000000000000";
    elsif rising_edge(clk_i) then
      if last_data_s /= old_last_data_s then
        old_last_data_s <= last_data_s;
      end if;
    end if;
  end process processClockSignal;

  ----------------------------------------------------------------------------------
  -- ProcessName: future_state_prcs
  -- Description: The purpose of this process is to decide witch state is the future
  --              state
  ----------------------------------------------------------------------------------
  future_state_prcs : process (current_state, data66_valid_i, data66_i, last_data_s)
  begin
    case current_state is
      when Init =>
        if data66_valid_i = '1' then
          future_state <= Save;
        else
          future_state <= Init;
        end if;
      when Ready =>
        if data66_valid_i = '1' and unsigned(data66_i(63 downto 0)) = unsigned(last_data_s) + 1
           and (data66_i(65 downto 64) = "01" or data66_i(65 downto 64) = "10") then
          future_state <= Save;
        elsif data66_valid_i = '1' then
          future_state <= Error;
        else
          future_state <= Ready;
        end if;
      when Save =>
        if data66_i(63 downto 0) = MAXDATA then
          future_state <= Finished;
        else
          future_state <= Ready;
        end if;
      when Finished =>
        future_state <= Finished;
      when Others =>
        future_state <= Error;
    end case;
  end process;

  ----------------------------------------------------------------------------------
  -- ProcessName: change_state_prcs
  -- Description: The purpose of this process is to change the state according to
  --              the decisions made in the future_state_prcs
  ----------------------------------------------------------------------------------
  change_state_prcs : process (clk_i, rst_i)
  begin
    if rst_i = '1' then
      current_state <= Init;
    elsif rising_edge(clk_i) then
      current_state <= future_state;
    end if;
  end process;

  ----------------------------------------------------------------------------------
  -- ProcessName: out_circuit_prcs
  -- Description: Output logic based on the current state
  ----------------------------------------------------------------------------------
  out_circuit_prcs : process (current_state, old_last_data_s, data66_i)
  begin
    last_data_s <= old_last_data_s;
    ok_o <= '1';
    if current_state = Save then
      last_data_s <= data66_i(63 downto 0);
    elsif current_state = Init or current_state = Error then
      ok_o <= '0';
    end if;
  end process;

end Behavioral;
