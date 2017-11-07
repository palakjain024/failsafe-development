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
       reset_fd : in STD_LOGIC;
       -- Converter fault flag;
       FD_flag : out STD_LOGIC := '0';
       -- Observer inputs
       pc_pwm : in STD_LOGIC_VECTOR(phases-1 downto 0);
       load : in sfixed(n_left downto n_right);
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
 -- ILA core
COMPONENT ila_0
 
 PORT (
     clk : IN STD_LOGIC;
 
 
 
     probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
     probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
     probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
     probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
     probe4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
     probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
 );
 END COMPONENT  ;
 -- Converter estimator
 component plant_x
 port (        Clk : in STD_LOGIC;
               ena : in STD_LOGIC;
               Start : in STD_LOGIC;
               Mode : in INTEGER range 0 to 2;
               pc_x : in vect2;
               load : in sfixed(n_left downto n_right);
               Done : out STD_LOGIC := '0';
               pc_theta : out vect2 := (theta_L_star,theta_C_star);
               pc_err : out vect2 := (zer0,zer0);
               pc_z : out vect2 := (zer0,zer0)
            );
 end component plant_x;
 
 
---- Signal definition for components ----

-- ILA core
 signal probe_thetaL, probe_thetaC : STD_LOGIC_VECTOR(31 downto 0);
 signal probe_x1, probe_x2 : STD_LOGIC_VECTOR(31 downto 0);
 signal probe_z1, probe_z2 : STD_LOGIC_VECTOR(31 downto 0);
 
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
Plant_inst: plant_x port map (
Clk => clk,
ena => pc_en,
Start => Start,
Mode => Mode,
pc_x => pc_x,
load => load,
Done => done,
pc_theta => theta_ila,
pc_err => err_ila,
pc_z => z_ila
);

ila_inst_1: ila_0
PORT MAP (
    clk => clk_ila,

    probe0 => probe_thetaL, 
    probe1 => probe_thetaC, 
    probe2 => probe_x1, 
    probe3 => probe_x2, 
    probe4 => probe_z1,
    probe5 => probe_z2
    
); 
---- Processes ----

-- Main loop
CoreLOOP: process(clk, pc_pwm, pc_en)
 begin
 
 

  if clk'event and clk = '1' then
           
  ---- ILA ----
  probe_thetaL  <= result_type(theta_ila(0));
  probe_thetaC <= result_type(theta_ila(1)) ; 
  probe_x1 <= result_type(pc_x(0));
  probe_x2 <= result_type(pc_x(1));
  probe_z1 <= result_type(z_ila(0));
  probe_z2 <= result_type(z_ila(1));
           
  ---- Output to main (Observer outputs) ----
   theta_done <= done;
   pc_theta <= theta_ila;
   pc_err <= err_ila;
   pc_z <= z_ila;
            
                      
  ---- To determine Mode PWM for top switch ----
   if counter = 0 then
           if (pc_pwm(0) = '0') then
           -- SW2 Bottom switch conducting
             mode <= 2;
           else
           -- SW1 top Switch conducting
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

   end if; -- Clk
 end process; 

end Behavioral;