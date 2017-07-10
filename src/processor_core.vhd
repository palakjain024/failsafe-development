library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use work.input_pkg.all;

entity processor_core is
Port ( -- General
       Clk : in STD_LOGIC;
       -- Observer inputs
       pc_pwm : in STD_LOGIC_VECTOR(phases-1 downto 0);
       load : in sfixed(n_left downto n_right);
       pc_y : in vect2;
       -- FD logic
       FD_residual_out : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       pc_z : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
       );
end processor_core;

architecture Behavioral of processor_core is
-- Component definition
 -- Converter estimator
 component plant_x
 port (   Clk : in STD_LOGIC;
          Start : in STD_LOGIC;
          Mode : in INTEGER range 1 to 4;
          load : in sfixed(n_left downto n_right);
          plt_y : in vect2;
          done : out STD_LOGIC := '0';
          FD_residual : out sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
          plt_z : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
         );
 end component plant_x;
 
  -- Signal definition for components
 
 -- General
 signal counter : integer range 0 to 50000 := -1;
 
 -- Common Inputs 
 signal Start : STD_LOGIC := '0';
 signal Mode  : INTEGER range 1 to 4 := 1;
 
 -- Plant outputs and Fault detection logic
 signal done: STD_LOGIC := '1';
 signal z_val: vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
 signal FD_residual : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
-- signal flag : STD_LOGIC := '0';
 
begin

Plant_inst: plant_x port map (
Clk => clk,
Start => start,
Mode => mode,
load => load,
plt_y => pc_y,
Done => done,
FD_residual => FD_residual,
plt_z => z_val
);

-- Processes
CoreLOOP: process(clk, pc_pwm)
 begin

           if clk'event and clk = '1' then
           
          -- Output to main
           pc_z <= z_val;
           FD_residual_out <= FD_residual;
           
          -- To determine Mode PWM for bot switch
               if counter = 0 then
                       if (pc_pwm(0) = '1' and pc_pwm(1) = '0' ) then
                       -- Mode SW1 top conducting
                         mode <= 1;
                       elsif (pc_pwm(0) = '0' and pc_pwm(1) = '0' ) then
                       -- Mode no top SW conducting
                         mode <= 2; 
                       elsif (pc_pwm(0) = '0' and pc_pwm(1) = '1' ) then
                       -- Mode SW2 top conducting
                         mode <= 3;
                       elsif (pc_pwm(0) = '1' and pc_pwm(1) = '1' ) then
                       -- Mode both top SW conducting
                         mode <= 4;  
                       end if;
              end if;
         -- For constant time step 500 ns Matrix Mutiplication to run  
                if (counter = 1) then
                  start <= '1';
                  elsif (counter = 2) then
                  start <= '0';
                  else null;
                end if; 
                 
                 if (counter = 49) then
                    counter <= 0;
                    else
                    counter <= counter + 1;
                 end if;
                           
    end if;
 end process; 
end Behavioral;
