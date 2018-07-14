-- Control --
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use ieee.std_logic_unsigned.all;
library work;
use work.input_pkg.all;

entity control is
    Port ( 
           clk : in STD_LOGIC;
           start : in STD_LOGIC;
           ena : in STD_LOGIC;
           iL : in sfixed(n_left downto n_right);
           done : out STD_LOGIC := '0';
           up1_out : OUT  sfixed(n_left downto n_right);
           up2_out : OUT  sfixed(n_left downto n_right);
           ui_out : OUT  sfixed(n_left downto n_right);
           duty : OUT  sfixed(n_left downto n_right) := duty_min --duty cycle (range given by bit resolution)         
         );
end control;

architecture Behavioral of control is
-- signals
signal err : sfixed(n_left downto n_right):= zer0;
signal up1, up2 : sfixed(n_left downto n_right):= zer0;
signal ui : sfixed(n_left downto n_right):= zer0;
signal input_val : sfixed(n_left downto n_right):= to_sfixed(0.50, n_left, n_right);

begin
main_loop: process(clk)

        type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6);
        variable State : STATE_VALUE := S0;

        
        begin
  if clk ='1' and clk'event then  
       
      if ena = '1' then
            
             case state is
             
         --------------------------------------------------------
         -- state S0(Check if fault has happened) FD = '1'
         ---------------------------------------------------------
              When S0 => 
              
              -- initilization            
                done <= '0';
           
              -- 500 ns wait
                if Start = '1' then
                State := S1;
                else
                State := S0;
                end if;
                                     
      
              When S1 =>
              -- P control
              up1 <= resize(err * kp, n_left, n_right); 
              -- Error cal
              err <= resize(iref - iL, n_left, n_right);
              State := S2;
              
              When S2 =>
              -- P control
              up1 <= resize((err * kp) - up1, n_left, n_right); 
              -- For PI control
              up2 <= resize(err * ki, n_left, n_right);   
              State := S3;
              
              When S3 =>
              -- PI control
              ui <= resize(up1 + up2, n_left, n_right);           
              State := S4;
              
              When S4 =>
              input_val <= resize(input_val + ui, n_left, n_right);
              State := S5;
              
              When S5 =>
              -- Saturator
              if input_val > duty_max then
              input_val <= duty_max;
              elsif input_val <  duty_min then
              input_val <= duty_min;
              else null;
              end if;
              State := S6;
              
              when S6 =>
              duty <= input_val; 
              up1_out <= up1;
              up2_out <= up2;
              ui_out <= ui;              
              done <= '1';
              State := S0;
                 
        end case;  
        
   else
    duty <= to_sfixed(0.50, n_left, n_right);
   end if; -- ena
   
     end if; -- Clk     
  end process;     

end Behavioral;
