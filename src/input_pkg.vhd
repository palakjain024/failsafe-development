-- Inputs to parameter estimator
library IEEE;
library IEEE_proposed;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.STD_LOGIC_1164.ALL;

package input_pkg is

  -- PWM parameters
  constant sys_clk         : INTEGER := 100_000_000;  --system clock frequency in Hz
  constant pwm_freq        : INTEGER := 10_000;       --PWM switching frequency in Hz
  constant bits_resolution : INTEGER := 8;            --bits of resolution setting the duty cycle
  constant phases          : INTEGER := 1;            --number of output pwms and phases
  -- Deadtime
  constant c_Dead_t        : INTEGER :=  200;         -- Dead time
    
  -- constant inputs
  constant h : sfixed(1 downto -30) := to_sfixed(0.0000005, 1, -30); -- Fixed time step
  constant rL : sfixed(1 downto -30) := to_sfixed(-0.082,1,-30);      -- Inductor resistance
  constant fd_th : sfixed(15 downto -16) := to_sfixed(0.4, 15, -16); -- Threshold
  
  -- inputs that could change (keep precison same for all)
  constant v_in : sfixed(15 downto -16)   := to_sfixed(190,15,-16);
  constant v_out : sfixed(15 downto -16)  := to_sfixed(380, 15, -16);
  constant i_load : sfixed(15 downto -16) := to_sfixed(2,15,-16);
  
  -- Initial values of il, vc (Initial state input)
  constant il0 : sfixed(15 downto -16) := to_sfixed(0, 15,-16);
  constant vc0 : sfixed(15 downto -16) := to_sfixed(400,15,-16);
 
  -- Zero initial input
  constant zer0 : sfixed(15 downto -16) := to_sfixed(0, 15,-16);
  constant zer0h : sfixed(1 downto -30) := to_sfixed(0, 1,-30);
  constant zer0_H_mat : sfixed(7 downto -24) := to_sfixed(0, 7,-24);  -- H_mat22 initial values
  
 -- theta_star parameters
  constant L_star :  sfixed(1 downto -30) := to_sfixed(0.005, 1, -30);
  constant C_star :  sfixed(1 downto -30) := to_sfixed(0.00285, 1, -30);
  constant theta_L_star : sfixed(15 downto -16) := to_sfixed(200, 15, -16);
  constant theta_C_star : sfixed(15 downto -16):= to_sfixed(350.877, 15, -16);
    
 -- Adaptive Gain for theta correction (descretized gain)
 constant e11 : sfixed(1 downto -30) := to_sfixed(-0.0001,1,-30);
 constant e22 : sfixed(1 downto -30) := to_sfixed(-0.0001,1,-30);
 type gain_mat is array (0 to 1, 0 to 1) of sfixed(1 downto -30);
 
 -- Luneberger oberver gain
  constant l11 : sfixed(1 downto -30) := to_sfixed(0.00001160310000,1,-30);
  constant l12 : sfixed(1 downto -30) := to_sfixed(0.00000093635000,1,-30);
  constant l21 : sfixed(1 downto -30) := to_sfixed(0.00000154145000,1,-30);
  constant l22 : sfixed(1 downto -30) := to_sfixed(0.00002495015000,1,-30);
      
 -- vectors
 type vect2 is array (0 to 1) of sfixed(15 downto -16); -- for z,u
 type vect4 is array (0 to 3) of sfixed(15 downto -16); -- for augumented [z;u]
 type discrete_vect2 is array (0 to 1) of sfixed(1 downto -30);
    
 -- Matrices
 type mat22 is array (0 to 1, 0 to 1) of sfixed(15 downto -16); -- for A,B
 type mat24 is array (0 to 1, 0 to 3) of sfixed(1 downto -30);  -- for augumented [A:B]
 type discrete_mat22 is array (0 to 1, 0 to 1) of sfixed(1 downto -30); -- for w
 type H_mat22 is array (0 to 1, 0 to 1) of sfixed(7 downto -24); -- for H
    
 -- Precision
 constant n_left: integer := 15;
 constant n_right: integer := -16;
 constant d_left: integer := 1;
 constant d_right:integer := -30;
  
  -- ILA
  subtype result_type is std_logic_vector (31 downto 0);
  
  -- ADC Descaler constants
  constant vmax : sfixed(15 downto -16):= to_sfixed(3.3,15,-16);
  constant vmin : sfixed(15 downto -16):= to_sfixed(0, 15, -16);
  constant adc_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
  constant offset : sfixed(15 downto -16) := to_sfixed(0, 15, -16);
  constant i_factor : sfixed(15 downto -16) := to_sfixed(10, 15, -16);
  constant v_factor : sfixed(15 downto -16) := to_sfixed(1000, 15, -16);
  
  -- DAC scaler constants
  constant dac_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
  
end package input_pkg;