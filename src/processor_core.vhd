--Processor Core for estimator
library IEEE;
library IEEE_PROPOSED;
library work;

use work.input_pkg.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;


entity processor_core is
Port ( -- General
       Clk : in STD_LOGIC;
       pc_enable : in STD_LOGIC;
       pc_pwm : in STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '1');
       u_inp : in vect7;
       -- Converter fault flag;
       FD_flag : out STD_LOGIC := '0';
       pc_err_val : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
       -- Converter state estimator
       pc_z : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right))
          );   
end processor_core;

architecture Behavioral of processor_core is
 -- Component definition
 -- ila core
 COMPONENT ila_0
 
 PORT (
     clk : IN STD_LOGIC;
 
 
 
     probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
     probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
     probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
     probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
 );
 END COMPONENT  ;
 -- Converter estimator
 component plant_x
 port (Clk   : in STD_LOGIC;
       Start : in STD_LOGIC;
       Mode  : in INTEGER range 1 to 8;
       u_inp : in vect7;
       Done  : out STD_LOGIC := '0';
       plt_z : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right))
       );
 end component plant_x;
 
 -- Signal definition for components
 --ila core
 signal probe0_pil, probe1_zil, probe2_eil : STD_LOGIC_VECTOR(31 downto 0); 
-- Estimator for 3p Inverter
  -- INPUT  
 signal start : STD_LOGIC := '0';
 signal mode  : INTEGER range 1 to 8 := 1;
 
 -- OUTPUT
 signal done  : STD_LOGIC;
 signal z_val : vect3;
 
 -- Misc
 signal err_val : vect3;
 signal counter: integer range 0 to pwm_freq := 0;
 
begin

Plant_inst: plant_x port map (
Clk => clk,
Start => start,
Mode => mode,
u_inp => u_inp,
Done => done,
plt_z => z_val
);

FD_loop: process(clk, u_inp)
begin

  if clk'event and clk = '1' then
        err_val(0) <= resize(z_val(0) + u_inp(4), n_left, n_right);      
        err_val(1) <= resize(z_val(1) + u_inp(5), n_left, n_right);
        err_val(2) <= resize(z_val(2) + u_inp(6), n_left, n_right);
  end if; -- For clk
  
end process;


CoreLOOP: process(clk, pc_pwm, pc_enable)
begin

if clk'event and clk = '1' then
 
    -- Output of estimator
       pc_err_val <= err_val;
       pc_z <= z_val;
       probe0_pil <= result_type(u_inp(4));
       probe1_zil <= result_type(z_val(0));
       probe2_eil <= result_type(err_val(0));
                
    if pc_enable = '1' then  
    
                -- Mode selection
                if counter = 0 then
            
                       if (pc_pwm(0) = '1' and pc_pwm(1) = '1' and pc_pwm(2) = '1') then
                        -- Mode 1
                           mode <= 1;
                        elsif (pc_pwm(0) = '1' and pc_pwm(1) = '1' and pc_pwm(2) = '0') then
                        -- Mode 2
                           mode <= 2;
                        elsif (pc_pwm(0) = '1' and pc_pwm(1) = '0' and pc_pwm(2) = '1') then
                        -- Mode 3
                           mode <= 3;
                        elsif (pc_pwm(0) = '1' and pc_pwm(1) = '0' and pc_pwm(2) = '0') then
                        -- Mode 4
                           mode <= 4;
                        elsif (pc_pwm(0) = '0' and pc_pwm(1) = '1' and pc_pwm(2) = '1') then
                        -- Mode 5
                           mode <= 5;
                        elsif (pc_pwm(0) = '0' and pc_pwm(1) = '1' and pc_pwm(2) = '0') then
                        -- Mode 6
                           mode <= 6;
                        elsif (pc_pwm(0) = '0' and pc_pwm(1) = '0' and pc_pwm(2) = '1') then
                        -- Mode 7
                           mode <= 7;   
                        elsif (pc_pwm(0) = '0' and pc_pwm(1) = '0' and pc_pwm(2) = '0') then
                        -- Mode 8
                           mode <= 8; 
                        else null;
                        end if;
          
                end if; 
            
        -- For constant time step 500 ns Matrix Mutiplication to run  
            if (counter = 0) then
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
                     
        end if; -- For pc_enable                    
  end if; -- For clk
end process; 

ila_core_inst: ila_0
PORT MAP (
	clk => clk,



	probe0 => probe0_pil, 
	probe1 => probe1_zil, 
	probe2 => probe2_eil,
	probe3(0) => pc_enable
);

end Behavioral;
