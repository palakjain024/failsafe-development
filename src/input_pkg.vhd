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
  constant c_Dead_t        : INTEGER :=  100;         -- Dead time
   
  -- Mode of operation
  constant buck : STD_LOGIC := '0';
  constant boost : STD_LOGIC := '1';
  constant passthrough : STD_LOGIC := '0';
  
 -- Matrix discretization
 constant a00d : sfixed(1 downto -30) := to_sfixed(0.999900000000000, 1, -30); -- common mode
 constant a01d : sfixed(1 downto -30) := to_sfixed(-0.000100000000000, 1, -30); -- common mode
 constant a10d : sfixed(1 downto -30) := to_sfixed(0.000270270270270, 1, -30); -- common mode
 constant a11d : sfixed(1 downto -30) := to_sfixed(1.000000000000000, 1, -30); -- common mode 
 constant b00d : sfixed(1 downto -30) := to_sfixed(0.000100000000000, 1, -30); -- common mode 
 constant b11d : sfixed(1 downto -30) := to_sfixed(-0.000270270270270, 1, -30); -- common mode
    
  -- constant inputs
  constant h : sfixed(1 downto -30) := to_sfixed(0.0000005, 1, -30); -- Fixed time step
  constant rL : sfixed(1 downto -30) := to_sfixed(-1,1,-30);      -- Inductor resistance
  constant fd_th : sfixed(1 downto -30) := to_sfixed(0.5, 1, -30); -- Threshold
  
  -- inputs that could change (keep precison same for all)
  constant v_in : sfixed(15 downto -16)   := to_sfixed(30,15,-16);
  constant v_out : sfixed(15 downto -16)  := to_sfixed(54, 15, -16);
  constant i_load : sfixed(15 downto -16) := to_sfixed(4,15,-16);
  
  -- Initial values of il, vc, ipv, vpv (Initial state input)
  constant il0 : sfixed(15 downto -16) := to_sfixed(0, 15,-16);
  constant vc0 : sfixed(15 downto -16) := to_sfixed(60,15,-16);
  constant ipv : sfixed(15 downto -16) := to_sfixed(6,15,-16);
  constant vpv : sfixed(15 downto -16) := to_sfixed(29,15,-16);
  
  -- Zero initial input
  constant zer0 : sfixed(15 downto -16) := to_sfixed(0, 15,-16);
  constant zer0h : sfixed(1 downto -30) := to_sfixed(0, 1,-30);
   
  -- vectors
  type vect2 is array (0 to 1) of sfixed(15 downto -16); -- for z,y
  type vect3 is array (0 to 2) of sfixed(15 downto -16); -- for u
  type vect4 is array (0 to 3) of sfixed(15 downto -16); -- for gamma
  type vectd4 is array (0 to 3) of sfixed(1 downto -30); -- for gamma normalized
    
  -- For normalization of gamma, put reciprocal to avoid division
  constant ibase: sfixed(15 downto -16) := to_sfixed(0.2, 15, -16); -- Ibase = 5
  constant vbase: sfixed(15  downto -16) := to_sfixed(0.025, 15, -16); -- Vbase = 40
    
  -- Matrices
  type mat24 is array (0 to 1, 0 to 3) of sfixed(1 downto -30);  -- for augumented [A:B]
    
  -- Precision
  constant n_left: integer := 15;
  constant n_right: integer := -16;
  constant sum_left: integer := 23;
  constant sum_right: integer := -16;
  constant d_left: integer := 1;
  constant d_right:integer := -30;
  
  -- ILA
  subtype result_type is std_logic_vector (31 downto 0);
  subtype constrained_result is std_logic_vector (30 downto 0);
  
  -- ADC Descaler constants
  constant vmax : sfixed(15 downto -16):= to_sfixed(3.3,15,-16);
  constant vmin : sfixed(15 downto -16):= to_sfixed(0, 15, -16);
  constant adc_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
  constant offset : sfixed(15 downto -16) := to_sfixed(0, 15, -16);
  constant i_factor : sfixed(15 downto -16) := to_sfixed(10, 15, -16);
  constant v_factor : sfixed(15 downto -16) := to_sfixed(100, 15, -16);
  
  -- DAC scaler constants
  constant dac_width : sfixed(15 downto -16) := to_sfixed(4095, 15, -16);
  
  -- Moving avg depth 
  -- Address
  constant total_address : sfixed(1 downto -30) := to_sfixed(0.001, 1, -30); -- Reciprocal of 1024
  constant address_size: integer range 0 to 100 := 9;
  constant address_depth: integer range 0 to 100 := 10;  -- For calculating total address depth
   
  -- Fault Identification
  type ip_array is array (0 to 8) of sfixed(15 downto -16);
  
end package input_pkg;