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
       ena : in STD_LOGIC;
       -- Converter state estimator
       vpv : in sfixed(n_left downto n_right);
       pc_x : in sfixed(n_left downto n_right);
       theta_done : out STD_LOGIC;
       pc_theta : out vect3Q := (theta_L_star,theta_C_star,theta_RC_star);
       pc_err : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       pc_z : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right)
       );   
end processor_core;

architecture Behavioral of processor_core is
 -- Component definition
 -- Converter estimator
 component plant_x
  port (  Clk : in STD_LOGIC;
          ena : in STD_LOGIC;
          Start : in STD_LOGIC;
          pc_x : in sfixed(n_left downto n_right);
          vpv : in sfixed(n_left downto n_right);
          Done : out STD_LOGIC := '0';
          pc_theta : out vect3Q := (theta_L_star,theta_C_star,theta_RC_star);
          pc_err : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
          pc_z : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right)
        );
 end component plant_x;
 
 -- Signal definition for components
 -- INPUT  
 signal start : STD_LOGIC := '0';
 -- Misc
 signal counter: integer range -1 to 1e3;
 
begin

Plant_inst: plant_x port map (
Clk => clk,
ena => ena,
Start => start,
pc_x => pc_x,
vpv => vpv,
Done => theta_done,
pc_theta => pc_theta,
pc_err => pc_err,
pc_z => pc_z
);

CoreLOOP: process(clk)
begin

if clk'event and clk = '1' then
          
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
