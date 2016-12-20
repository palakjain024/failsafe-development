-- Inputs to parameter estimator
library IEEE;
library IEEE_proposed;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.STD_LOGIC_1164.ALL;

package input_pkg is

  -- constant inputs
  constant h : sfixed(0 downto -35) := to_sfixed(0.0000005, 0, -35); -- Fixed time step
  constant r : sfixed(1 downto -30) := to_sfixed(-0.05, 1,-30);       -- inductor resistance
  
    
  -- Initial values of il and vc (Initial state input)
  constant il0 : sfixed(15 downto -16) := to_sfixed(0, 15,-16);
  constant vc0 : sfixed(15 downto -16) := to_sfixed(0,15,-16);
  
  -- theta_star parameters
  constant L_star :  sfixed(0 downto -35) := to_sfixed(0.0000000794, 0, -35);
  constant C_star :  sfixed(0 downto -35) := to_sfixed(0.0004, 0, -35);
  constant R_star :  sfixed(0 downto -35) := to_sfixed(0.25, 0, -35);
  constant theta_L_star : sfixed(29 downto -2) := to_sfixed(1.26e7, 29, -2);
  constant theta_C_star : sfixed(29 downto -2):= to_sfixed(2.5e3, 29, -2);
  constant theta_RC_star : sfixed(29 downto -2):= to_sfixed(1e4, 29, -2);
  
  -- Adaptive Gain for theta correction, these gains are multiplied by h 
  -- (see theta(:,n)  = theta(:,n-1)  + ((h*-G) * (H_est'*e(:,n)))
  constant e11 : sfixed(29 downto -2) := to_sfixed(0.01,29,-2);
  constant e22 : sfixed(29 downto -2) := to_sfixed(1e3,29,-2);
  constant e33 : sfixed(29 downto -2) := to_sfixed(5e3,29,-2);
  constant e00 : sfixed(29 downto -2) := to_sfixed(0,29,-2);
  type gain_mat is array (0 to 2) of sfixed(29 downto -2);
  
  -- vectors
  type vect2 is array (0 to 1) of sfixed(15 downto -16); -- for z,u
  type vect3 is array (0 to 2) of sfixed(15 downto -16); -- for g_h_err, h_err
  type vect3Q is array (0 to 2) of sfixed(29 downto -2); -- for theta
  type vect3H is array (0 to 2) of sfixed(5 downto -26); -- for H
  type vect4 is array (0 to 3) of sfixed(15 downto -16); -- for augumented [z;u]
 
  
  -- Matrices
  type mat22 is array (0 to 1, 0 to 1) of sfixed(15 downto -16); -- for A,B
  type mat24 is array (0 to 1, 0 to 3) of sfixed(5 downto -26);  -- for augumented [A:B]
  type discrete_mat23 is array (0 to 1, 0 to 2) of sfixed(5 downto -26); -- for w
  type L_mat23 is array (0 to 1, 0 to 2) of sfixed(10 downto -21); -- for L
    
  -- Precision
  constant n_left: integer := 15;
  constant n_right: integer := -16;
  constant d_left: integer := 5;
  constant d_right:integer := -26;
  constant lmat_left: integer := 10;
  constant lmat_right: integer := -21;
  
  -- ADC Descaler constants
  constant vmax : sfixed(15 downto -16):= to_sfixed(3.3,15,-16);
  constant vmin : sfixed(15 downto -16):= to_sfixed(0, 15, -16);
  constant adc_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
  
  -- DAC scaler constants
  constant dac_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
   
end package input_pkg;