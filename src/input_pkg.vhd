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
    constant c_Dead_t : integer :=  100;
    
  -- constant inputs
  constant h : sfixed(0 downto -35) := to_sfixed(0.0000005, 0, -35); -- Fixed time step
    
  -- inputs that could change (keep precison same for all)
  constant v_in : sfixed(15 downto -16)   := to_sfixed(230,15,-16);
  constant r_load : sfixed(15 downto -16) := to_sfixed(0.02,15,-16);
    
  -- Initial values of il and v (Initial state input)
  constant il : sfixed(15 downto -16) := to_sfixed(0, 15,-16);
  constant va01 : sfixed(15 downto -16) := to_sfixed(0.1, 15,-16);
  constant va02 : sfixed(15 downto -16) := to_sfixed(-0.1, 15,-16);
  constant vb0 : sfixed(15 downto -16) := to_sfixed(50, 15,-16);
  constant vc0 : sfixed(15 downto -16) := to_sfixed(-50, 15,-16);
  
  -- Healthy value of Inductor and capacitors for A and B
    constant a1 : sfixed(1 downto -30) := to_sfixed(0.999969644106927,1, -30);
    constant a2 : sfixed(1 downto -30) := to_sfixed(0.000015689646798, 1,-30);
    constant b1 : sfixed(1 downto -30) := to_sfixed(0.000066666666667,1, -30);
    constant b2 : sfixed(1 downto -30) := to_sfixed(-0.000033333333333, 1,-30); 
    constant l1 : sfixed(1 downto -30) := to_sfixed(-0.000010356600000,1, -30);
    constant l2 : sfixed(1 downto -30) := to_sfixed(0.000005690000000, 1,-30); 
    
--    constant a1 : sfixed(1 downto -30) := to_sfixed(0.999980000000000,1, -30);
--    constant a2 : sfixed(1 downto -30) := to_sfixed(0.000010000000000, 1,-30);
--    constant b1 : sfixed(1 downto -30) := to_sfixed(0.000066666666667,1, -30);
--    constant b2 : sfixed(1 downto -30) := to_sfixed(-0.000033333333333, 1,-30); 
--    constant l1 : sfixed(1 downto -30) := to_sfixed(0,1, -30);
--    constant l2 : sfixed(1 downto -30) := to_sfixed(0,1,-30);   
    
  -- Fault limits
  
  
  -- vectors
  type vect3  is array (0 to 2) of sfixed(15 downto -16); -- for z, x
  type vect7  is array (0 to 6) of sfixed(15 downto -16); -- for augumented u
  type vect10  is array (0 to 9) of sfixed(15 downto -16); -- for augumented [z;u;x]
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
  
  -- ADC offset
  constant offset : sfixed(15 downto -16):= to_sfixed(100,15,-16);
  subtype result_type is std_logic_vector (31 downto 0);
  
  -- DAC scaler constants
  constant dac_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
    
end package input_pkg;