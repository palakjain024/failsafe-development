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
           -- DAC ports 1
           DA_DATA1_1 : out STD_LOGIC;
           DA_DATA2_1 : out STD_LOGIC;
           DA_CLK_OUT_1 : out STD_LOGIC;
           DA_nSYNC_1 : out STD_LOGIC;
           -- DAC ports 2
           DA_DATA1_2 : out STD_LOGIC;
           DA_DATA2_2 : out STD_LOGIC;
           DA_CLK_OUT_2 : out STD_LOGIC;
           DA_nSYNC_2 : out STD_LOGIC;
           -- ADC ports 1
           AD_CS_1 : out STD_LOGIC;
           AD_D0_1 : in STD_LOGIC;
           AD_D1_1 : in STD_LOGIC;
           AD_SCK_1 : out STD_LOGIC;
           -- ADC ports 2
           AD_CS_2 : out STD_LOGIC;
           AD_D0_2 : in STD_LOGIC;
           AD_D1_2 : in STD_LOGIC;
           AD_SCK_2 : out STD_LOGIC;
          -- ADC ports 3
           AD_CS_3 : out STD_LOGIC;
           AD_D0_3 : in STD_LOGIC;
           AD_D1_3 : in STD_LOGIC;
           AD_SCK_3 : out STD_LOGIC
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


-- Signal Definition

-- DAC signals         
signal DA_sync_1, DA_sync_2: STD_LOGIC;
-- DAC scaler output
signal dac_1, dac_2, dac_3, dac_4: std_logic_vector(11 downto 0);


-- ADC Descaler inputs
signal adc_out_1, adc_out_2, adc_out_3: vect2 := (to_sfixed(3,n_left,n_right),to_sfixed(175,n_left,n_right));
signal de_done_1, de_done_2, de_done_3, de_done_4, de_done_5, de_done_6 : STD_LOGIC;
-- ADC signals
signal AD_sync_1, AD_sync_2, AD_sync_3: STD_LOGIC;
signal adc_1, adc_2, adc_3, adc_4, adc_5, adc_6: std_logic_vector(11 downto 0) := (others => '0');

begin

-- ILA


-- Clk

-- ADC and DAC
dac_1_inst: pmodDA2_ctrl port map (
    CLK => CLK,
    RST => '0', 
    D1 => DA_DATA1_1, 
    D2 => DA_DATA2_1, 
    CLK_OUT => DA_CLK_OUT_1, 
    nSYNC => DA_nSYNC_1, 
    DATA1 => dac_1, 
    DATA2 => dac_2, 
    START => DA_sync_1, 
    DONE => DA_sync_1);

dac_2_inst: pmodDA2_ctrl port map (
    CLK => CLK,
    RST => '0', 
    D1 => DA_DATA1_2, 
    D2 => DA_DATA2_2, 
    CLK_OUT => DA_CLK_OUT_2, 
    nSYNC => DA_nSYNC_2, 
    DATA1 => dac_3, 
    DATA2 => dac_4, 
    START => DA_sync_2, 
    DONE => DA_sync_2);
    
adc_1_inst: pmodAD1_ctrl port map (
    CLK => CLK,       
    RST => '0',
    SDATA1 => AD_D0_1,
    SDATA2 => AD_D1_1, 
    SCLK   => AD_SCK_1,
    nCS    => AD_CS_1,
    DATA1  => adc_1,    
    DATA2  => adc_2,  
    START  => AD_sync_1, 
    DONE   => AD_sync_1
);

adc_2_inst: pmodAD1_ctrl port map (
        CLK => CLK,       
        RST => '0',
        SDATA1 => AD_D0_2,
        SDATA2 => AD_D1_2, 
        SCLK   => AD_SCK_2,
        nCS    => AD_CS_2,
        DATA1  => adc_3,  
        DATA2  => adc_4,   
        START  => AD_sync_2, 
        DONE   => AD_sync_2
        );  

adc_3_inst: pmodAD1_ctrl port map (
        CLK => CLK,       
        RST => '0',
        SDATA1 => AD_D0_3,
        SDATA2 => AD_D1_3, 
        SCLK   => AD_SCK_3,
        nCS    => AD_CS_3,
        DATA1  => adc_5,  
        DATA2  => adc_6, 
        START  => AD_sync_3, 
        DONE   => AD_sync_3
        ); 
               
-- ADC Retrieval   
de_inst_1: descaler generic map (adc_factor => i_factor )
            port map (
            clk => clk,
            start => AD_sync_1,
            adc_in => adc_1,
            done => de_done_1,
            adc_val => adc_out_1(0));
de_inst_2: descaler generic map (adc_factor => v_factor)
            port map (
            clk => clk,
            start => AD_sync_1,
            adc_in => adc_2,
            done => de_done_2,
            adc_val => adc_out_1(1)); 
de_inst_3: descaler generic map (adc_factor => i_factor)
            port map (
            clk => clk,
            start => AD_sync_2,
            adc_in => adc_3,
            done => de_done_3,
            adc_val => adc_out_2(0));
de_inst_4: descaler generic map (adc_factor => v_factor)
            port map (
            clk => clk,
            start => AD_sync_2,
            adc_in => adc_4,
            done => de_done_4,
            adc_val => adc_out_2(1)); 
de_inst_5: descaler generic map (adc_factor => i_factor)
            port map (
            clk => clk,
            start => AD_sync_3,
            adc_in => adc_5,
            done => de_done_5,
            adc_val => adc_out_3(0));
de_inst_6: descaler generic map (adc_factor => v_factor)
            port map (
            clk => clk,
            start => AD_sync_3,
            adc_in => adc_6,
            done => de_done_6,
            adc_val => adc_out_3(1));           
-- DAC Scaler       
scaler_1: scaler generic map (
              dac_left => n_left,
              dac_right => n_right,
              dac_max => to_sfixed(1.66,15,-16),
              dac_min => to_Sfixed(-1.66,15,-16)
              )
              port map (
              clk => clk,
              dac_in => adc_out_1(0),  
              dac_val => dac_1);                  
scaler_2: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(1.66,15,-16),
            dac_min => to_sfixed(-1.66,15,-16)
            )
            port map (
            clk => clk,
            dac_in => adc_out_1(1),  
            dac_val => dac_2); 
scaler_3: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(1.66,15,-16),
            dac_min => to_sfixed(-1.66,15,-16)
            )
            port map (
            clk => clk,
            dac_in => adc_out_3(0),  
            dac_val => dac_3); 
scaler_4: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(1.66,15,-16),
            dac_min => to_sfixed(-1.66,15,-16)
            )
            port map (
            clk => clk,
            dac_in => adc_out_3(1),  
            dac_val => dac_4); 
            
--main_loop: process (clk)
--begin
--if (clk = '1' and clk'event) then
--p_adc1 <= result_type(adc_out_1(0)); 
--end if;
--end process; 

end Behavioral;
