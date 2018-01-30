-- Testbench: For averaging gamma 
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;


entity moving_avg_t is
--  Port ( );
end moving_avg_t;

architecture Behavioral of moving_avg_t is

-- Component def
Component moving_avg is
    Port ( clk : in STD_LOGIC;      -- 100 MHz rate
           start : in STD_LOGIC;
           datain : in sfixed(d_left downto d_right);
           done: out STD_LOGIC := '0';
           avg: out sfixed(d_left downto d_right) := zer0h
           );
end component moving_avg;

-- Signal definitions
signal clk, start, done : STD_LOGIC;
signal max_gamma_out : sfixed(d_left downto d_right) := zer0h;
signal avg : sfixed(d_left downto d_right) := zer0h;


begin

clk_p: process
begin
clk <= '1';
wait for 5 ns;
clk <= '0';
wait for 5 ns;
end process;

moving_avg_int: moving_avg port map (
clk => clk,
start => start,
datain => max_gamma_out,
done => done,
avg => avg
);

main_loop: process(clk)
begin
 if clk'event and clk = '1' then
 
  start <= '1';
  max_gamma_out <= to_sfixed(0.98, d_left, d_right);
  
 end if; -- CLK
end process; 
 

end Behavioral;
