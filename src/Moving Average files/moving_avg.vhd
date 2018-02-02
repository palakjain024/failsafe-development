-- For averaging gamma: It is the test VHDL program.
-- Its test bench name is moving_avg_t
-- For main program, use moving_average file 
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
--  signal wea: std_logic_vector(0 downto 0) := (others => '0');
--  signal addra: std_logic_vector(3 downto 0) := (others => '0');
--  signal douta, dina: STD_LOGIC_VECTOR(31 DOWNTO 0);
--  signal rsta_busy: STD_LOGIC;
  
--  -- For averaging
--  signal sum_slv: STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');   
--  signal avg_int: sfixed(1 downto -30):= zer0h ;   
  
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
    
    dina <= to_slv(datain);
    done <= '0';
    
    if start = '1' then
     State := S1;
    else
     State := S0;
    end if;
   
    
   when S1 =>
   sum <= resize(sum - to_sfixed(douta,d_left,d_right), d_left, d_right);
   State := S2;
   
   when S2 =>
   wea <= "1";
   sum <= resize(sum + datain, d_left, d_right);
   State := S3;
   
   when S3 =>
   avg_int <= resize(sum*address_size,d_left,d_right);
   State := S4;
   
   when S4 =>
   wea <= "0";
   addra <= addra + "1";
   avg <= avg_int;
   done <= '1';
   
   State := S0;
   end case;
  end if; -- CLK
 end process moving_avg;

end Behavioral;