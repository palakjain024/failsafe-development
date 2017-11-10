-- Open loop observer

library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use work.input_pkg.all;

entity processor_core is
Port ( -- General
       Clk : in STD_LOGIC;
       clk_ila : in STD_LOGIC;
       pc_en : in STD_LOGIC;
       pc_pe : in STD_LOGIC;
       -- Converter fault flag;
       --reset_fd : in STD_LOGIC;
       --FD_flag : out STD_LOGIC := '0';
       -- Observer inputs
       pc_pwm : in STD_LOGIC;
       load : in sfixed(n_left downto n_right);
       gain : in vect2;
       pc_x : in vect2 ;
       -- Observer outputs
       theta_done : out STD_LOGIC := '0';
       pc_theta : out vect2 := (theta_L_star,theta_C_star);
       pc_err : out vect2 := (zer0,zer0);
       pc_z : out vect2 := (zer0,zer0)
       );
end processor_core;

architecture Behavioral of processor_core is

---- Component definition ----

 -- Converter estimator
 component plant_x_cl
 port (        clk : in STD_LOGIC;
               clk_ila : in STD_LOGIC;
               pc_en : in STD_LOGIC;
               ena : in STD_LOGIC;
               Start : in STD_LOGIC;
               Mode : in INTEGER range 0 to 2;
               pc_x : in vect2;
               load : in sfixed(n_left downto n_right);
               gain : in vect2;
               Done : out STD_LOGIC := '0';
               pc_theta : out vect2 := (theta_L_star,theta_C_star);
               pc_err : out vect2 := (zer0,zer0);
               pc_z : out vect2 := (zer0,zer0)
            );
 end component plant_x_cl;
 
 
---- Signal definition for components ----

  -- General
 signal counter : integer range 0 to 50000 := -1;
 
 -- Common Inputs 
 signal Start : STD_LOGIC := '0';
 signal Mode  : INTEGER range 0 to 2 := 1;
 
 -- Plant outputs and Fault detection logic
 signal done: STD_LOGIC := '1';
 signal z_ila: vect2 := (zer0,zer0);
 signal err_ila : vect2 := (zer0,zer0);
 signal theta_ila : vect2 := (zer0,zer0);
 
begin

---- Instances ----
Plant_inst: plant_x_cl port map (
clk => clk,
clk_ila => clk_ila,
pc_en => pc_en,
ena => pc_pe,
Start => Start,
Mode => Mode,
pc_x => pc_x,
load => load,
gain => gain,
Done => done,
pc_theta => theta_ila,
pc_err => err_ila,
pc_z => z_ila
);

---- Processes ----

-- Main loop
CoreLOOP: process(clk, pc_pwm, pc_en)
 begin
 
 

  if clk'event and clk = '1' then
  
  if pc_en = '1' then
           
  ---- Output to main (Observer outputs) ----
   theta_done <= done;
   pc_theta <= theta_ila;
   pc_err <= err_ila;
   pc_z <= z_ila;
            
                      
  ---- To determine Mode PWM for top switch ----
   if counter = 0 then
           if (pc_pwm = '0') then -- active low (pc_pwm(0) given to bottom switch)
           -- SW2 Bottom switch conducting
             mode <= 2;
           else
           -- SW1 Top Switch conducting
             mode <= 1;  
           end if;
   end if;
  ---- For constant time step 500 ns Matrix Mutiplication to run ----
    if (counter = 1) then
      start <= '1';
    elsif (counter = 2) then
      start <= '0';
    else null;
    end if; 
     
    if (counter = 49) then
        counter <= 0;
    else
        counter <= counter + 1;
    end if;
    
    end if; -- pc_en
   end if; -- Clk
 end process; 

end Behavioral;