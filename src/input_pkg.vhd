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
    constant phases          : INTEGER := 2;            --number of output pwms and phases
  -- Deadtime
    constant c_Dead_t : integer :=  100;
    
  -- constant inputs
  constant h : sfixed(1 downto -30) := to_sfixed(0.0000005, 1, -30); -- Fixed time step
  constant esr: sfixed(1 downto -30) := to_sfixed(0.038,1,-30);
  constant fd_th : sfixed(15 downto -16) := to_sfixed(1.2, 15, -16);
  
  -- inputs that could change (keep precison same for all)
  constant v_in : sfixed(15 downto -16)   := to_sfixed(190,15,-16);
  constant v_out : sfixed(15 downto -16)  := to_sfixed(380, 15, -16);
  constant i_load : sfixed(15 downto -16) := to_sfixed(3,15,-16);
  
  -- Initial values of il and vc (Initial state input)
  constant il0 : sfixed(15 downto -16) := to_sfixed(4, 15,-16);
  constant vc0 : sfixed(15 downto -16) := to_sfixed(380,15,-16);
  constant zer0 : sfixed(15 downto -16) := to_sfixed(0, 15,-16);
  
  -- theta_star parameters
  constant Ltheta_star :  sfixed(15 downto -16) := to_sfixed(200, 15, -16);
  constant Ctheta_star :  sfixed(15 downto -16) := to_sfixed(350.87, 15, -16);
  
  -- Adaptive Gain for theta correction
  
  -- vectors
  type vect3 is array (0 to 2) of sfixed(15 downto -16); -- for z
  type vect2 is array (0 to 1) of sfixed(15 downto -16); -- for y, u
  type vect7 is array (0 to 6) of sfixed(15 downto -16); -- for augumented [z;u;y]
  
  -- Matrices
  type mat37 is array (0 to 2, 0 to 6) of sfixed(1 downto -30);  -- for augumented [A:B:L]
  
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
  constant v_factor : sfixed(15 downto -16) := to_sfixed(200, 15, -16);
  
  -- DAC scaler constants
  constant dac_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
  
end package input_pkg;