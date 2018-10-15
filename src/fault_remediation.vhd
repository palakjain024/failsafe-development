-- Fault identification --
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use ieee.std_logic_unsigned.all;
library work;
use work.input_pkg.all;

entity fault_remediation is
    Port ( 
           clk : in STD_LOGIC;
           start : in STD_LOGIC;
           FD_flag : in STD_LOGIC;
           FI_flag : in STD_LOGIC_Vector(3 downto 0):= (others => '0');
           done : out STD_LOGIC := '0';
           SW_active : out STD_LOGIC := '0';
           FR_flag_iL : out STD_LOGIC := '0';
           FR_flag : out STD_LOGIC := '0'          
         );
end fault_remediation;


architecture Behavioral of fault_remediation is

begin
main_loop: process(clk)

        type STATE_VALUE is (S0, S1, S2);
        variable State : STATE_VALUE := S0;

        
        begin
       if clk ='1' and clk'event then  
            
             case state is
             
         --------------------------------------------------------
         -- state S0(Check if fault has happened) FD = '1'
         ---------------------------------------------------------
              When S0 => 
              
              -- initilization            
                done <= '0';
                
              -- 500 ns wait
                if Start = '1' then
                
                -- Check if FD = '1'
                if FD_flag = '1' then
                State := S1;
                else
                State := S0;
                SW_active <= '0';
                FR_flag <= '0';
                FR_flag_iL <= '0';
                end if;
                
                else
                State := S0;
                end if;
                                     
      
              When S1 =>
              
              if FI_flag = "0001" then
              SW_active <= '1';
              FR_flag <= '1';
              elsif FI_flag = "0010" then
              SW_active <= '0';
              FR_flag_iL <= '1';
              FR_flag <= '1';
              elsif FI_flag = "0100" then
              FR_flag_iL <= '0';
              SW_active <= '0';
              FR_flag <= '1';
              else
              SW_active <= '0';
              FR_flag_iL <= '0';
              FR_flag <= '0';
              end if;
              
              State := S2;
              
              When S2 =>
              
              done <= '1';
              State := S0;
                 
        end case;  
     end if; -- Clk     
  end process;     
end Behavioral;
