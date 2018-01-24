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
       -- FDI outputs
       fd_flag_out : out STD_LOGIC := '0';
       -- FI_flag : out STD_LOGIC_VECTOR(3 downto 0);
       -- Observer inputs
       pc_pwm_top : in STD_LOGIC;
       pc_pwm_bot : in STD_LOGIC;
       plt_u : in vect3;
       plt_y : in vect2
       );
end processor_core;

architecture Behavioral of processor_core is

---- Component definition ----
 -- ILA core
    COMPONENT ila_0

PORT (
    clk : IN STD_LOGIC;


    trig_in : IN STD_LOGIC;
    trig_in_ack : OUT STD_LOGIC;
    probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
    probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
    probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
    probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
    probe4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
    probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
    probe6 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe7 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END COMPONENT  ;
 -- Digital twin estimator (Buck-boost converter)
 component plant_x
 port (   clk : in STD_LOGIC;
          start : in STD_LOGIC;
          -- Buck-boost operation
          mode : in INTEGER range 1 to 3;
          -- Plant input
          plt_u : in vect3; -- see through CRO
          -- Plant output
          plt_y : in vect2;
          -- Estimator outputs
          done : out STD_LOGIC := '0';
          fd_residual : out sfixed(n_left downto n_right) := zer0;
          plt_z : out vect2 := (zer0,zer0)
         );
 end component plant_x;
 
 
---- Signal definition for components ----

-- ILA core
 signal trig_in_ack, trig_in : STD_LOGIC := '0';
 signal probe_normfd, probe_fdflag, probe_z1, probe_z2, probe_y1, probe_y2: STD_LOGIC_VECTOR(31 downto 0);
 signal probe6, probe7: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
 
 -- General
 signal counter : integer range 0 to 50000 := -1;
 
 -- Common Inputs 
 signal start : STD_LOGIC := '0';
 signal mode  : INTEGER range 1 to 3 := 1;
 
 -- Plant outputs and Fault detection logic
 signal done: STD_LOGIC := '1';
 signal z_val: vect2 := (zer0,zer0);
 signal fd_residual : sfixed(n_left downto n_right) := zer0;
 signal fd_flag : STD_LOGIC := '0';
 
begin

---- Instances ----
Plant_inst: plant_x port map (
clk => clk,
start => start,
mode => mode,
plt_u => plt_u,
plt_y => plt_y,
done => done,
fd_residual => fd_residual,
plt_z => z_val
);

ila_inst_1: ila_0
PORT MAP (
    clk => clk_ila,
    
    trig_in => trig_in,
    trig_in_ack => trig_in_ack,
    probe0 => probe_fdflag, 
    probe1 => probe_normfd, 
    probe2 => probe_z1,  
    probe3 => probe_z2, 
    probe4 => probe_y1,
    probe5 => probe_y2,
    probe6 => probe6,
    probe7 => probe7
    
); 
---- Processes ----
-- Main loop
CoreLOOP: process(clk, pc_pwm_top, pc_pwm_bot, pc_en)
 begin
 
 

  if clk'event and clk = '1' then
  
  trig_in <= pc_en;
           
           if pc_en = '1' then


   ---- ILA ----
      probe_fdflag(0) <= fd_flag;
      probe_normfd <= result_type(fd_residual); 
      probe_z1  <= result_type(z_val(0));
      probe_z2 <= result_type(z_val(1)) ; 
      probe_y1 <= result_type(plt_y(0));
      probe_y2 <= result_type(plt_y(1));
      probe6 <= STD_LOGIC_VECTOR(to_unsigned(mode,probe6'length));
                
   ---- Output to main ----
   fd_flag_out <= fd_flag;   -- FD observer
            
   ---- To determine Matrix for corresponding mode ----
   if buck = '1' then
           if (pc_pwm_top = '1' and pc_pwm_bot = '0' ) then
               mode <= 1;
           elsif (pc_pwm_top = '0' and pc_pwm_bot = '1' ) then
                  mode <= 2; 
           else null;
           end if;
    elsif boost = '1' then       
           if (pc_pwm_top = '1' and pc_pwm_bot = '0' ) then
                   mode <= 1;
           elsif (pc_pwm_top = '0' and pc_pwm_bot = '1' ) then
                      mode <= 3; 
           else null;
           end if;
    elsif passthrough = '1' then       
           mode <= 1;
    else
          null;                  
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
 
-- Fault detection logic
fault_detection: process(clk, reset_fd, FD_residual)
               begin
                   if (clk = '1' and clk'event) then
                   
                    -- Fault detection with latch
                      fd_flag <= '0';
                      if reset_fd = '1' then
                      fd_flag <= '0';
                      elsif fd_residual > fd_th or fd_flag = '1'  then
                      fd_flag <= '1';
                      else
                      fd_flag <= '0';
                      end if; -- fd logic
                      
                 end if; -- clk
             end process; -- process

end Behavioral;
