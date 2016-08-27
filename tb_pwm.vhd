-- Testbench for power trench module
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;


entity tb_pwm is
 end tb_pwm;

architecture Behavioral of tb_pwm is

 component pwm
 PORT(
       clk       : IN  STD_LOGIC;                                    --system clock
       reset_n   : IN  STD_LOGIC;                                    --asynchronous reset
       ena       : IN  STD_LOGIC;                                    --latches in new duty cycle
       duty      : IN  sfixed(n_left downto n_right);                       --duty cycle (range given by bit resolution)
       pwm_out   : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1');          --pwm outputs
       pwm_n_out : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1'));         --pwm inverse outputs
 END component pwm;
 
 component deadtime_test
          Port ( clk : in STD_LOGIC;
                p_Pwm_In : in STD_LOGIC;
                p_Pwm1_Out : out STD_LOGIC := '1';
                p_Pwm2_Out : out STD_LOGIC := '1');
 end component deadtime_test;
 
 signal clk: STD_LOGIC;
 --signals
 signal pwm_out   : STD_LOGIC_VECTOR(phases-1 DOWNTO 0);        --pwm outputs
 signal pwm_n_out : STD_LOGIC_VECTOR(phases-1 DOWNTO 0);         --pwm inverse outputs
 
 -- Deadtime
 signal p_pwm1_out: std_logic;  --pwm outputs with dead band
 signal p_pwm2_out: std_logic;  --pwm inverse outputs with dead band  
 
begin

pwm_inst: pwm 
 port map(
    clk => clk, 
    reset_n => '1', 
    ena => '1', 
    duty => to_sfixed(0.5,n_left,n_right), 
    pwm_out => pwm_out, 
    pwm_n_out => pwm_n_out);
    
clk_process: process
     begin
                clk <= '0';
                wait for 5 ns;
                clk <= '1';
                wait for 5 ns;  
     end process clk_process;
 
deadtime_inst: deadtime_test  
     port map(
         p_pwm_in => pwm_out(0), 
         clk => clk, 
         p_pwm1_out => p_pwm1_out, 
         p_pwm2_out => p_pwm2_out);
             
end Behavioral;
