-- For averaging gamma, using IP block, Block Memory Generator 8.3
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;

entity moving_avg_v1 is
 Port (
          clk : in STD_LOGIC;      -- 100 MHz rate
          start : in STD_LOGIC;
          datain : in sfixed(n_left downto n_right);
          -- Output signals   
          done: out STD_LOGIC := '0';
          avg: out sfixed(n_left downto n_right) := zer0);
end moving_avg_v1;

architecture Behavioral of moving_avg_v1 is
-- Memory Block (Write  first mode)
COMPONENT blk_mem_gen_0
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rsta_busy : OUT STD_LOGIC
  );
END COMPONENT;
 
 -- Memory Block
 signal wea: std_logic_vector(0 downto 0) := (others => '0');
 signal addra: std_logic_vector(11 downto 0) := (others => '0');
 signal douta, dina: STD_LOGIC_VECTOR(31 DOWNTO 0);
 signal rsta_busy: STD_LOGIC;
   
 -- For averaging
 signal sum: sfixed(sum_left downto sum_right):= to_sfixed(0, sum_left, sum_right);  
 signal avg_out: sfixed(n_left downto n_right):= zer0;
 
begin

mem_inst: blk_mem_gen_0
  PORT MAP (
    clka => clk,
    ena => '1',
    wea => wea,
    addra => addra,
    dina => dina,
    douta => douta,
    rsta_busy => rsta_busy
  );

moving_avg: process(clk)

type STATE_VALUE is (S0, S1, S2, S3, S4);
variable State: STATE_VALUE := S0; 

begin

if (Clk'event and Clk = '1') then
   
   case State is
   
    when S0 =>
    
    done <= '0';
    if start = '1' then
     State := S1;
    else
     State := S0;
    end if;
    
   when S1 =>
   sum <= resize(sum - to_sfixed(douta,n_left,n_right), sum_left, sum_right);
   State := S2;
   
   when S2 =>
   wea <= "1";
   dina <= to_slv(datain);
   sum <= resize(sum + datain, sum_left, sum_right);
   State := S3;
   
   when S3 =>
   avg_out <= resize(sum*total_address,n_left,n_right);
   State := S4;
   
   when S4 =>
   wea <= "0";
   addra <= addra + "1";
   avg <= avg_out;
   done <= '1';
   
   State := S0;
   end case;
  end if; -- CLK
 end process moving_avg;


end Behavioral;
