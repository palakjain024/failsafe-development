-- Top Module

library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.input_pkg.all;

  
entity main is
    Port ( -- General
           clk : in STD_LOGIC;
           pwm_f: in STD_LOGIC;
           -- PWM ports
           pwm_out_t : out STD_LOGIC_VECTOR(phases-1 downto 0);
           pwm_n_out_t : out STD_LOGIC_VECTOR(phases-1 downto 0);
           -- Flags
           FD_flag : out STD_LOGIC;
           reset_fd : in STD_LOGIC;
           -- DAC ports 1
           DA_DATA1 : out STD_LOGIC;
           DA_DATA2 : out STD_LOGIC;
           DA_CLK_OUT_1 : out STD_LOGIC;
           DA_nSYNC_1 : out STD_LOGIC;
           -- DAC ports 2
           DA_DATA3 : out STD_LOGIC;
           DA_DATA4 : out STD_LOGIC;
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
           AD_SCK_2 : out STD_LOGIC
         );
end main;

architecture Behavioral of main is

-- Component definitions

-- PWM and DEADTIME Module
COMPONENT pwm IS
 PORT(
     clk       : IN  STD_LOGIC;                                                -- system clock
     reset_n   : IN  STD_LOGIC;                                                -- synchronous reset
     pwm_out_t   : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1'); -- pwm outputs
     pwm_n_out_t : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1')  -- pwm inverse outputs
     );   
END COMPONENT pwm;

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
       -- Converter fault flag;
       FD_flag : out STD_LOGIC := '0';
       -- Converter state estimator
       pc_pwm : in STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1');
       pc_x : in vect3;
       pc_z : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right))
          );   
end component processor_core;

-------------- Signal Definition -------------
-- PWM
signal pwm_out   : STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1');   -- pwm outputs
signal pwm_n_out : STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1');   -- pwm inverse outputs

-- DAC signals         
signal DA_sync1: STD_LOGIC;
signal DA_sync2: STD_LOGIC;

-- DAC scaler output
signal dac_1: std_logic_vector(11 downto 0);
signal dac_2: std_logic_vector(11 downto 0);
signal dac_3: std_logic_vector(11 downto 0);
signal dac_4: std_logic_vector(11 downto 0);

-- ADC Descaler inputs
signal plt_x : vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
signal plt_x_raw : vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
signal de_done_1, de_done_2, de_done_3, de_done_4 : STD_LOGIC;

-- ADC signals
signal AD_sync_1, AD_sync_2: STD_LOGIC;
signal adc_1, adc_2 : std_logic_vector(11 downto 0) := (others => '0');
signal adc_3, adc_4 : std_logic_vector(11 downto 0) := (others => '0');

-- Processor core
signal z_val : vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));

begin

-- PWM and Deadtime module
pwm_instance: pwm
  PORT MAP(
        clk => clk,
        reset_n => '1',
        pwm_out_t => pwm_out,
        pwm_n_out_t => pwm_n_out);
      
-- DAC
dac_1_inst: pmodDA2_ctrl port map (
        CLK => CLK,
        RST => '0', 
        D1 => DA_DATA1, 
        D2 => DA_DATA2, 
        CLK_OUT => DA_CLK_OUT_1, 
        nSYNC => DA_nSYNC_1, 
        DATA1 => dac_1, 
        DATA2 => dac_2, 
        START => DA_sync1, 
        DONE => DA_sync1);
dac_2_inst: pmodDA2_ctrl port map (
        CLK => CLK,
        RST => '0', 
        D1 => DA_DATA3, 
        D2 => DA_DATA4, 
        CLK_OUT => DA_CLK_OUT_2, 
        nSYNC => DA_nSYNC_2, 
        DATA1 => dac_3, 
        DATA2 => dac_4, 
        START => DA_sync2, 
        DONE => DA_sync2);
        
-- ADC
adc_1_inst: pmodAD1_ctrl port map (
        CLK => CLK,       
        RST => '0',
        SDATA1 => AD_D0_1,
        SDATA2 => AD_D1_1, 
        SCLK   => AD_SCK_1,
        nCS    => AD_CS_1,
        DATA1  => adc_1, -- Ia3    
        DATA2  => adc_2, -- no use
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
        DATA1  => adc_3, -- Ia1
        DATA2  => adc_4, -- Ia2
        START  => AD_sync_2, 
        DONE   => AD_sync_2
        );  
            
-- ADC Retrieval
de_inst_1: descaler generic map (adc_factor => to_sfixed(10,15,-16) )
            port map (
            clk => clk,
            start => AD_sync_1,
            adc_in => adc_3,
            done => de_done_1,
            adc_val => plt_x_raw(0));
de_inst_2: descaler generic map (adc_factor => to_sfixed(10,15,-16) )
            port map (
            clk => clk,
            start => AD_sync_2,
            adc_in => adc_4,
            done => de_done_2,
            adc_val => plt_x_raw(1));
de_inst_3: descaler generic map (adc_factor => to_sfixed(10,15,-16) )
            port map (
            clk => clk,
            start => AD_sync_2,
            adc_in => adc_1,
            done => de_done_3,
            adc_val => plt_x_raw(2));   
            
-- DAC Scaler       
scaler_theta_1: scaler generic map (
              dac_left => n_left,
              dac_right => n_right,
              dac_max => to_sfixed(16.5,15,-16),
              dac_min => to_Sfixed(-16.5,15,-16)
              )
              port map (
              clk => clk,
              dac_in => z_val(0), 
              dac_val => dac_1);                  
scaler_theta_2: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(16.5,15,-16),
            dac_min => to_sfixed(-16.5,15,-16)
            )
            port map (
            clk => clk,
            dac_in => z_val(1),  
            dac_val => dac_2);
scaler_theta_3: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(16.5,15,-16),
            dac_min => to_sfixed(-16.5,15,-16)
            )
            port map (
            clk => clk,
            dac_in => z_val(2), 
            dac_val => dac_3);
scaler_theta_4: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(16.5,15,-16),
            dac_min => to_sfixed(-16.5,15,-16)
            )
            port map (
            clk => clk,
            dac_in => plt_x(0), 
            dac_val => dac_4);
                
              
-- Main loop
main_loop: process (clk)
 begin
     if (clk = '1' and clk'event) then
     
           
             -- ADC offsets
              plt_x(0) <= resize(plt_x_raw(0) - offset, n_left, n_right);
              plt_x(1) <= resize(plt_x_raw(1) - offset, n_left, n_right);
              plt_x(2) <= resize(plt_x_raw(2) - offset, n_left, n_right);
              
             -- PWM output
             if pwm_f = '0' then
               pwm_out_t <= pwm_out;
               pwm_n_out_t  <= pwm_n_out;
             else
               pwm_out_t(0) <= '1';
               pwm_n_out_t(0)  <= '1';
               pwm_out_t(1) <= '1';
               pwm_n_out_t(1)  <= '1';
               pwm_out_t(2) <= '1';
               pwm_n_out_t(2)  <= '1';
             end if;                                 
 
      end if;
 end process main_loop;
 
 -- Processor core
pc_instance: processor_core port map (
                Clk => clk,
                FD_flag => FD_flag,
                pc_pwm => pwm_out,
                pc_x => plt_x,
                pc_z => z_val);
                
    
end Behavioral;
