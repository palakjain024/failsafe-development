----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.01.2018 20:44:01
-- Design Name: 
-- Module Name: max_num - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use work.input_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity max_num is
Port ( 
clk : in STD_LOGIC;
start : in STD_LOGIC;
gamma : in vect4;
gamma_norm_out : out vectd4 := (zer0h, zer0h, zer0h, zer0h);
ab_gamma_norm_out : out vectd4 := (zer0h, zer0h, zer0h, zer0h);
max_gamma_out : out sfixed(d_left downto d_right):= zer0h
);
end max_num;

architecture Behavioral of max_num is

-- Signal definition
-- Fault detection and residual generation
signal gamma_norm : vectd4 := (zer0h, zer0h, zer0h, zer0h);
signal ab_gamma_norm : vectd4 := (zer0h, zer0h, zer0h, zer0h);


begin

max_numinst: process(clk, gamma)

    type state_value is (S0, S1, S2, S3, S4);
    variable State : state_value := S0;
    variable max_gamma: sfixed(d_left downto d_right):= zer0h;
    
begin
    if clk'event and clk = '1' then
    
    case state is
    
    when S0 =>
         max_gamma := zer0h;
        -- Waiting to start
        if( Start = '1' ) then
           State := S1;
        else
           State := S0;
        end if;
                                
    when S1 =>
        -- Gamma normalization
        gamma_norm(0) <= resize(gamma(0)/ibase, d_left, d_right);
        gamma_norm(1) <= resize(gamma(1)/vbase, d_left, d_right);
        gamma_norm(2) <= resize(gamma(2)/ibase, d_left, d_right);
        gamma_norm(3) <= resize(gamma(3)/vbase, d_left, d_right);
    State := S2;
    
    when S2 =>
        -- Absolute normalizaed gamma
        ab_gamma_norm(0) <= resize(abs(gamma_norm(0)), d_left, d_right); 
        ab_gamma_norm(1) <= resize(abs(gamma_norm(1)), d_left, d_right); 
        ab_gamma_norm(2) <= resize(abs(gamma_norm(2)), d_left, d_right); 
        ab_gamma_norm(3) <= resize(abs(gamma_norm(3)), d_left, d_right); 
    State := S3;
    
    when S3 =>
        -- Calculation of infinity norm
        for i in 0 to 3 loop
            if (max_gamma < ab_gamma_norm(i)) then
            max_gamma := ab_gamma_norm(i);
            end if;
        end loop;
    State := S4;
    
    when S4 =>
        -- Output to mains 
       max_gamma_out <= max_gamma;
       gamma_norm_out <= gamma_norm;
       ab_gamma_norm_out <= ab_gamma_norm;
    State := S0;
    
      end case;
   end if; -- clk
end process;

end Behavioral;
