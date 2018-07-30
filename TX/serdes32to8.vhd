-------------------------------------------------------------------------------------
-- Company:        LBNL / HEIA-FR
-- Engineer:       Queiroz Maic
-- E-Mail:         mqueiroz at lbl.gov
--                 maic.queiroz at edu.hefr.ch
-- Create Date:    01:46:20 06/30/2018
-- Design Name:
-- Module Name:    serdes32to8 - Behavioral
-- Project Name:   Pixel data-stream aggregator
-- Target Devices: Xilinx Kintex-7 KC705
-- Tool versions:  Xilinx Vivado v2017.4
-- Description:    The purpose of this VHDL component is to implement a conversion
--                 from a 32 bit input to a 8 bit output, outputing 4 blocks
--                 of 8 bit for each input.
--
-- Additional Comments:  -
--
-------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity serdes32to8 is
  port (
    -- Sys connect
    rst_i            : in  std_logic;
    clk_i            : in  std_logic;

    -- Inputs
    data32_i         : in  std_logic_vector(31 downto 0);
    data32_valid_i   : in  std_logic;

    -- Outputs
    data8_o          : out std_logic_vector(7 downto 0)
  );
end serdes32to8;

architecture Behavioral of serdes32to8 is
  ----------------------------
  -- Signals
  ----------------------------  
  signal   buffer32_s       : std_logic_vector(31 downto 0);  -- 32 bit buffer
  signal   c32to8_cnt_s     : integer range 0 to 3 ;          -- Current 8 bit output cycle in a 32 bit data
  
  ----------------------------
  -- Constants
  ----------------------------
  constant c_c32TO8_CNT     : integer := 3 ;                  -- Max 8 bit output cycle
begin

  ----------------------------------------------------------------------------------
  -- ProcessName: serdes_proc
  -- Description: conversion from a 32 bit input to a 8 bit output, outputing 4 blocks
  --              of 8 bit for each input.
  ----------------------------------------------------------------------------------
  serdes_proc : process(clk_i, rst_i)
  begin
    if (rst_i = '1') then
      buffer32_s <= (others => '0');
    elsif rising_edge(clk_i) then
      -- counter
      if c32to8_cnt_s = c_c32TO8_CNT or data32_valid_i = '1' then
        c32to8_cnt_s <= 0;
      else
        c32to8_cnt_s <= c32to8_cnt_s + 1;
      end if;

      -- Save in buffer
      if data32_valid_i = '1' then
        buffer32_s <= data32_i;
      end if;
    end if;
  end process;

  --output
  data8_o <= buffer32_s(31 - (c32to8_cnt_s * 8) downto 24 - (c32to8_cnt_s * 8));

end Behavioral;
