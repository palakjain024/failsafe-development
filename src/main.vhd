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
           -- DAC ports
           DA_DATA1 : out STD_LOGIC;
           DA_DATA2 : out STD_LOGIC;
           DA_CLK_OUT : out STD_LOGIC;
           DA_nSYNC : out STD_LOGIC;
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
-- PWM Module
component pwm
    PORT(
        clk       : IN  STD_LOGIC;                                    --system clock
        reset_n   : IN  STD_LOGIC;                                    --asynchronous reset
        ena       : IN  STD_LOGIC;                                    --latches in new duty cycle
        duty      : IN  sfixed(n_left downto n_right);                       --duty cycle
        pwm_out   : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '0');          --pwm outputs
        pwm_n_out : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '0'));          --pwm inverse outputs
end component pwm;
-- Dead Time Module
component deadtime_test
         Port ( clk : in STD_LOGIC;
               p_Pwm_In : in STD_LOGIC;
               p_Pwm1_Out : out STD_LOGIC := '0';
               p_Pwm2_Out : out STD_LOGIC := '0');
end component deadtime_test;
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
-- Signal Definition
-- pwm
signal pwm_out   : STD_LOGIC_VECTOR(phases-1 DOWNTO 0);        --pwm outputs
signal pwm_n_out : STD_LOGIC_VECTOR(phases-1 DOWNTO 0);         --pwm inverse outputs
signal ena : STD_LOGIC := '0';
signal duty_ratio : sfixed(n_left downto n_right);
signal duty : sfixed(n_left downto n_right);

-- Deadtime
signal p_pwm1_out: std_logic;  --pwm outputs with dead band
signal p_pwm2_out: std_logic;  --pwm inverse outputs with dead band  

-- DAC signals         
signal DA_sync: STD_LOGIC;

-- ADC inputs
--signal plt_x : vect2 := (to_sfixed(3,n_left,n_right),to_sfixed(175,n_left,n_right));

-- ADC signals
signal AD_sync_1, AD_sync_2: STD_LOGIC;
signal adc_load, adc_no_use : std_logic_vector(11 downto 0) := (others => '0');
signal adc_vc, adc_il : std_logic_vector(11 downto 0) := (others => '0');

begin

-- PWM and Deadtime module
pwm_inst: pwm 
 port map(
    clk => clk, 
    reset_n => pwm_f, 
    ena => ena, 
    duty => duty, 
    pwm_out => pwm_out, 
    pwm_n_out => pwm_n_out);

deadtime_inst: deadtime_test  
port map(
    p_pwm_in => pwm_out(0), 
    clk => clk, 
    p_pwm1_out => p_pwm1_out, 
    p_pwm2_out => p_pwm2_out);
 
-- ADC and DAC
dac_inst: pmodDA2_ctrl port map (
    CLK => CLK,
    RST => '0', 
    D1 => DA_DATA1, 
    D2 => DA_DATA2, 
    CLK_OUT => DA_CLK_OUT, 
    nSYNC => DA_nSYNC, 
    DATA1 => adc_il, 
    DATA2 => adc_vc, 
    START => DA_sync, 
    DONE => DA_sync);
adc_1_inst: pmodAD1_ctrl port map (
    CLK => CLK,       
    RST => '0',
    SDATA1 => AD_D0_1,
    SDATA2 => AD_D1_1, 
    SCLK   => AD_SCK_1,
    nCS    => AD_CS_1,
    DATA1  => adc_load,    -- Load
    DATA2  => adc_no_use,  -- Not using 
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
        DATA1  => adc_il,  --Inductor current
        DATA2  => adc_vc,  --Capacitor voltage 
        START  => AD_sync_2, 
        DONE   => AD_sync_2
        );    
-- Main loop
main_loop: process (clk)
 begin
     if (clk = '1' and clk'event) then
       pwm_out_t(0) <= p_pwm1_out;
       pwm_n_out_t(0)  <= p_pwm2_out;
      end if;
 end process main_loop;
 
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
