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
       pc_x : in vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
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
 -- Converter estimator
 component plant_x
 port (   Clk : in STD_LOGIC;
          Start : in STD_LOGIC;
          Mode : in INTEGER range 1 to 4;
          load : in sfixed(n_left downto n_right);
          plt_y : in vect2;
          done : out STD_LOGIC := '0';
          FD_residual : out sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
          plt_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
         );
 end component plant_x;
 
 
---- Signal definition for components ----

-- ILA core
 signal trig_in_ack, trig_in : STD_LOGIC := '0';
 signal probe_normfd, probe_normc, probe_z1fd, probe_z2fd, probe_y1c : STD_LOGIC_VECTOR(31 downto 0);
 signal probe_y2c, probe_y1p, probe_y2p : STD_LOGIC_VECTOR(31 downto 0);
 
 -- General
 signal counter : integer range 0 to 50000 := -1;
 
 -- Common Inputs 
 signal Start : STD_LOGIC := '0';
 signal Mode  : INTEGER range 1 to 4 := 1;
 
 -- Plant outputs and Fault detection logic
 signal done: STD_LOGIC := '1';
 signal z_val: vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
 signal FD_residual : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
 signal flag : STD_LOGIC := '0';
 
begin

---- Instances ----
Plant_inst: plant_x port map (
Clk => clk,
Start => start,
Mode => mode,
load => load,
plt_y => pc_y,
Done => done,
FD_residual => FD_residual,
plt_z => z_val
);

ila_inst_1: ila_0
PORT MAP (
    clk => clk_ila,
    
    trig_in => trig_in,
    trig_in_ack => trig_in_ack,
    probe0 => probe_normfd, 
    probe1 => probe_normc, 
    probe2 => probe_z1fd,  
    probe3 => probe_z2fd, 
    probe4 => probe_y1c,
    probe5 => probe_y2c,
    probe6 => probe_y1p,
    probe7 => probe_y2p
    
); 
---- Processes ----

-- Main loop
CoreLOOP: process(clk, pc_pwm, pc_en)
 begin
 
 

  if clk'event and clk = '1' then
           
           if pc_en = '1' then


   ---- ILA ----
      probe_normfd <= result_type(FD_residual);
      probe_normc <= result_type(norm_c); 
      probe_z1fd  <= result_type(z_val(0));
      probe_y1p <= result_type(pc_y(0)) ; 
      probe_y2p <= result_type(pc_y(1));
      probe_z2fd <= result_type(z_val(1));
      probe_y1c <= result_type(y_est_c(0));
      probe_y2c <= result_type(y_est_c(1));
           
          ---- Output to main ----
          
           -- FD observer
            pc_z <= z_val;
            FD_residual_out <= FD_residual;
            FD_flag <= flag;
            
                      
           ---- To determine Mode PWM for top switch ----
               if counter = 0 then
                       if (pc_pwm(0) = '1' and pc_pwm(1) = '0' ) then
                       -- Mode SW1 top conducting
                         mode <= 1;
                       elsif (pc_pwm(0) = '0' and pc_pwm(1) = '0' ) then
                       -- Mode no top SW conducting
                         mode <= 2; 
                       elsif (pc_pwm(0) = '0' and pc_pwm(1) = '1' ) then
                       -- Mode SW2 top conducting
                         mode <= 3;
                       elsif (pc_pwm(0) = '1' and pc_pwm(1) = '1' ) then
                       -- Mode both top SW conducting
                         mode <= 4;  
                       end if;
              end if;
           ---- For constant time step 500 ns Matrix Mutiplication to run ----
                if (counter = 1) then
                  start <= '1';
                  trig_in <= '1'; 
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
                    -- Fault detection
                      --flag <= '0';
                      if FD_residual > fd_th or flag = '1' then
                      
                      flag <= '1';
                          if (reset_fd = '1') then
                          flag <= '0';
                          else
                          flag <= '1';
                          end if;
                      else
                      flag <= '0';
                      end if;
                 end if;
             end process;

end Behavioral;
