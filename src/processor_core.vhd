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
       -- Input fault flag
       input_f : in STD_LOGIC;
       FI_vin : out STD_LOGIC;
       -- Converter fault flag;
       FD_flag : out STD_LOGIC;
       FI_flag :out STD_LOGIC_VECTOR(1 downto 0); 
       -- Converter state estimator
       pc_pwm : in STD_LOGIC;
       load : in sfixed(n_left downto n_right);
       pc_x : in vect2;
       ip: inout ip_array := (to_sfixed(0, n_left, n_right), to_sfixed(0, n_left, n_right));
       avg_norm_p: out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
       pc_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
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
       Done : out STD_LOGIC := '0';
       plt_x : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
            );
 end component plant_x;
 -- Fault identification
 component fault_identification
  Port ( 
           clk : in STD_LOGIC;
           start : in STD_LOGIC;
           FD_flag : in STD_LOGIC;
           avg_norm : in vect2;
           done : out STD_LOGIC := '0';
           ip: inout ip_array := (to_sfixed(0, n_left, n_right), to_sfixed(0, n_left, n_right));
           FI_flag : out STD_LOGIC_Vector(1 downto 0):= (others => '0')
         );
 end component;
 --Moving average
 component moving_avg is
  Port ( clk : in STD_LOGIC;
         start : in STD_LOGIC;
         datain : in sfixed(n_left downto n_right);
         done: out STD_LOGIC;
         avg: out sfixed(n_left downto n_right)
        );
 end component moving_avg;
 
 -- Signal definition for components
 
 -- fault identification
 signal fd_value: sfixed(d_left downto d_right);
 signal flag: STD_LOGIC; 
 
 
 signal err_val, z_val, abs_err_val: vect2;
 signal norm: vect2;
 signal abs_norm: vect2;
 -- Moving avg
 signal avg_norm: vect2;
  -- INPUT  
 signal start : STD_LOGIC := '0';
 signal mode  : INTEGER range 0 to 2 := 0;
 -- OUTPUT
 signal done, done_avg_il, done_avg_vc, done_FI : STD_LOGIC := '1';
 -- Misc
 signal counter: integer range -1 to f_load;
 
begin

Plant_inst: plant_x port map (
Clk => clk,
Start => start,
Mode => mode,
load => load,
Done => done,
plt_x => z_val
);

moving_avg_gamma_il: moving_avg port map (
clk => clk,
start => start,
datain => norm(0),
done => done_avg_il,
avg => avg_norm(0));

moving_avg_gamma_vc: moving_avg port map (
clk => clk,
start => start,
datain => norm(1),
done => done_avg_vc,
avg => avg_norm(1));

fI_inst: fault_identification port map (
clk => clk,
start => start,
FD_flag => flag,
avg_norm => avg_norm,
done => done_FI,
ip => ip,
FI_flag => FI_flag);

CoreLOOP: process(clk, pc_pwm)
begin

if clk'event and clk = '1' then
            pc_z <= z_val;
            avg_norm_p <= avg_norm;
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
                    if (counter = 2) then
                      start <= '1';
                      elsif (counter = 3) then
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
------------------------------
fault_detection: process(clk)
            
        type state_value is (S0, S1, S2, S3, S4, S5);
        variable State : state_value := S0;
              begin
                  if (clk = '1' and clk'event) then
                   
                    case state is
                            
                            when S0 =>
                                       if( Start = '1' ) then
                                           State := S1;
                                       else
                                           State := S0;
                                       end if;
                            when S1 =>
                            err_val(0) <= resize(pc_x(0) - z_val(0), n_left, n_right);
                            err_val(1) <= resize(pc_x(1) - z_val(1), n_left, n_right);
                            State := S2;
                            
                            when S2 =>
                            abs_err_val(0) <= resize(abs(err_val(0)), n_left, n_right);
                            abs_err_val(1) <= resize(abs(err_val(1)), n_left, n_right);
                            norm(0) <= resize(err_val(0)*to_sfixed(0.2, n_left, n_right), n_left, n_right);
                            norm(1) <= resize(err_val(1)*to_sfixed(0.005, n_left, n_right), n_left, n_right);
                            State := S3;
                            
                            when S3 =>
                            abs_norm(0) <= resize(abs(norm(0)), n_left, n_right);
                            abs_norm(1) <= resize(abs(norm(1)), n_left, n_right);
                            State := S4;
                            
                            when S4 =>
                            -- Calculation of infinity norm       
                            if abs_norm(0) >= abs_norm(1) then
                            fd_value <= resize(abs_norm(0), d_left, d_right);
                            else
                            fd_value <= resize(abs_norm(1), d_left, d_right);
                            end if;
                            State := S5;
                            
                            when S5 =>
                            
                            -- Fault detection and identification when input fault, here can think of implementing both input fault as well as other converter faults (Multiple faults)
                            -- Single fault case
                            if input_f = '1' then
                               FI_vin <= '1'; -- output port
                               FD_flag <= '1';
                            else
                             -- Fault detection if no input fault
                               if fd_value > to_sfixed(0.2, d_left, d_right) then
                               FD_flag <= '1'; -- output port
                               flag <= '1';
                               else
                               FD_flag <= '0';
                               flag <= '0';
                               end if;
                               FI_vin <= '0';
                            end if;
                            
                            State := S0;  
                   end case;
             end if;
     end process;
end Behavioral;
