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
           pwm_f: in STD_LOGIC;
           -- PWM ports
           pwm_out_t : out STD_LOGIC_VECTOR(phases-1 downto 0);
           pwm_n_out_t : out STD_LOGIC_VECTOR(phases-1 downto 0);
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
-- PWM Module
component pwm_dc
    PORT(
        clk       : IN  STD_LOGIC;                                    --system clock
        reset_n   : IN  STD_LOGIC;                                    --asynchronous reset
        ena       : IN  STD_LOGIC;                                    --latches in new duty cycle
        duty      : IN  sfixed(n_left downto n_right);                       --duty cycle
        pwm_out   : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '0');          --pwm outputs
        pwm_n_out : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '0'));          --pwm inverse outputs
end component pwm_dc;
-- Dead Time Module
component deadtime
         Port ( clk : in STD_LOGIC;
               p_Pwm_In : in STD_LOGIC;
               p_Pwm1_Out : out STD_LOGIC := '0';
               p_Pwm2_Out : out STD_LOGIC := '0');
end component deadtime;
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
       -- Observer inputs
       pc_pwm : in STD_LOGIC_VECTOR(phases-1 downto 0);
       load : in sfixed(n_left downto n_right);
       pc_y : in vect2;
       -- FD logic
       FD_residual_out : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       pc_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
       );
end component processor_core;

-- Signal Definition
-- pwm
signal pwm_out   : STD_LOGIC_VECTOR(phases-1 DOWNTO 0);        --pwm outputs
signal pwm_n_out : STD_LOGIC_VECTOR(phases-1 DOWNTO 0);         --pwm inverse outputs
signal ena : STD_LOGIC := '0';
signal duty_ratio : sfixed(n_left downto n_right);
signal duty : sfixed(n_left downto n_right);


-- Deadtime
signal a_pwm1_out, b_pwm1_out: std_logic;  --pwm outputs with dead band
signal a_pwm2_out, b_pwm2_out: std_logic;  --pwm inverse outputs with dead band  

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
-- Processor core
signal pc_pwm : STD_LOGIC_VECTOR(phases-1 downto 0);
signal FD_residual:  sfixed(n_left downto n_right);
signal z_val : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
signal plt_y : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));

begin
-- ILA
-- Clk
-- PWM and Deadtime module
pwm_inst: pwm_dc 
 port map(
    clk => clk, 
    reset_n => '1', 
    ena => ena, 
    duty => duty, 
    pwm_out => pwm_out, 
    pwm_n_out => pwm_n_out);

deadtime_a_inst: deadtime  
port map(
    p_pwm_in => pwm_out(0), 
    clk => clk, 
    p_pwm1_out => a_pwm1_out, 
    p_pwm2_out => a_pwm2_out);
    
deadtime_b_inst: deadtime  
    port map(
        p_pwm_in => pwm_out(1), 
        clk => clk, 
        p_pwm1_out => b_pwm1_out, 
        p_pwm2_out => b_pwm2_out);
    
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
            adc_val => adc_out_1(0)); -- Inductor current
de_inst_2: descaler generic map (adc_factor => v_factor)
            port map (
            clk => clk,
            start => AD_sync_1,
            adc_in => adc_2,
            done => de_done_2,
            adc_val => adc_out_1(1));  --capacitor voltage
de_inst_3: descaler generic map (adc_factor => i_factor)
            port map (
            clk => clk,
            start => AD_sync_2,
            adc_in => adc_3,
            done => de_done_3,
            adc_val => adc_out_2(0)); -- load
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
              dac_max => to_sfixed(33,15,-16),
              dac_min => to_Sfixed(0,15,-16)
              )
              port map (
              clk => clk,
              dac_in => z_val(0),  
              dac_val => dac_1);                  
scaler_2: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(660,15,-16),
            dac_min => to_sfixed(0,15,-16)
            )
            port map (
            clk => clk,
            dac_in => z_val(1),  
            dac_val => dac_2); 
scaler_3: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(660,15,-16),
            dac_min => to_sfixed(0,15,-16)
            )
            port map (
            clk => clk,
            dac_in => adc_out_1(1),  
            dac_val => dac_3); 
scaler_4: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(33,15,-16),
            dac_min => to_sfixed(0,15,-16)
            )
            port map (
            clk => clk,
            dac_in => adc_out_2(0),  
            dac_val => dac_4); 


-- Processor_core
pc_inst: processor_core port map (
            Clk => clk,
            pc_pwm => pc_pwm,
            load => adc_out_2(0),
            pc_y => plt_y,
            FD_residual_out => FD_residual,
            pc_z => z_val);
            
main_loop: process (clk)
begin
if (clk = '1' and clk'event) then
-- Output
pwm_out_t(0) <= a_pwm1_out;
pwm_n_out_t(0)  <= a_pwm2_out;
pwm_out_t(1) <= b_pwm1_out;
pwm_n_out_t(1)  <= b_pwm2_out;

-- Processor core
pc_pwm(0) <= a_pwm1_out;
pc_pwm(1) <= b_pwm1_out;
plt_y(0) <= adc_out_1(0);
plt_y(1) <= adc_out_1(1);

end if;
end process; 

-- duty cycle cal
duty_cycle_uut: process (clk)

type state_variable is (S0, S1);
variable state: state_variable := S0;

begin
   if (clk = '1' and clk'event) then
      case state is

       when S0 =>
       ena <= '0';
       duty_ratio <= resize(v_in/v_out, n_left, n_right);
       state := S1;
       
       when S1 =>
       ena <= '1';
       duty <= resize(to_sfixed(1, n_left, n_right) - duty_ratio, n_left, n_right);
       state := S0;  
       end case;  
     end if;
end process;

end Behavioral;
