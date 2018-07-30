-------------------------------------------------------------------------------------
-- Company:        LBNL / HEIA-FR
-- Engineer:       Queiroz Maic
-- E-Mail:         mqueiroz at lbl.gov
--                 maic.queiroz at edu.hefr.ch
-- Create Date:    00:32:09 07/10/2018
-- Design Name:
-- Module Name:    generator - Behavioral
-- Project Name:   Pixel data-stream aggregator
-- Target Devices: Xilinx Kintex-7 KC705
-- Tool versions:  Xilinx Vivado v2017.4
-- Description:    The purpose of this VHDL component is to implement a test module
--                 that is able to send incrementing value in a data transmission.
--
-- Additional Comments:  -
--
-------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity generator is
  port (
    -- Sys connect
    rst_i            : in  std_logic;
    clk_i            : in  std_logic;
    -- Inputs
    read_i           : in  std_logic;
    -- Outputs
    data_o           : out std_logic_vector(65 downto 0)
  );
end generator;

architecture Behavioral of generator is
  signal   read_s                 : std_logic;
  signal   one_clk_read_s         : std_logic;
  constant MAXDATA                : std_logic_vector(63 downto 0) := x"FFFFFFFFFFFFFFFF";
  signal   current_data_s         : std_logic_vector(63 downto 0);
begin

  ----------------------------------------------------------------------------------
  -- ProcessName: processClockSignal
  -- Description: Used to detect falling edge of the read_i
  ----------------------------------------------------------------------------------
  processClockSignal: process (rst_i, clk_i)
  begin
    if (rst_i = '1') then
      read_s <= '0';
    elsif rising_edge(clk_i) then
      read_s <= read_i;
    end if;
  end process processClockSignal;

  one_clk_read_s <= '1' when read_i = '1' and read_s = '0' else '0';
        
  -- Example:
  --                     __    __    __    __    __    __    __    __    __
  --      clk_i       __/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \__/  \_...
  --                                       ______________
  --      read_i      ____________________/              \___________________...
  --                                             ______________
  --      read_s      __________________________/              \_____________...
  --                                       _____
  -- one_clk_read_s   ____________________/     \___________________________...


  ----------------------------------------------------------------------------------
  -- ProcessName: counter_prcs
  -- Description: The purpose of this process is to increment a counter each time a
  --              read is requested
  ----------------------------------------------------------------------------------
  counter_prcs : process (clk_i, rst_i)
  begin
    if rst_i = '1' then
      current_data_s <= (others => '0');
    elsif rising_edge(clk_i) then
      if one_clk_read_s = '1' and current_data_s < MAXDATA then
        current_data_s <= std_logic_vector(unsigned(current_data_s) + 1);
      end if;
    end if;
  end process;

  -- Output: dummy header and current value
  data_o <= "01" & current_data_s;

end Behavioral;