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
    constant c_Dead_t : integer :=  0;
  -- constant inputs
  constant h : sfixed(0 downto -35) := to_sfixed(0.0000005, 0, -35); -- Fixed time step
  constant r : sfixed(1 downto -30) := to_sfixed(-0.82, 1,-30);       -- inductor resistance
  
  -- inputs that could change (keep precison same for all)
  constant v_in : sfixed(15 downto -16)   := to_sfixed(100,15,-16);
  constant v_out : sfixed(15 downto -16)  := to_sfixed(200, 15, -16);
  constant i_load : sfixed(15 downto -16) := to_sfixed(4,15,-16);
  constant f_load : integer := 3141592*2; 
  
  -- Initial values of il and vc (Initial state input)
  constant il0 : sfixed(15 downto -16) := to_sfixed(0, 15,-16);
  constant vc0 : sfixed(15 downto -16) := to_sfixed(377,15,-16);
  
  -- theta_star parameters
  constant L_star :  sfixed(0 downto -35) := to_sfixed(0.005, 0, -35);
  constant C_star :  sfixed(0 downto -35) := to_sfixed(0.0001, 0, -35);
  constant theta_L_star : sfixed(15 downto -16) := to_sfixed(200, 15, -16);
  constant theta_C_star : sfixed(15 downto -16):= to_sfixed(10000, 15, -16);
  constant theta_C_init : sfixed(15 downto -16):= to_sfixed(6667, 15, -16);
  -- Adaptive Gain for theta correction
  constant e11 : sfixed(24 downto -10) := to_sfixed(-0.1,24,-10);
  constant e22 : sfixed(24 downto -10) := to_sfixed(-3e6,24,-10);
  type gain_mat is array (0 to 1, 0 to 1) of sfixed(24 downto -10);
  
  -- vectors
  type vect2 is array (0 to 1) of sfixed(15 downto -16); -- for z,u
  type vect4 is array (0 to 3) of sfixed(15 downto -16); -- for augumented [z;u]
  type discrete_vect2 is array (0 to 1) of sfixed(0 downto -35);
  
  -- Matrices
  type mat22 is array (0 to 1, 0 to 1) of sfixed(15 downto -16); -- for A,B
  type mat24 is array (0 to 1, 0 to 3) of sfixed(0 downto -35);  -- for augumented [A:B]
  type discrete_mat22 is array (0 to 1, 0 to 1) of sfixed(0 downto -35); -- for w
  type H_mat22 is array (0 to 1, 0 to 1) of sfixed(2 downto -35); -- for H
  -- Precision
  constant n_left: integer := 15;
  constant n_right: integer := -16;
  constant d_left: integer := 0;
  constant d_right:integer := -35;
  
  -- ADC Descaler constants
  constant vmax : sfixed(15 downto -16):= to_sfixed(3.3,15,-16);
  constant vmin : sfixed(15 downto -16):= to_sfixed(0, 15, -16);
  constant adc_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
  
  -- DAC scaler constants
  constant dac_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
  
  -- Fault Identification
  type ip_array is array (0 to 1) of sfixed(15 downto -16);
  
  -- Address
  constant address_size: integer range 0 to 1000 := 10;
    
end package input_pkg;