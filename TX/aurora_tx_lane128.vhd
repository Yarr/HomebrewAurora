-------------------------------------------------------------------------------------
-- Company:        LBNL / HEIA-FR
-- Engineer:       Queiroz Maic
-- E-Mail:         mqueiroz at lbl.gov
--                 maic.queiroz at edu.hefr.ch
-- Create Date:    01:24:12 07/03/2018
-- Design Name:
-- Module Name:    aurora_tx_lane128 - Behavioral
-- Project Name:   Pixel data-stream aggregator
-- Target Devices: Xilinx Kintex-7 KC705
-- Tool versions:  Xilinx Vivado v2017.4
-- Description:    Aurora TX Lane, map all the subcomponents
--
-- Additional Comments:  -
--
-------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity aurora_tx_lane128 is
  port (
    -- Sys connect
    rst_i              : in  std_logic;
    clk_i              : in  std_logic;
    clkhigh_i          : in  std_logic;
    -- Inputs
    data66tx_i         : in  std_logic_vector(65 downto 0);
    -- Outputs
    read_o             : out std_logic;
    dataout_p          : out std_logic;
    dataout_n          : out std_logic
  );
end aurora_tx_lane128;

architecture Behavioral of aurora_tx_lane128 is
  ----------------------------
  -- Components
  ----------------------------
  
  -- Data scrambler (no impact on the header)
  component scrambler
  port (
    data_in            : in  std_logic_vector(0 to 63);
    data_out           : out std_logic_vector(65 downto 0);
    enable             : in  std_logic;
    sync_info          : in  std_logic_vector(1 downto 0);
    clk                : in  std_logic;
    rst                : in  std_logic
  );
  end component scrambler;
  
  -- Garbox 66 bit to 32 bit
  component gearbox66to32
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
  end component;
  
  -- 32bit to 8 bit (required to have the right serdes input width)
  component serdes32to8
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
  end component;
  
  -- Serdes 8 to 1
  component serdes8to1
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
  end component;
  
  ----------------------------
  -- Signals
  ----------------------------  
  signal data66_s        : std_logic_vector(65 downto 0);     -- 66 bit Header + Block
  signal data32_s        : std_logic_vector(31 downto 0);     -- 32-bit chunks
  signal data32_valid_s  : std_logic;                         -- 32-bit chunks validity
  signal data8_s         : std_logic_vector(7 downto 0);      -- 8-bit chunks
  signal readandscramb_s : std_logic;                         -- Read block and scramble flag

  ----------------------------
  -- Constants
  ----------------------------
  constant RATIO         : integer := 4;

begin

  --  Generics constraints checking
  assert (RATIO >= 4)
  report "aurora_tx_lane128, generic constant RATIO error: ratio must be 4 minimum"
  severity failure;


  Map1: scrambler port map (
    data_in => data66tx_i(63 downto 0),
    data_out => data66_s,
    enable => readandscramb_s,
    sync_info => data66tx_i(65 downto 64),
    clk => clk_i,
    rst => rst_i
  );
  
  Map2gb66to32:gearbox66to32
  generic map (
    ratio_g => RATIO
  )
  port map(
    rst_i => rst_i,
    clk_i => clk_i,
    data66_i => data66_s,
    data32_o => data32_s,
    data32_valid_o => data32_valid_s,
    read_o => readandscramb_s
  );
  
  Map3serdes32to8:serdes32to8
  port map(
    rst_i => rst_i,
    clk_i => clk_i,
    data32_i => data32_s,
    data32_valid_i => data32_valid_s,
    data8_o => data8_s
  );
  
  Map4serdes1to8:serdes8to1
  port map(
    rst_i => rst_i,
    clk_i => clk_i,
    clkhigh_i => clkhigh_i,
    data8_i => data8_s,
    TQ_o => open,
    dataout_p => dataout_p,
    dataout_n => dataout_n
  );

  read_o <= readandscramb_s;
  
end Behavioral;
