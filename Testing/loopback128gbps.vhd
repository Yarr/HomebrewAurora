-------------------------------------------------------------------------------------
-- Company:        LBNL / HEIA-FR
-- Engineer:       Queiroz Maic
-- E-Mail:         mqueiroz at lbl.gov
--                 maic.queiroz at edu.hefr.ch
-- Create Date:    19:49:23 07/10/2018
-- Design Name:
-- Module Name:    128gbpsloopback - Behavioral
-- Project Name:   Pixel data-stream aggregator
-- Target Devices: Xilinx Kintex-7 KC705
-- Tool versions:  Xilinx Vivado v2017.4
-- Description:    Real simulation mapping, to test alignement between tx and rx lanes
--
-- Additional Comments:  -
--
-------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library unisim;
use unisim.vcomponents.all;

entity loopback128gbps is
  Port (
    -- Sys connect
    rst_i            : in  std_logic;
    clkp_i           : in  std_logic;
    clkn_i           : in  std_logic;
    -- Inputs
    datain_p         : in  std_logic;
    datain_n         : in  std_logic;
    -- Outputs
    dataout_p        : out std_logic;
    dataout_n        : out std_logic;
    led0_o           : out std_logic;
    led1_o           : out std_logic;
    led2_o           : out std_logic;
    led3_o           : out std_logic;
    led4_o           : out std_logic;
    led5_o           : out std_logic;
    led6_o           : out std_logic;
    led7_o           : out std_logic
  );
end loopback128gbps;

architecture Behavioral of loopback128gbps is
  ----------------------------
  -- Components
  ----------------------------
  component clk_gen
  port (
    -- Clock in ports
    clk200_i         : in  std_logic;
    -- Clock out ports
    clk_o            : out std_logic;
    clkidelay_o      : out std_logic;
    clkhigh_o        : out std_logic;
    -- Status and control signals
    reset            : in  std_logic;
    locked           : out std_logic
  );
  end component clk_gen;
  
  component generator
  port (
    -- Sys connect
    rst_i            : in  std_logic;
    clk_i            : in  std_logic;
    -- Inputs
    read_i           : in  std_logic;
    -- Outputs
    data_o           : out std_logic_vector(65 downto 0)
  );
  end component generator;
  
  component aurora_tx_lane128
  port (
    -- Sys connect
    rst_i            : in  std_logic;
    clk_i            : in  std_logic;
    clkhigh_i        : in  std_logic;
    -- Inputs
    data66tx_i       : in  std_logic_vector(65 downto 0);
    -- Outputs
    read_o           : out std_logic;
    dataout_p        : out std_logic;
    dataout_n        : out std_logic
  );
  end component;
  
  component aurora_rx_lane
  port (
    -- Sys connect
    rst_n_i          : in std_logic;
    clk_rx_i         : in std_logic;
    clk_serdes_i     : in std_logic;
    -- Input
    rx_data_i_p      : in std_logic;
    rx_data_i_n      : in std_logic;
    -- Output
    rx_data_o        : out std_logic_vector(63 downto 0);
    rx_header_o      : out std_logic_vector(1 downto 0);
    rx_valid_o       : out std_logic;
    rx_stat_o        : out std_logic_vector(7 downto 0)
  );
  end component;
   
  component comparator
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
  end component;
   
  ----------------------------
  -- Signals
  ----------------------------
  signal clk200_s        : std_logic;                        -- 200 MHz clock (FPGA oscillator)
  signal clk_s           : std_logic;                        -- 160 MHz clock (System clock)
  signal clkhigh_s       : std_logic;                        -- 640 MHz clock (Serdes clock)
  signal clkidelay_s     : std_logic;                        -- 300 MHz clock (IDELAYCTRL)
  signal locked_s        : std_logic;                        -- MMCM Locked
  signal read_s          : std_logic;                        -- TX lane Read block
  signal tx_data_s       : std_logic_vector(65 downto 0);    -- TX Header + Block
  signal rx_data_s       : std_logic_vector(63 downto 0);    -- RX Block
  signal rx_header_s     : std_logic_vector(1 downto 0);     -- RX Header
  signal rx_valid_s      : std_logic;                        -- RX valid block flag
  signal rx_stat_s       : std_logic_vector(7 downto 0);     -- RX status
  signal rxdata66_s      : std_logic_vector(65 downto 0);    -- RX Header + Block
  signal ok_s            : std_logic;                        -- Comparator valid sequence flag
  signal idelay_rst_s    : std_logic;                        -- TX Reset (depends on IDELAYCTRL)
  
  ----------------------------
  -- IODELAY 
  ----------------------------
  attribute IODELAY_GROUP: STRING;
  attribute IODELAY_GROUP of IDELAYCTRL_inst : label is "aurora";
  signal idelay_rdy_s    : std_logic;
  
begin

  -- XAPP1017 / RX Lane reset, depends directly on the the IDELAY
  idelay_rst_s <= not(rst_i) and locked_s and idelay_rdy_s;
   
  -- IDELAYCTRL required for XAPP1017
  IDELAYCTRL_inst : IDELAYCTRL
  port map (
    RDY => idelay_rdy_s,      -- 1-bit output: Ready output
    REFCLK => clkidelay_s,    -- 1-bit input: Reference clock input
    RST => rst_i              -- 1-bit input: Active high reset input
  );

  -- IBUFDS for the LVDS input clock
  Map0IBUFDSclk : IBUFDS
  port map (
    O => clk200_s,
    I => clkp_i,
    IB => clkn_i
  );

  -- Clock  generation (IDELAYCTRL, system, serialization)
  Map0clk: clk_gen port map (
    clk200_i => clk200_s,
    clk_o => clk_s,
    clkidelay_o => clkidelay_s,
    clkhigh_o => clkhigh_s,
    reset => rst_i,
    locked => locked_s
  );
  
  -- Data generator (incrementing counter)
  Map1: generator port map (
    rst_i => rst_i,
    clk_i => clk_s,
    read_i => read_s,
    data_o => tx_data_s
  );
  
  -- Aurora 1.28GBps TX Lane
  Map2: aurora_tx_lane128 port map (
    rst_i => rst_i,
    clk_i => clk_s,
    clkhigh_i => clkhigh_s,
    data66tx_i => tx_data_s,
    read_o => read_s,
    dataout_p => dataout_p,
    dataout_n => dataout_n
  );
    
  -- Aurora RX Lane
  Map3: aurora_rx_lane port map (
    rst_n_i => idelay_rst_s, 
    clk_rx_i => clk_s, 
    clk_serdes_i => clkhigh_s, 
    rx_data_i_p => datain_p, 
    rx_data_i_n => datain_n, 
    rx_data_o => rx_data_s, 
    rx_header_o => rx_header_s, 
    rx_valid_o => rx_valid_s, 
    rx_stat_o => rx_stat_s
  );
  
  -- Header and block concatenation
  rxdata66_s <= rx_header_s & rx_data_s;
  
  -- Comparator (validate the counter sequence)
  Map4: comparator port map (
    rst_i => rst_i,
    clk_i => clk_s,
    data66_i => rxdata66_s,
    data66_valid_i => rx_valid_s,
    ok_o => ok_s
  );
  
  -- LED STATUS:
  -- rx_stat_s 2 to 7 --> unused
  -- rx_stat_s(0) --> XAPP1017 lock
  -- rx_stat_s(1) --> RX gearbox synchronized (after 32 valid blocks)
  led0_o <= rx_stat_s(0);
  led1_o <= rx_stat_s(1);
  led2_o <= rx_stat_s(2);
  led3_o <= rx_stat_s(3);
  led4_o <= rx_stat_s(4);
  led5_o <= rx_stat_s(5);
  led6_o <= rx_stat_s(6);
  led7_o <= rx_stat_s(7) or ok_s;
  
end Behavioral;
