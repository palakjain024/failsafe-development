-- Processor Core
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
       ena : in STD_LOGIC;
       pc_en : in STD_LOGIC;
       reset_fd : in STD_LOGIC;
       FI_flag_delay : in STD_LOGIC_VECTOR(3 downto 0);
       -- FDI outputs
       fd_flag_out : out STD_LOGIC := '0';
       fi_flag_out : out STD_LOGIC_VECTOR(3 downto 0);
       fr_flag_out : out STD_LOGIC := '0';
       -- FR
       SW_active_out : out STD_LOGIC := '0';
       zval: out vect2;
       -- Control
       duty : OUT  sfixed(n_left downto n_right);
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
     probe7 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
     probe8 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
     probe9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
     probe10 : IN STD_LOGIC_VECTOR(3 DOWNTO 0); 
     probe11 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
     probe12 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
     probe13 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
     probe14 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
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
          gamma_out : out vect4 := (zer0, zer0, zer0, zer0);
          max_gamma_out : out sfixed(d_left downto d_right) := zer0h;
          gamma_avg_out : out vect4 := (zer0, zer0, zer0, zer0);
          plt_z : out vect2 := (zer0,zer0)
         );
 end component plant_x;
 
 -- Fault identification
  component fault_identification
    Port ( 
         clk : in STD_LOGIC;
         start : in STD_LOGIC;
         FD_flag : in STD_LOGIC;
         FR_flag : in STD_LOGIC;
         gamma_avg : in vect4;
         done : out STD_LOGIC := '0';
         max_ip_out : out sfixed(n_left downto n_right) := zer0;
         gavg_norm_out : out vect4 := (zer0, zer0, zer0, zer0); -- norm of gamma average
         ip_out : out ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
         FI_flag : out STD_LOGIC_Vector(3 downto 0):= (others => '0')
       );
 end component fault_identification;
 
 -- Fault remediation
 component fault_remediation
 Port ( 
            clk : in STD_LOGIC;
            start : in STD_LOGIC;
            FD_flag : in STD_LOGIC;
            FI_flag : in STD_LOGIC_Vector(3 downto 0):= (others => '0');
            done : out STD_LOGIC := '0';
            SW_active : out STD_LOGIC := '0';
            FR_flag : out STD_LOGIC := '0'          
          );
 end component fault_remediation;
 
 -- Control
 component control
  Port ( 
            clk : in STD_LOGIC;
            start : in STD_LOGIC;
            ena : in STD_LOGIC;
            iL : in sfixed(n_left downto n_right);
            done : out STD_LOGIC := '0';
            up1_out : OUT  sfixed(n_left downto n_right);
            up2_out : OUT  sfixed(n_left downto n_right);
            ui_out : OUT  sfixed(n_left downto n_right);
            duty : OUT  sfixed(n_left downto n_right) --duty cycle (range given by bit resolution)         
          );
  end component control;        
---- Signal definition for components ----

-- ILA core
 signal trig_in_ack, trig_in: STD_LOGIC := '0';
 
 signal probe_z1, probe_z2, probe_ipv, probe_vpv, probe_vc, probe_iload, probe_il: STD_LOGIC_VECTOR(31 downto 0);
 signal probe_normfd, probe_maxip: STD_LOGIC_VECTOR(31 downto 0);
 -- control
 signal probe_duty, probe_up1, probe_up2, probe_ui: STD_LOGIC_VECTOR(31 downto 0);
 -- Gamma avg
 signal probe_gn0, probe_gn1, probe_gn2, probe_gn3: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
 signal probe_gn0avg, probe_gn1avg, probe_gn2avg, probe_gn3avg: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
 
 signal probe_fd: STD_LOGIC_VECTOR(0 downto 0) := (others => '0');
 signal probe_fi: STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
 signal probe_ip1, probe_ip2, probe_ip3 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
 signal probe_ip4, probe_ip5, probe_ip6 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
 signal probe_ip7, probe_ip8, probe_ip9 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
 signal probe_ip10, probe_ip11, probe_ip12 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
 
 -- General
 signal counter : integer range 0 to 50000 := 0;
 signal counter_control : integer range 0 to 50000 := 0;
 
 -- Common Inputs 
 signal start : STD_LOGIC := '0';
 signal mode  : INTEGER range 1 to 3 := 1;
 
 -- Plant outputs and Fault detection logic
 signal done: STD_LOGIC := '0';
 signal z_val: vect2 := (zer0,zer0);
 signal gamma, gamma_avg : vect4 := (zer0, zer0, zer0, zer0);
 signal gamma_norm, gamma_avg_norm : vectd4 := (zer0h, zer0h, zer0h, zer0h);
 signal max_gamma : sfixed(d_left downto d_right):= zer0h;
 signal fd_flag : STD_LOGIC := '0';
 
 -- Fault identification
 signal done_fi: STD_LOGIC := '0';
 signal gavg_norm : vect4 := (zer0, zer0, zer0, zer0);
 signal max_ip : sfixed(n_left downto n_right) := zer0;
 signal ip:  ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
 signal fi_flag : STD_LOGIC_VECTOR(3 downto 0):= (others => '0');
 
 -- Fault remediation
 signal FR_flag, done_fr : STD_LOGIC := '0';
 signal SW_active : STD_LOGIC := '0';
 
 -- Control
 signal done_control, start_control : STD_LOGIC := '0';
 signal duty_control, up1, up2, ui : sfixed(n_left downto n_right) := zer0;
 
begin

---- Instances ----
control_inst: control port map (
clk => clk,
start => start,
ena => ena,
iL => plt_y(0),
done => done_control,
up1_out => up1,
up2_out => up2,
ui_out => ui,
duty => duty_control
);

fault_rem_inst: fault_remediation port map (
clk => clk,
start => start,
FD_flag => FD_flag,
FI_flag => FI_flag_delay,
done => done_fr,
SW_active => SW_active,
FR_flag => FR_flag
);


fault_identity_inst: fault_identification port map(
clk => clk,
start => start,
FD_flag => fd_flag,
FR_flag => FR_flag,
gamma_avg => gamma_avg,
done => done_fi,
max_ip_out => max_ip,
gavg_norm_out => gavg_norm,
ip_out => ip,
FI_flag => fi_flag
);

Plant_inst: plant_x port map (
clk => clk,
start => start,
mode => mode,
plt_u => plt_u,
plt_y => plt_y,
done => done,
gamma_out => gamma,
max_gamma_out => max_gamma,
gamma_avg_out => gamma_avg,
plt_z => z_val
);

ila_inst_1: ila_0
PORT MAP (
    clk => clk_ila,
    
    trig_in => trig_in,
    trig_in_ack => trig_in_ack,
    -- Inner product debugging
--    probe0 => probe_ip1, 
--    probe1 => probe_ip2, 
--    probe2 => probe_ip3,  
--    probe3 => probe_ip4, 
--    probe4 => probe_ip5,
--    probe5 => probe_ip6,
--    probe6 => probe_ip7,
--    probe7 => probe_ip8,
--    probe8 => probe_ip9, 
--    probe11 => probe_ip10, 
--    probe12 => probe_ip11, 
--    probe13 => probe_ip12,
--    probe14 => probe_maxip,

    -- probe0 => probe_normfd, 
    -- probe1 => probe_gn0avg, 
    -- probe2 => probe_gn1avg, 
    probe0 => probe_up1,
    probe1 => probe_up2, 
    probe2 => probe_ui,  
    probe3 => probe_gn2avg, 
    probe4 => probe_gn3avg,
    probe5 => probe_ipv,
    probe6 => probe_vpv,
    probe7 => probe_iload,
    probe8 => probe_vc,
    probe11 => probe_z1, 
    probe12 => probe_z2, 
    -- probe13 => probe_maxip,
    probe13 => probe_duty,
    probe14 => probe_il,
    
    probe9 => probe_fd,  -- Fd
    probe10 => probe_fi  -- FI


    
); 
---- Processes ----
-- Main loop
CoreLOOP: process(clk, pc_pwm_top, pc_pwm_bot, pc_en)
 begin
 
 

  if clk'event and clk = '1' then
  
  trig_in <= pc_en;
           
           if pc_en = '1' then


       ---- ILA ----
       
--        probe_gn0 <= result_type(gamma_avg(0));
--        probe_gn1 <= result_type(gamma_avg(1));
--        probe_gn2 <= result_type(gamma_avg(2));
--        probe_gn3 <= result_type(gamma_avg(3));
       
        probe_z1  <= result_type(z_val(0));
        probe_z2 <= result_type(z_val(1)) ; 
        probe_il <= result_type(plt_y(0));
        probe_vc <= result_type(plt_y(1));
        probe_iload <= result_type(plt_u(1));
        probe_vpv <= result_type(plt_u(0));
        probe_ipv <= result_type(plt_u(2));
        -- probe_gn0avg <= result_type(gavg_norm(0));
        -- probe_gn0avg <= result_type(gamma_avg(0));
        -- probe_gn1avg <= result_type(gavg_norm(1));
        probe_gn2avg <= result_type(gavg_norm(2));
        probe_gn3avg <= result_type(gavg_norm(3));
        -- control
        probe_duty <= result_type(duty_control);
        probe_up1 <= result_type(up1);
        probe_up2 <= result_type(up2);
        probe_ui <= result_type(ui);        
        -- probe_normfd <= result_type(max_gamma); 
        -- probe_maxip <= result_type(max_ip);
        probe_fd(0) <= fd_flag;
        probe_fi  <= fi_flag;
        
--        probe_ip1 <= result_type(ip(0));  -- f2
--        probe_ip2 <= result_type(ip(1));  -- f3
--        probe_ip3 <= result_type(ip(2));  -- f4
--        probe_ip4 <= result_type(ip(3));  -- f7
--        probe_ip5 <= result_type(ip(4));  -- f6
--        probe_ip6 <= result_type(ip(5));  -- f9
--        probe_ip7 <= result_type(ip(6));  -- f10, fA
--        probe_ip8 <= result_type(ip(7));  -- f11, fB
--        probe_ip9 <= result_type(ip(8));  -- f12, fC
--        probe_ip10 <= result_type(ip(9)); -- f14, fE
--        probe_ip11 <= result_type(ip(10)); -- f15, fF
--        probe_ip12 <= result_type(ip(11)); -- f1, 

   ---- Output to main ----
   fd_flag_out <= fd_flag;   -- FD observer
   fi_flag_out <= fi_flag;   -- FI observer
   fr_flag_out <= FR_flag;    -- FR
   zval <= z_val;      
   SW_active_out <= SW_active;   
   duty <= duty_control;
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
     
     ---- For constant time step 20 us CONTROL since Ts is 20 us ----
         if (counter_control = 1) then
           start_control <= '1';
           elsif (counter_control = 2) then
           start_control <= '0';
           else null;
         end if; 
          
          if (counter_control = 2000) then
             counter_control <= 0;
             else
             counter_control <= counter_control + 1;
          end if;
                           
    end if; -- pc_en
   end if; -- Clk
 end process; 
 
-- Fault detection logic
fault_detection: process(clk, reset_fd, max_gamma)
               begin
                   if (clk = '1' and clk'event) then
                   
                    -- Fault detection with latch
                      --fd_flag <= '0';
                      if reset_fd = '1' then
                      fd_flag <= '0';
                      elsif max_gamma > fd_th or fd_flag = '1'  then
                      fd_flag <= '1';
                      else
                      fd_flag <= '0';
                      end if; -- fd logic
                      
                 end if; -- clk
             end process; -- process

end Behavioral;
