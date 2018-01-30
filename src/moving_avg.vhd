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
    Port ( clk : in STD_LOGIC;      -- 100 MHz rate
           start : in STD_LOGIC;
           datain : in sfixed(d_left downto d_right);
           done: out STD_LOGIC := '0';
           avg: out sfixed(d_left downto d_right) := zer0h
           );
end moving_avg;

architecture Behavioral of moving_avg is
 -- Component Definitions
 -- Memory Block (Read first mode)
 COMPONENT blk_mem_gen_0
   PORT (
     clka : IN STD_LOGIC;
     ena : IN STD_LOGIC;
     wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
     addra : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
     dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
     douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
     rsta_busy : OUT STD_LOGIC
   );
 END COMPONENT;
   
  -- Memory Block
  signal wea: std_logic := '0';
  signal addra: std_logic_vector(3 downto 0) := (others => '0');
  signal douta, dina: STD_LOGIC_VECTOR(31 DOWNTO 0);
  signal rsta_busy: STD_LOGIC;
  
  -- For averaging
  signal sum_slv: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');   
  signal avg_slv: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');   
  
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
    
    dina <= result_type(datain);
    wea <= '1';
    done <= '0';
    
    if start = '1' then
     State := S1;
    else
     State := S0;
    end if;
   
    
   when S1 =>
   sum_slv <= sum_slv - douta;
   State := S2;
   
   when S2 =>
   sum_slv <= sum_slv + dina;
   State := S3;
   
   when S3 =>
   avg_slv <= sum_slv/address_size;
   wea <= '0';
   addra <= addra + '1';
   State := S4;
   
   when S4 =>
   avg <= to_sfixed(to_integer(signed(avg_slv)), d_left, d_right);
   done <= '1';
   
   State := S0;
   end case;
  end if; -- CLK
 end process moving_avg;

end Behavioral;