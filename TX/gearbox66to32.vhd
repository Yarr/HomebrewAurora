-------------------------------------------------------------------------------------
-- Company:        LBNL / HEIA-FR
-- Engineer:       Queiroz Maic
-- E-Mail:         mqueiroz at lbl.gov
--                 maic.queiroz at edu.hefr.ch
-- Create Date:    20:48:40 06/27/2018
-- Design Name:
-- Module Name:    gearbox66to32 - Behavioral
-- Project Name:   Pixel data-stream aggregator
-- Target Devices: Xilinx Kintex-7 KC705
-- Tool versions:  Xilinx Vivado v2017.4
-- Description:    The purpose of this VHDL component is to implement a gearbox taking
--                 a 66 bit input and outputing 32bit.
--
-- Additional Comments:  -
--
-------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity gearbox66to32 is
  generic (
    ratio_g          : integer := 4
  );
  port (
    -- Sys connect
    rst_i            : in  std_logic;
    clk_i            : in  std_logic;
    -- Inputs
    data66_i         : in  std_logic_vector(65 downto 0);
    -- Outputs
    data32_o         : out std_logic_vector(31 downto 0);
    data32_valid_o   : out std_logic;
    read_o           : out std_logic
  );
end gearbox66to32;

architecture Behavioral of gearbox66to32 is
  ----------------------------
  -- Signals
  ----------------------------  
  signal   gearbox_cnt_s    : integer range 0 to 32;          -- Gearbox cycles counts
  signal   gbox_cnt_dur_s   : integer range 0 to ratio_g-1;   -- Ratio counter
  signal   buffer96_s       : std_logic_vector(95 downto 0);  -- Gearbox buffer
  
  ----------------------------
  -- Constants
  ----------------------------
  constant c_GEARBOX_CNT    : integer := 32;                  -- Geatbox cycles counts max value
  constant c_GBOX_CNT_DUR   : integer := ratio_g-1;           -- Ratio conter max value
  constant c_BLOCK_SIZE     : integer := 66;                  -- Block size
  constant c_BUFF_MAX_INDEX : integer := 95;                  -- Gearbox buffer max index

begin

  --  Generics constraints checking
  assert (ratio_g >= 1)
  report "gearbox66to32, geeneric parameter ratio_g error: ratio must be 1 minimum"
  severity failure;

  ----------------------------------------------------------------------------------
  -- ProcessName: shift_proc
  -- Description: conversion from a 66 bit input to a 32 bit output. Each 33rd cycle
  --              a compensation output is transmitted
  ----------------------------------------------------------------------------------
  shift_proc: process(clk_i, rst_i)
  begin
    if (rst_i = '1') then
      buffer96_s <= (others => '0');
      gearbox_cnt_s <= 0;
      read_o <= '0';
    elsif rising_edge(clk_i) then
     -- counter
      if gearbox_cnt_s = c_GEARBOX_CNT and gbox_cnt_dur_s = c_GBOX_CNT_DUR then
        gearbox_cnt_s <= 0;
        gbox_cnt_dur_s <= 0;
      elsif gbox_cnt_dur_s = c_GBOX_CNT_DUR then
        gearbox_cnt_s <= gearbox_cnt_s + 1;
        gbox_cnt_dur_s <= 0;
      else
        gbox_cnt_dur_s <= gbox_cnt_dur_s + 1;
      end if;
      
      -- Shift and insert new block depending on the counter value
      read_o <= '0';
      if gbox_cnt_dur_s = c_GBOX_CNT_DUR then
        buffer96_s <= (others => '0');
        if gearbox_cnt_s = c_GEARBOX_CNT then
          -- 32 special case
          buffer96_s(95 downto (c_BUFF_MAX_INDEX - (c_BLOCK_SIZE - 1))) <= data66_i;
          read_o <= '1';
        elsif gearbox_cnt_s mod 2 = 0 or gearbox_cnt_s = 31 then
          -- even number or 31 (special case)
          buffer96_s(95 downto 32) <= buffer96_s(63 downto 0);
        else
          -- remaining odd numbers
          read_o <= '1';
          buffer96_s((c_BUFF_MAX_INDEX - gearbox_cnt_s - 1) downto (c_BUFF_MAX_INDEX - gearbox_cnt_s - c_BLOCK_SIZE)) <= data66_i; --OK
          --buffer96_s(c_BUFF_MAX_INDEX downto (c_BUFF_MAX_INDEX - gearbox_cnt_s)) <= buffer96_s(63 downto (63 - gearbox_cnt_s)); 
          -- synthesis NOK (complex assignment not supported)  --> Replaced with the case.. (https://www.xilinx.com/support/answers/52302.html)
          case gearbox_cnt_s is
            when 1 => 
              buffer96_s(c_BUFF_MAX_INDEX downto 94) <= buffer96_s(63 downto 62);
            when 3 =>
              buffer96_s(c_BUFF_MAX_INDEX downto 92) <= buffer96_s(63 downto 60);
            when 5 =>
              buffer96_s(c_BUFF_MAX_INDEX downto 90) <= buffer96_s(63 downto 58);
            when 7 => 
              buffer96_s(c_BUFF_MAX_INDEX downto 88) <= buffer96_s(63 downto 56);
            when 9 =>
              buffer96_s(c_BUFF_MAX_INDEX downto 86) <= buffer96_s(63 downto 54);
            when 11 =>
              buffer96_s(c_BUFF_MAX_INDEX downto 84) <= buffer96_s(63 downto 52);
            when 13 => 
              buffer96_s(c_BUFF_MAX_INDEX downto 82) <= buffer96_s(63 downto 50);
            when 15 =>
              buffer96_s(c_BUFF_MAX_INDEX downto 80) <= buffer96_s(63 downto 48);
            when 17 =>
              buffer96_s(c_BUFF_MAX_INDEX downto 78) <= buffer96_s(63 downto 46);
            when 19 => 
              buffer96_s(c_BUFF_MAX_INDEX downto 76) <= buffer96_s(63 downto 44);
            when 21 =>
              buffer96_s(c_BUFF_MAX_INDEX downto 74) <= buffer96_s(63 downto 42);
            when 23 =>
              buffer96_s(c_BUFF_MAX_INDEX downto 72) <= buffer96_s(63 downto 40);
            when 25 => 
              buffer96_s(c_BUFF_MAX_INDEX downto 70) <= buffer96_s(63 downto 38);
            when 27 =>
              buffer96_s(c_BUFF_MAX_INDEX downto 68) <= buffer96_s(63 downto 36);
            when 29 =>
              buffer96_s(c_BUFF_MAX_INDEX downto 66) <= buffer96_s(63 downto 34);
            when others =>
              buffer96_s <= (others => '0');
          end case;
        end if;
      end if;
    end if;
  end process shift_proc;

  -- Output logic
  data32_o <= buffer96_s(95 downto 64);
  data32_valid_o <= '1' when gbox_cnt_dur_s = 0 else '0';

end Behavioral;
