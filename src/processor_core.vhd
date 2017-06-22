--Processor Core for estimator
library IEEE;
library IEEE_PROPOSED;
library work;

use work.input_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;


entity processor_core is
Port ( -- General
       Clk : in STD_LOGIC;
       pwm_start : in STD_LOGIC;
       pc_pwm : in STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1');
       u_inp : in vect7;
       -- Converter fault flag;
       FD_flag : out STD_LOGIC := '0';
       -- Converter state estimator
       pc_z : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right))
          );   
end processor_core;

architecture Behavioral of processor_core is
 -- Component definition
 
 -- Converter estimator
 component plant_x
 port (Clk   : in STD_LOGIC;
       Start : in STD_LOGIC;
       Mode  : in INTEGER range 1 to 8;
       u_inp : in vect7;
       Done  : out STD_LOGIC := '0';
       plt_z : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right))
       );
 end component plant_x;
 
 -- Signal definition for components
 
-- Estimator for 3p Inverter
  -- INPUT  
 signal start : STD_LOGIC := '0';
 signal mode  : INTEGER range 1 to 8 := 1;
 
 -- OUTPUT
 signal done  : STD_LOGIC := '1';
 signal z_val : vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
 
 -- Misc
 signal counter: integer range 0 to pwm_freq := 0;
 
begin

Plant_inst: plant_x port map (
Clk => clk,
Start => start,
Mode => mode,
u_inp => u_inp,
Done => done,
plt_z => z_val
);

CoreLOOP: process(clk, pc_pwm)
begin

if clk'event and clk = '1' then
          
          if pwm_start = '1' then  

            -- Output of estimator
            pc_z <= z_val;
            
            if counter = 0 then
            
            -- Mode selection
               if (pc_pwm = "111") then
                -- Mode 1
                   mode <= 1;
                elsif(pc_pwm = "011") then
                -- Mode 2
                   mode <= 2;
                elsif(pc_pwm = "101") then
                -- Mode 3
                   mode <= 3;
                elsif(pc_pwm = "001") then
                -- Mode 4
                   mode <= 4;
                elsif(pc_pwm = "110") then
                -- Mode 5
                   mode <= 5;
                elsif(pc_pwm = "010") then
                -- Mode 6
                   mode <= 6;
                elsif(pc_pwm = "100") then
                -- Mode 7
                   mode <= 7;   
                elsif(pc_pwm = "000") then
                -- Mode 8
                   mode <= 8; 
                else null;
                end if;
          
          end if; 
              
 -- For constant time step 500 ns Matrix Mutiplication to run  
                    if (counter = 0) then
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
                     
     end if; -- For pwm_start                     
  end if; -- For clk
end process; 

end Behavioral;
