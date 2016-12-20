-- Top Module
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;

  
entity main is
    Port ( -- General
           clk : in STD_LOGIC;
           ena : in STD_LOGIC;
           algo_status : out STD_LOGIC;
           -- DAC ports
           DA_DATA1 : out STD_LOGIC;
           DA_DATA2 : out STD_LOGIC;
           DA_CLK_OUT : out STD_LOGIC;
           DA_nSYNC : out STD_LOGIC;
           -- ADC ports 1
           AD_CS_1 : out STD_LOGIC;
           AD_D0_1 : in STD_LOGIC;
           AD_D1_1 : in STD_LOGIC;
           AD_SCK_1 : out STD_LOGIC
          );
end main;

architecture Behavioral of main is

-- Component definitions
-- DAC Module
component pmodDA2_ctrl
     Port ( 
      CLK : in STD_LOGIC;
      RST : in STD_LOGIC;
      D1 : out STD_LOGIC;
      D2 : out STD_LOGIC;
      CLK_OUT : out STD_LOGIC;
      nSYNC : out STD_LOGIC;
      DATA1 : in STD_LOGIC_VECTOR(11 downto 0);
      DATA2 : in STD_LOGIC_VECTOR(11 downto 0);
      START : in STD_LOGIC;
      DONE : out STD_LOGIC
            );
end component;
-- ADC Module
component pmodAD1_ctrl
    Port    (    

    CLK      : in std_logic;         
    RST      : in std_logic;
    SDATA1   : in std_logic;
    SDATA2   : in std_logic;
    SCLK     : out std_logic;
    nCS      : out std_logic;
    DATA1    : out std_logic_vector(11 downto 0);
    DATA2    : out std_logic_vector(11 downto 0);
    START    : in std_logic; 
    DONE     : out std_logic
            );
end component;
-- Descaler for ADC
component descaler
     Generic(
  adc_Factor : sfixed(15 downto -16));
  Port ( clk : in STD_LOGIC;
         start : in STD_LOGIC;
         adc_in : in STD_LOGIC_VECTOR(11 downto 0);
         done : out STD_LOGIC := '0';
         adc_val : out sfixed(n_left downto n_right)
       );
end component; 
-- Scaler for DAC
component scaler
Generic(
    dac_left : integer range -100 to 100;
    dac_right : integer range -100 to 100;
    dac_max : sfixed(n_left downto n_right);
    dac_min : sfixed(n_left downto n_right));
    Port ( clk : in STD_LOGIC;
           dac_in : in sfixed(dac_left downto dac_right);
           dac_val : out STD_LOGIC_VECTOR(11 downto 0));
end component;

-- Processor core
component processor_core
Port ( -- General
       Clk : in STD_LOGIC;
       ena : in STD_LOGIC;
       -- Converter state estimator
       vpv : in sfixed(n_left downto n_right);
       pc_x : in sfixed(n_left downto n_right);
       theta_done : out STD_LOGIC;
       pc_theta : out vect3Q := (theta_L_star,theta_C_star,theta_RC_star);
       pc_err : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       pc_z : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right)
          ); 
end component processor_core;

-- Signal Definition
-- DAC signals         
signal DA_sync: STD_LOGIC;
-- DAC scaler output
signal dac_c: std_logic_vector(11 downto 0);
signal dac_l: std_logic_vector(11 downto 0);

-- ADC Descaler inputs
signal vpv_off, vpv : sfixed(n_left downto n_right);
signal ipv_off, ipv : sfixed(n_left downto n_right);
signal de_done_ipv, de_done_vpv : STD_LOGIC;

-- ADC signals
signal AD_sync_1 : STD_LOGIC;
signal adc_ipv, adc_vpv : std_logic_vector(11 downto 0) := (others => '0');

-- Processor core
signal z_val, err_val : sfixed(n_left downto n_right);
signal pc_theta: vect3Q;
signal theta_done : STD_LOGIC;

begin

-- ADC and DAC
dac_inst: pmodDA2_ctrl port map (
    CLK => CLK,
    RST => '0', 
    D1 => DA_DATA1, 
    D2 => DA_DATA2, 
    CLK_OUT => DA_CLK_OUT, 
    nSYNC => DA_nSYNC, 
    DATA1 => dac_l, 
    DATA2 => dac_C, 
    START => DA_sync, 
    DONE => DA_sync);
adc_1_inst: pmodAD1_ctrl port map (
    CLK => CLK,       
    RST => '0',
    SDATA1 => AD_D0_1,
    SDATA2 => AD_D1_1, 
    SCLK   => AD_SCK_1,
    nCS    => AD_CS_1,
    DATA1  => adc_ipv,  -- PV current
    DATA2  => adc_vpv,  -- PV voltage 
    START  => AD_sync_1, 
    DONE   => AD_sync_1
);
       
-- ADC Retrieval   
de_inst_ipv: descaler generic map (adc_factor => to_sfixed(10,15,-16) )
            port map (
            clk => clk,
            start => AD_sync_1,
            adc_in => adc_ipv,
            done => de_done_ipv,
            adc_val => ipv_off);
de_inst_vpv: descaler generic map (adc_factor => to_sfixed(1,15,-16) )
            port map (
            clk => clk,
            start => AD_sync_1,
            adc_in => adc_vpv,
            done => de_done_vpv,
            adc_val => vpv_off); 
        
-- DAC Scaler       
scaler_theta_l: scaler generic map (
              dac_left => 15,
              dac_right => -16,
              dac_max => to_sfixed(33,15,-16),
              dac_min => to_sfixed(-33,15,-16)
              )
              port map (
              clk => clk,
              dac_in => z_val,  -- For inductor current
              dac_val => dac_l);                  
scaler_theta_c: scaler generic map (
            dac_left => 15,
            dac_right => -16,
            dac_max => to_sfixed(33,15,-16),
            dac_min => to_sfixed(-33,15,-16)
            )
            port map (
            clk => clk,
            dac_in => err_val,  -- For capacitor voltage
            dac_val => dac_c);
            
-- Processor core
pc_inst: processor_core port map (
Clk => Clk,
ena => ena,
vpv => vpv,
pc_x => ipv,
pc_theta => pc_theta,
pc_err => err_val,
pc_z => z_val
);              
-- Main loop
main_loop: process (clk)
 begin
     if (clk = '1' and clk'event) then
        vpv <= resize(vpv_off - to_sfixed(1, n_left, 0), n_left, n_right);
        ipv <= resize(ipv_off - to_sfixed(10, n_left, 0), n_left, n_right);
        algo_status <= ena;
      end if;
 end process main_loop;
 
 
end Behavioral;
