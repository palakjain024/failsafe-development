--Processor Core for estimator and fault detection and identification for 500 ns
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;

entity processor_core is
Port ( -- General
       Clk : in STD_LOGIC;
       reset_fd : in STD_LOGIC;
       -- Converter fault flag;
       FD_flag : out STD_LOGIC := '0';
       -- Converter FI flag
       FI_flag : out STD_LOGIC_Vector(2 downto 0):= (others => '0');
       -- Observer inputs
       pc_pwm : in STD_LOGIC;
       load : in sfixed(n_left downto n_right);
       pc_x : in vect2;
       -- FD logic
       FD_residual_out : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       pc_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
       -- C Filter
       C_residual_out : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       C_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
       ); 
end processor_core;

architecture Behavioral of processor_core is

 -- Component definition
 -- Converter estimator
 component plant_x
 port (   Clk : in STD_LOGIC;
          Start : in STD_LOGIC;
          Mode : in INTEGER range 0 to 2;
          load : in sfixed(n_left downto n_right);
          plt_x : in vect2;
          done : out STD_LOGIC := '0';
          FD_residual : out sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
          plt_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
           );
 end component plant_x;
 -- C Filter
 Component Filter_C 
 port (      Clk : in STD_LOGIC;
             Start : in STD_LOGIC;
             flag : in STD_LOGIC;
             Mode : in INTEGER range 0 to 2;
             load : in sfixed(n_left downto n_right);
             plt_x : in vect2;
             done : out STD_LOGIC := '0';
             C_residual : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
             C_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
          );
 end component Filter_C;
 
----------------------------------------------------------------------------
 -- Signal definition for components
 
 -- General
 signal counter : integer range 0 to 50000 := -1;
 
 -- Common Inputs 
 signal Start : STD_LOGIC := '0';
 signal Mode  : INTEGER range 0 to 2 := 0;
 
 -- Plant outputs and Fault detection logic
 signal done: STD_LOGIC := '1';
 signal z_val: vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
 signal FD_residual : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
 signal flag : STD_LOGIC := '0';
 
 -- Fault identification
 -- C Filter
 signal C_done : STD_LOGIC := '1';
 signal C_residual : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
 --signal C_residual_avg : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);

 
begin

Plant_inst: plant_x port map (
Clk => clk,
Start => start,
Mode => mode,
load => load,
plt_x => pc_x,
Done => done,
FD_residual => FD_residual,
plt_z => z_val
);

filterc_inst: Filter_C port map (
Clk => clk,
Start => start,
flag => flag,
Mode => mode,
load => load,
plt_x => pc_x,
Done => C_done,
C_residual => C_residual,
C_zval => C_zval
);


 -- Processes
CoreLOOP: process(clk, pc_pwm)
        begin

            if clk'event and clk = '1' then
                    -- Output to main
                    pc_z <= z_val;
                    FD_flag <= flag;
                    FD_residual_out <= FD_residual;
                    
                    C_residual_out <= C_residual;
           
                    -- To determine Mode
                    if counter = 0 then
                            if (pc_pwm = '0') then
                            -- Mode
                              mode <= 0;
                            elsif(pc_pwm = '1') then
                            -- Mode
                                mode <= 1; 
                            else mode <= 0;
                            end if;
                     end if;   
                  -- For constant time step 500 ns Matrix Mutiplication to run  
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
                               
        end if;
    end process; 

---------- Fault detection logic -------------------------
fault_detection: process(clk, reset_fd, FD_residual)
              begin
                  if (clk = '1' and clk'event) then
                   -- Fault detection
                     flag <= '0';
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
