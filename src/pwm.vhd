-- PWM Module
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;


ENTITY pwm IS
  PORT(
      clk       : IN  STD_LOGIC;                                    -- system clock
      reset_n   : IN  STD_LOGIC;                                    -- asynchronous reset
      pwm_out_t   : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1');    --pwm outputs
      pwm_n_out_t : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1'));   --pwm inverse outputs
END pwm;

architecture Behavioral of pwm is
-- Component definition

-- Sine and Triangular waveform generation
Component waveform_synthesis is
 port(
      clk       : IN  STD_LOGIC;   
      sine_ref  : OUT sine_3p;
      ctrl_freq : OUT INTEGER range 0 to 200 := 0
      );
end component waveform_synthesis;

-- Dead Time Module
component deadtime_test
         Port ( clk : in STD_LOGIC;
               p_Pwm_In : in STD_LOGIC;
               p_Pwm1_Out : out STD_LOGIC := '0';
               p_Pwm2_Out : out STD_LOGIC := '0');
end component deadtime_test;

-- signal definition
signal sine_ref : sine_3p;
signal ctrl_freq : INTEGER RANGE 0 to 200 := 0;
signal pwm_out   : STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1');    --pwm outputs
signal pwm_n_out : STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1');   --pwm inverse outputs
      
      
begin

deadtime_inst_0: deadtime_test  
port map(
    p_pwm_in => pwm_out(0), 
    clk => clk, 
    p_pwm1_out => pwm_out_t(0), 
    p_pwm2_out => pwm_n_out_t(0));
    

deadtime_inst_1: deadtime_test  
port map(
    p_pwm_in => pwm_out(1), 
    clk => clk, 
    p_pwm1_out => pwm_out_t(1), 
    p_pwm2_out => pwm_n_out_t(1));
    
deadtime_inst_2: deadtime_test  
    port map(
        p_pwm_in => pwm_out(2), 
        clk => clk, 
        p_pwm1_out => pwm_out_t(2), 
        p_pwm2_out => pwm_n_out_t(2));

ws_inst: waveform_synthesis
            PORT MAP (
                  clk => clk,   
                  sine_ref => sine_ref,
                  ctrl_freq => ctrl_freq
                    );
                    
pwm_gen_process: PROCESS(clk, reset_n)
 begin
    if (clk'EVENT AND clk = '1') THEN   
       
       -- synchronous reset 
        IF(reset_n = '0') THEN                                                   
          pwm_out <= (OTHERS => '1');                                            -- clear pwm outputs
          pwm_n_out <= (OTHERS => '1');  
       
       -- PWM generation   
        ELSE
   
         
                 FOR i IN 0 to phases-1 LOOP    
                    
                    IF sine_ref(i) >= ctrl_freq THEN
                    
                    pwm_out(i) <= '1';                                                     --assert the pwm output
                    pwm_n_out(i) <= '0';                                                   --deassert the pwm inverse output
                    
                    ELSE
                    
                    pwm_out(i) <= '0';                                                     --deassert the pwm output
                    pwm_n_out(i) <= '1';                                                   --assert the pwm inverse output
                    
                    END IF;
                   
                 END LOOP; 
         END IF;
    end if;
 end process;
end Behavioral;
