-- Memory Block
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;

entity memory_block is
 port (
   clk   : in  std_logic;
   we      : in  std_logic;
   address : in  std_logic_vector(address_size downto 0);
   datain  : in  sfixed(n_left downto n_right);
   dataout : out sfixed(n_left downto n_right)
 );
end memory_block;

architecture Behavioral of memory_block is

   type ram_type is array (0 to (2**address_depth)-1) of sfixed(n_left downto n_right);
   signal ram : ram_type :=  (others => zer0);
   signal read_address : std_logic_vector(address'range);

begin

RamProc: process(clk) is
begin
  
    if clk'event and clk = '1' then
      
      if we = '1' then
        ram(to_integer(unsigned(address))) <= datain;
        elsif we = '0' then
        dataout <= ram(to_integer(unsigned(read_address)));
        else null;
      end if;
      
    end if;
end process RamProc;

read_address <= address;
end Behavioral;