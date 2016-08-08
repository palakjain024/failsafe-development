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
           pwm_n_out_t : out STD_LOGIC_VECTOR(phases-1 downto 0)
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
