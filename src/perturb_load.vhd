library IEEE;
library IEEE_proposed;
library work;
use work.input_pkg.all;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.STD_LOGIC_1164.ALL;


entity perturb_load is
    Port ( clk : in STD_LOGIC;
           pulsed_load : out sfixed(n_left downto n_right) := to_sfixed(2, n_left, n_right) );
end perturb_load;

architecture Behavioral of perturb_load is
    signal counter_load   : integer range -1 to f_load; 
begin
Load: process (clk) 
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN                            
                                                      
        IF(counter_load = f_load - 1) THEN                                    --end of period reached
          counter_load <= 0;                                                  --reset counter
        ELSE                                                                  --end of period not reached
          counter_load <= counter_load + 1;                                   --increment counter
        END IF;
 
        IF(counter_load <= f_load/2) THEN     --Load's falling edge reached
          pulsed_load <= i_load;                                                  
        ELSE                                  --Load's rising edge reached
          pulsed_load <= to_sfixed(2,15,-16);                                                   
        END IF;
      
    END IF;
 END PROCESS;
end Behavioral;
