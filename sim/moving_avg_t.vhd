-- Testbench: For averaging gamma, Design file is moving_avg. This is alsothe test design file. 
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
           -- Intermediate signals
           wea: inout std_logic_vector(0 downto 0) := (others => '0');
           addra: inout std_logic_vector(3 downto 0) := (others => '0');
           douta: inout STD_LOGIC_VECTOR(31 DOWNTO 0);
           dina: inout STD_LOGIC_VECTOR(31 DOWNTO 0);
           rsta_busy: out STD_LOGIC;
            -- For averaging
           sum: inout sfixed(1 downto -30):= zer0h;   
           avg_int: inout sfixed(1 downto -30):= zer0h ;
           -- Output signals   
           done: out STD_LOGIC := '0';
           
           avg: out sfixed(d_left downto d_right) := zer0h
           );
end component moving_avg;

-- Signal definitions
signal clk, start, done : STD_LOGIC := '0';
signal max_gamma_out : sfixed(d_left downto d_right) := zer0h;
signal avg : sfixed(d_left downto d_right) := zer0h;
signal counter : integer range 0 to 5000 := 0;

signal wea: std_logic_vector(0 downto 0) := (others => '0');
signal addra: std_logic_vector(3 downto 0) := (others => '0');
signal douta, dina: STD_LOGIC_VECTOR(31 DOWNTO 0);
signal rsta_busy: STD_LOGIC;
  
  -- For averaging
signal sum: sfixed(1 downto -30):= zer0h;   
signal avg_int: sfixed(1 downto -30):= zer0h ;   
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
wea => wea,
addra => addra,
douta => douta,
dina => dina,
rsta_busy => rsta_busy,
sum => sum,
avg_int => avg_int,
done => done,
avg => avg
);

main_loop: process(clk)
begin
 if clk'event and clk = '1' then
 
   if (counter = 2) then
      start <= '1';
      max_gamma_out <= resize(max_gamma_out - to_sfixed(0.002, n_left, n_right), d_left, d_right); 
      elsif (counter = 3) then
      start <= '0';
      else null;
    end if; 
     
     if (counter = 49) then
        counter <= 0;
        else
        counter <= counter + 1;
     end if;
  
 end if; -- CLK
end process; 
 

end Behavioral;
