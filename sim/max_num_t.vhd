----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.01.2018 21:33:55
-- Design Name: 
-- Module Name: max_num_t - Behavioral
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

entity max_num_t is
end max_num_t;

architecture Behavioral of max_num_t is

-- Component definitions
Component max_num 
Port ( 
clk : in STD_LOGIC;
start : in STD_LOGIC;
gamma : in vect4;
gamma_norm_out : out vectd4 := (zer0h, zer0h, zer0h, zer0h);
ab_gamma_norm_out : out vectd4 := (zer0h, zer0h, zer0h, zer0h);
max_gamma_out : out sfixed(d_left downto d_right):= zer0h
);
end component max_num;

-- Signal definitions
signal clk, start : STD_LOGIC;
signal gamma_norm : vectd4 := (zer0h, zer0h, zer0h, zer0h);
signal ab_gamma_norm : vectd4 := (zer0h, zer0h, zer0h, zer0h);
signal gamma : vect4 := (zer0, zer0, zer0, zer0);
signal max_gamma_out : sfixed(d_left downto d_right) := zer0h;

begin

max_num_inst: max_num port map (
clk => clk,
start => start,
gamma => gamma,
gamma_norm_out => gamma_norm,
ab_gamma_norm_out => ab_gamma_norm,
max_gamma_out => max_gamma_out
);


clk_p: process
begin
clk <= '1';
wait for 5 ns;
clk <= '0';
wait for 5 ns;
end process;

mainLOOP: process(clk)
begin
 if clk'event and clk = '1' then
 
 start <= '1';
 gamma(0) <= to_sfixed(-3, n_left, n_right);
 gamma(1) <= to_sfixed(2, n_left, n_right);
 gamma(2) <= to_sfixed(-2, n_left, n_right);
 gamma(3) <= to_sfixed(-46, n_left, n_right);
 

 end if; -- clk
end process;

end Behavioral;
