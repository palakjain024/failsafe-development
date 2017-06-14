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
    constant phases          : INTEGER := 3;            --number of output pwms and phases
    
  -- Deadtime
    constant c_Dead_t : integer :=  500;
    
  -- constant inputs
  constant h : sfixed(0 downto -35) := to_sfixed(0.0000005, 0, -35); -- Fixed time step
  constant r : sfixed(1 downto -30) := to_sfixed(-0.82, 1,-30);       -- inductor resistance
  
  -- inputs that could change (keep precison same for all)
  constant v_in : sfixed(15 downto -16)   := to_sfixed(100,15,-16);
  constant r_load : sfixed(15 downto -16) := to_sfixed(3,15,-16);
    
  -- Initial values of il and vc (Initial state input)
  constant il : sfixed(15 downto -16) := to_sfixed(3, 15,-16);
  
  -- Healthy value of Inductor
  constant L_ind :  sfixed(0 downto -35) := to_sfixed(0.005, 0, -35);
    
  -- Fault limits
  
  
  -- vectors
  type vect3 is array (0 to 2) of sfixed(15 downto -16); -- for z, x
  type vect4 is array (0 to 3) of sfixed(15 downto -16); -- for u
  type vect10 is array (0 to 9) of sfixed(15 downto -16); -- for augumented [z;u;x]
  type sine_3p is array (0 to 2) of INTEGER range 0 to 128;
  
  -- Matrices
  type mat310 is array (0 to 2, 0 to 9) of sfixed(1 downto -30); -- for augumented [A:B]
     
  -- Precision
  constant n_left: integer := 15;
  constant n_right: integer := -16;
  constant d_left: integer := 1;
  constant d_right:integer := -30;
  
  -- ADC Descaler constants
  constant vmax : sfixed(15 downto -16):= to_sfixed(3.3,15,-16);
  constant vmin : sfixed(15 downto -16):= to_sfixed(0, 15, -16);
  constant adc_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
  
  -- DAC scaler constants
  constant dac_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
    
end package input_pkg;