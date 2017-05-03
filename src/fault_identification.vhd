-- Fault identification --
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use ieee.std_logic_unsigned.all;
library work;
use work.input_pkg.all;

entity fault_identification is
    Port ( 
           clk : in STD_LOGIC;
           start : in STD_LOGIC;
           FD_flag : in STD_LOGIC;
           Residual  : in vect3;
           done : out STD_LOGIC := '0';
           FI_flag : out STD_LOGIC_Vector(2 downto 0):= (others => '0')
         ); 
end fault_identification;

architecture Behavioral of fault_identification is
    
begin
main_loop: process(clk)

        type STATE_VALUE is (S0, S1, S2);
        variable State : STATE_VALUE := S0;
        variable min_num : sfixed(n_left downto n_right) := to_sfixed(30000, n_left, n_right);
        variable index : integer range -1 to 3 := 3;
        
        begin
       if clk ='1' and clk'event then  
            
             case state is
             
         --------------------------------------------------------
         -- state S0(Check if fault has happened) FD = '1'
         ---------------------------------------------------------
              When S0 => 
                         done <= '0';
                       if FD_flag = '1' then
                       
                            if Start = '1' then
                            State := S1;
                            else
                            State := S0;
                            end if;
                       else
                           FI_flag <= "000";
                           State := S0;
                       end if; 
                       
             -- initilization of min_number               
             min_num := to_sfixed(30000, n_left, n_right);
             index := 3;           
          --------------------------------------------------------
           -- state S1 (Find min residual)
          ---------------------------------------------------------
            When S1 =>
                  
                                
              -- Finding min residual
                  for i in 0 to 2 loop
                     if Residual(i) < min_num then
                        min_num := Residual(i);
                        index := i;
                     end if;
                     end loop;
                    State := S2;
            --------------------------------------------------------
            -- state S2 (Compare to threshold and output the result)
            ---------------------------------------------------------
             When S2 =>            
                    --Fault identification flag
                          done <= '1';
                             if index = 0 then
                             FI_flag <= "001";
                             elsif index = 1 then
                             FI_flag <= "010";
                             elsif index = 2 then
                             FI_flag <= "100";
                             else
                             FI_flag <= "000";
                             end if;       
                  State := S0;       
            end case;  
       end if;     
    end process;
end Behavioral;






