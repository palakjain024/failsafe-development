--Processor Core for estimator and fault detection and identification for 500 ns
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;

entity processor_core is
Port ( -- General
       Clk : in STD_LOGIC;
       -- Converter state estimator
       pc_pwm : in STD_LOGIC;
       load : in sfixed(n_left downto n_right);
       pc_x : in vect2;
       pc_err : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
       pc_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
          );   
end processor_core;

architecture Behavioral of processor_core is
 -- Component definition
 -- Converter estimator
 component plant_x
  port (  Clk : in STD_LOGIC;
          Start : in STD_LOGIC;
          Mode : in INTEGER range 0 to 2;
          pc_x : in vect2;
          load : in sfixed(n_left downto n_right);
          Done : out STD_LOGIC := '0';
          pc_err : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
          pc_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
        );
 end component plant_x;
 
 -- Signal definition for components
 -- INPUT  
 signal start : STD_LOGIC := '0';
 signal mode  : INTEGER range 0 to 2 := 0;
 -- OUTPUT
 signal done: STD_LOGIC := '1';
 -- Misc
 signal counter: integer range -1 to f_load;
 
begin

Plant_inst: plant_x port map (
Clk => clk,
Start => start,
Mode => mode,
pc_x => pc_x,
load => load,
Done => done,
pc_err => pc_err,
pc_z => pc_z
);

CoreLOOP: process(clk, pc_pwm)
begin

if clk'event and clk = '1' then
          
            if counter = 0 then
                if (pc_pwm = '0') then
                -- Mode
                  mode <= 0;
                elsif(pc_pwm = '1') then
                -- Mode
                    mode <= 1; 
                else mode <= 0;
                end if;
            end if;   
 -- For constant time step 500 ns Matrix Mutiplication to run  
                    if (counter = 2) then
                      start <= '1';
                      elsif (counter = 3) then
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
