-- For averaging gamma
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;

entity moving_avg is
    Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datain : in sfixed(n_left downto n_right);
           done: out STD_LOGIC;
           avg: out sfixed(n_left downto n_right));
end moving_avg;

architecture Behavioral of moving_avg is
 -- Component Definitions
 component memory_block
 port (
    clk   : in  std_logic;
    we      : in  std_logic;
    address : in  std_logic_vector(address_size downto 0);
    datain  : in  sfixed(n_left downto n_right);
    dataout : out sfixed(n_left downto n_right)
  );
  end component;
  
  -- Signal 
  signal sum: sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
  signal we: std_logic := '0';
  signal address: std_logic_vector(address_size downto 0) := (others => '0');
  signal dataout: sfixed(n_left downto n_right);
    
begin

memory_inst: memory_block port map (
clk => clk,
we => we,
address => address,
datain => datain,
dataout => dataout);

moving_avg: process(clk)

type STATE_VALUE is (S0, S1, S2, S3);
variable State: STATE_VALUE := S0; 

begin

if (Clk'event and Clk = '1') then
   
   case State is
   
    when S0 =>
    
    if start = '1' then
     State := S1;
    else
    State := S0;
    end if;
    we <= '0';
    done <= '0';
    
   when S1 =>
   sum <= resize(sum - dataout + datain, n_left, n_right);
   State := S2;
   
   when S2 =>
   we <= '1';
   avg <= resize(sum/to_sfixed(2048, n_left, n_right), n_left, n_right);
   done <= '1';
   State := S3;
   
   when S3 =>
   we <= '0';
   address <= address + '1';
   State := S0;
   end case;
   
end if;

end process moving_avg;

end Behavioral;
