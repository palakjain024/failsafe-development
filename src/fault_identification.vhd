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
           avg_norm : in vect2;
           done : out STD_LOGIC := '0';
           ip: inout ip_array := (to_sfixed(0, n_left, n_right), to_sfixed(0, n_left, n_right), to_sfixed(0, n_left, n_right));
           FI_flag : out STD_LOGIC_Vector(2 downto 0):= (others => '0')
         );
end fault_identification;

architecture Behavioral of fault_identification is

--Signals   
--  Inner product          
    signal	A       : ip_array := (to_sfixed(0, n_left, n_right), to_sfixed(0, n_left, n_right), to_sfixed(0, n_left, n_right));
    signal  B       : ip_array := (to_sfixed(0, n_left, n_right), to_sfixed(0, n_left, n_right), to_sfixed(0, n_left, n_right));
   
    
begin
main_loop: process(clk)

        type STATE_VALUE is (S0, S1, S2, S3, S4, S5);
        variable State : STATE_VALUE := S0;
        variable max_num : sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
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
                           ip   <= (to_sfixed(0, n_left, n_right), to_sfixed(0, n_left, n_right), to_sfixed(0, n_left, n_right));
                           FI_flag <= "000";
                           State := S0;
                       end if; 
                       
             -- initilization of max_number               
             max_num := to_sfixed(-10, n_left, n_right);
             index := 3;           
          --------------------------------------------------------
           -- state S1 (Calculate inner product)
          ---------------------------------------------------------
            When S1 =>
                  
        A(0) <= resize(to_sfixed(-1.5, n_left, n_right) * avg_norm(0), n_left, n_right);
        A(1) <= resize(to_sfixed(-0.8, n_left, n_right) * avg_norm(0), n_left, n_right); 
        A(2) <= resize(to_sfixed(-0.5, n_left, n_right) * avg_norm(0), n_left, n_right);      
        State := S2;
            --------------------------------------------------------
            -- state S2 (Integrate inner product)
            ---------------------------------------------------------
            When S2 =>
            
         B(0) <= resize(to_sfixed(0, n_left, n_right) * avg_norm(1), n_left, n_right);
         B(1) <= resize(to_sfixed(-1.8, n_left, n_right) * avg_norm(1), n_left, n_right);
         B(2) <= resize(to_sfixed(10, n_left, n_right) * avg_norm(1), n_left, n_right);       
         State := S3;
          
           When S3 =>
           
         ip(0) <= resize(A(0) + B(0), n_left, n_right);
         ip(1) <= resize(A(1) + B(1), n_left, n_right);
         ip(2) <= resize(A(2) + B(2), n_left, n_right);
         State := S4;
         
            When S4 =>            
                          
              -- Finding max ip
                  for i in 0 to 2 loop
                     if ip(i) > max_num then
                        max_num := ip(i);
                        index := i;
                     end if;
                     end loop;
                    State := S5;
                    --------------------------------------------------------
                    -- state S5 (Compare to threshold and output the result)
                    ---------------------------------------------------------
                     When S5 =>            
                    --Fault identification flag
                          done <= '1';
                          if max_num > to_sfixed(0.8, n_left, n_right) then
                          
                             if index = 0 then
                             FI_flag <= "001";
                             elsif index = 1 then
                             FI_flag <= "010";
                             elsif index = 2 then
                             FI_flag <= "100";
                             else
                             FI_flag <= "000";
                             end if;
                             
                          end if;       
                 State := S0;       
            end case;  
       end if;     
    end process;
end Behavioral;






