library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;

entity descaler is
    Generic(
    adc_Factor : sfixed(15 downto -16));
    Port ( clk : in STD_LOGIC;
           adc_in : in STD_LOGIC_VECTOR(11 downto 0);
           adc_val : out sfixed(n_left downto n_right)
         );
end descaler;

architecture Behavioral of descaler is
   signal int_val : integer range 0 to 5000 := 0;
   signal adc_range : sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
   signal inlevel : sfixed(n_left downto n_right):= to_sfixed(0, n_left, n_right);
   signal conv_val : sfixed(n_left downto n_right):= to_sfixed(0, n_left, n_right);
   
begin
conv: process (clk)
                   
                   
                           type adc_conv is (V0, V1, V2);
                           variable conv_step : adc_conv := V0;
                          
  begin
          if clk ='1' and clk'event then
        
              case conv_step is
                                   
               when V0 =>
               int_val <= to_integer(unsigned(adc_in));
               adc_range <= resize((vmax - vmin) * adc_factor, n_left, n_right);
               conv_step := V1;
                                                         
               when V1 =>
               inlevel <= resize(adc_range/adc_width, n_left, n_right);
               conv_step := V2;
               
               when V2 =>
               adc_val <= resize(int_val * inlevel, n_left, n_right);
               conv_step := V0;
                                                                     
               end case;
         end if;
end process;         
end Behavioral;
