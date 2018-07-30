-------------------------------------------------------------------------------------
-- Company:        LBNL / HEIA-FR
-- Engineer:       Queiroz Maic
-- E-Mail:         mqueiroz at lbl.gov
--                 maic.queiroz at edu.hefr.ch
-- Create Date:    22:09:13 07/03/2018
-- Design Name:
-- Module Name:    serdes1to8 - Behavioral
-- Project Name:   Pixel data-stream aggregator
-- Target Devices: Xilinx Kintex-7 KC705
-- Tool versions:  Xilinx Vivado v2017.4
-- Description:    The purpose of this VHDL component is to implement a 8 bit DDR
--                 serializer and to output data in differential.
--                 Note: Words are transmitted LSB first
-- Additional Comments:  -
--
-------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library unisim;
use unisim.vcomponents.all;

entity serdes8to1 is
  port (
    -- Sys connect
    rst_i            : in  std_logic;
    clk_i            : in  std_logic;
    clkhigh_i        : in  std_logic;
    -- Inputs
    data8_i          : in  std_logic_vector(7 downto 0);
    -- Outputs
    TQ_o             : out std_logic;
    dataout_p        : out std_logic;
    dataout_n        : out std_logic
  );
end serdes8to1;

architecture Behavioral of serdes8to1 is
  ----------------------------
  -- Signals
  ----------------------------  
  signal tx_data_out : std_logic;  -- OSERDESE2 ouptut
begin

  -- OSERDESE2 mapping
  oserdes_m : OSERDESE2
  generic map(
    DATA_WIDTH => 8,               -- SERDES word width
    TRISTATE_WIDTH => 1,
    DATA_RATE_OQ => "DDR",         -- <SDR>, DDR
    DATA_RATE_TQ => "SDR",         -- <SDR>, DDR
    SERDES_MODE => "MASTER"        -- <DEFAULT>, MASTER, SLAVE
  )
  port map (
    OQ => tx_data_out,
    OCE => '1',
    CLK => clkhigh_i,
    RST => rst_i,
    CLKDIV => clk_i,
    D8 => data8_i(0),
    D7 => data8_i(1),
    D6 => data8_i(2),
    D5 => data8_i(3),
    D4 => data8_i(4),
    D3 => data8_i(5),
    D2 => data8_i(6),
    D1 => data8_i(7),
    TQ => TQ_o,
    T1 => '0',
    T2 => '0',
    T3 => '0',
    T4 => '0',
    TCE => '0',
    TBYTEIN => '0',
    TBYTEOUT => open,
    OFB => open,
    TFB => open,
    SHIFTOUT1 => open,
    SHIFTOUT2 => open,
    SHIFTIN1 => '0',
    SHIFTIN2 => '0'
  );

  -- OBUFDS mapping
  io_data_out : OBUFDS 
  port map (
    O => dataout_p,
    OB => dataout_n,
    I => tx_data_out
  );

end Behavioral;
