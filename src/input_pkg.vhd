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
    constant c_Dead_t : integer :=  100;
    
 -- constant inputs
     constant h : sfixed(1 downto -30) := to_sfixed(0.0000005, 1, -30); -- Fixed time step
     constant r : sfixed(1 downto -30) := to_sfixed(-0.082, 1,-30);       -- inductor resistance
    
 -- inputs that could change (keep precison same for all)
     constant v_in : sfixed(15 downto -16)   := to_sfixed(190,15,-16);
     constant v_out : sfixed(15 downto -16)  := to_sfixed(380, 15, -16);
     constant i_load : sfixed(15 downto -16) := to_sfixed(2,15,-16);
    
 -- Initial values of il and vc (Initial state input)
     constant il0 : sfixed(15 downto -16) := to_sfixed(2, 15,-16);
     constant vc0 : sfixed(15 downto -16) := to_sfixed(100,15,-16);
    
  -- theta parameters
     constant L_theta :  sfixed(1 downto -30) := to_sfixed(0.0001, 1, -30);
     constant C_theta :  sfixed(1 downto -30) := to_sfixed(0.0001754386,1, -30);
     
     constant L_theta_min :  sfixed(1 downto -30) := to_sfixed(0.000083, 1, -30);
     constant L_theta_max :  sfixed(1 downto -30) := to_sfixed(0.0005, 1, -30);
     
     constant C_theta_min :  sfixed(1 downto -30) := to_sfixed(0.0001466, 1, -30);
     constant C_theta_max :  sfixed(1 downto -30) := to_sfixed(0.0008772, 1, -30);
     
     constant R_theta_min :  sfixed(1 downto -30) := to_sfixed(-0.0000065, 1, -30); -- Actual: -rmin * L_theta
     constant R_theta_max :  sfixed(1 downto -30) := to_sfixed(-0.000164, 1, -30); -- Actual: -rmax * L_theta
     
    
 -- vectors
     type vect2 is array (0 to 1) of sfixed(15 downto -16); -- for z,u
     type vect6 is array (0 to 5) of sfixed(15 downto -16); -- for augumented [z;u;y]
    
 -- Matrices
     type mat22 is array (0 to 1, 0 to 1) of sfixed(15 downto -16); -- for A,B,L
     type mat26 is array (0 to 1, 0 to 5) of sfixed(1 downto -30);  -- for augumented [A:B:L]
    
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
 
 -- Fd threshold
     constant fd_th : sfixed(15 downto -16) := to_sfixed(4.5, 15, -16); 
      
 -- Address
     constant address_size: integer range 0 to 1000 := 10;
    
end package input_pkg;