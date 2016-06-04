library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;

entity scaler is
   Generic(
    dac_left : integer range -100 to 100;
    dac_right : integer range -100 to 100;
    dac_max : sfixed(n_left downto n_right);
    dac_min : sfixed(n_left downto n_right));
    Port ( clk : in STD_LOGIC;
           dac_in : in sfixed(dac_left downto dac_right);
           dac_val : out STD_LOGIC_VECTOR(11 downto 0));
end scaler;

architecture Behavioral of scaler is
 
 signal dac_range : sfixed(dac_left downto dac_right);
 signal shift     : sfixed(dac_left downto dac_right);
 signal outlevel  : sfixed(dac_left downto dac_right);
 signal conv_val  : integer range 0 to 5000;
 signal in_val : sfixed(dac_left downto dac_right);
 
begin

scaler_p: process (clk)


type STATE_VALUE is (S0, S1, S2, S3);
variable State : STATE_VALUE := S0;       
         
begin
        
  if clk = '1' and clk'event then

  case state is
  
    when S0 =>
         dac_range <= resize(dac_max - dac_min, dac_range'left, dac_range'right);
        -- check if dac_in is range
         if dac_in < dac_min then
         in_val <= dac_min;
         elsif dac_in > dac_max then
         in_val <= dac_max;
         else
         in_val <= dac_in;
         end if;
         
         State := S1;
         
    when S1 =>
         shift <= resize(in_val - dac_min, shift'left, shift'right);
         outlevel <= resize(dac_width/dac_range, outlevel'left, outlevel'right);
         State := S2;
          
    when S2 =>
         conv_val <= to_integer(shift * outlevel);
         State := S3;
            
    when S3 =>
          dac_val <= std_logic_vector(to_unsigned(conv_val, 12));
          State := S0;
          
    end case;
  end if;
end process;

end Behavioral;
