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
       -- Converter fault flag
       FD_flag : out STD_LOGIC;
       reset_fd : in STD_LOGIC;
       -- FI flag
       FI_flag : out STD_LOGIC_Vector(2 downto 0):= (others => '0');
       -- Observer inputs
       pc_pwm : in STD_LOGIC;
       load : in sfixed(n_left downto n_right);
       pc_x : in vect2;
       -- FD logic
       err_val : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
       residual_funct : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       norm : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right); 
       pc_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
        -- Fault identification
       C_residual_out : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       C_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
       L_residual_out : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       L_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
       SW_residual_out : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       SW_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
       R_residual : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       R_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))        
          );     
end processor_core;

architecture Behavioral of processor_core is
 -- Component definition
 -- Converter estimator
 component plant_x
 port (    Clk : in STD_LOGIC;
           Start : in STD_LOGIC;
           Mode : in INTEGER range 0 to 2;
           load : in sfixed(n_left downto n_right);
           plt_x : in vect2;
           done : out STD_LOGIC := '0';
           plt_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
        );
 end component plant_x;
 
 component Filter_C
 port (      Clk : in STD_LOGIC;
             Start : in STD_LOGIC;
             flag : in STD_LOGIC;
             Mode : in INTEGER range 0 to 2;
             load : in sfixed(n_left downto n_right);
             plt_x : in vect2;
             done : out STD_LOGIC := '0';
             C_norm : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
             C_residual : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
             C_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
           );
 end component Filter_C;
 
 component Filter_L
 port (       Clk : in STD_LOGIC;
              Start : in STD_LOGIC;
              flag : in STD_LOGIC;
              Mode : in INTEGER range 0 to 2;
              load : in sfixed(n_left downto n_right);
              plt_x : in vect2;
              done : out STD_LOGIC := '0';
              L_norm : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
              L_residual : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
              L_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
           );
  end component Filter_L;
  
 component Filter_SW
   port (      Clk : in STD_LOGIC;
                Start : in STD_LOGIC;
                 flag : in STD_LOGIC;
                Mode : in INTEGER range 0 to 2;
                load : in sfixed(n_left downto n_right);
                plt_x : in vect2;
                done : out STD_LOGIC := '0';
                SW_norm : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
                SW_residual : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
                SW_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
             );
  end component Filter_SW;
  
  Component Filter_R
   port (      Clk : in STD_LOGIC;
               Start : in STD_LOGIC;
               Mode : in INTEGER range 0 to 2;
               load : in sfixed(n_left downto n_right);
               plt_x : in vect2;
               done : out STD_LOGIC := '0';
               R_norm : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
               R_residual : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
               R_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
            );
  end component Filter_R;
-- fault identification logic
component moving_avg is
Port ( clk : in STD_LOGIC;
           start : in STD_LOGIC;
           datain : in sfixed(n_left downto n_right);
           done: out STD_LOGIC;
           avg: out sfixed(n_left downto n_right)
      );
end component moving_avg;
 
component fault_identification
 Port ( 
            clk : in STD_LOGIC;
            start : in STD_LOGIC;
            FD_flag : in STD_LOGIC;
            Residual  : in vect3;
            done : out STD_LOGIC := '0';
            FI_flag : out STD_LOGIC_Vector(2 downto 0):= (others => '0')
          );
end component fault_identification;
----------------------------------------------------------------------------
 -- Signal definition for components
 -- INPUT  
 signal start : STD_LOGIC := '0';
 signal mode  : INTEGER range 0 to 2 := 0;
 
 -- OUTPUT
 signal done: STD_LOGIC := '1';
 signal z_val: vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
 
 -- Fault detection
 signal err_val_out : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
 signal norm_out : sfixed(n_left downto n_right):= to_sfixed(0, n_left, n_right);
 signal residual_funct_out : sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
 signal residual_eval_out : sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
 signal flag : STD_LOGIC := '0';
 
 -- Fault identificatiom
 signal C_norm : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
 signal C_done : STD_LOGIC := '1';
 signal L_norm : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
 signal L_done : STD_LOGIC := '1';
 signal SW_norm : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
 signal SW_done : STD_LOGIC := '1';
 signal R_norm : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
 signal R_done : STD_LOGIC := '1';
 
 -- Fault identification logic
 signal C_residual, L_residual, SW_residual: sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
 signal C_residual_avg, L_residual_avg, SW_residual_avg: sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
 signal L_done_avg, C_done_avg, SW_done_avg, fi_done : STD_LOGIC := '1';
 signal Residual: vect3 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
 
 -- Misc
 signal A_ref : sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
 signal Ad_ref : sfixed(d_left downto d_right) := to_sfixed(0, d_left, d_right);
 signal B_ref : sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
 signal P_ref : sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
 signal Sum_ref : sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
 signal counter: integer range -1 to 50000 := 0;
 
begin

Plant_inst: plant_x port map (
Clk => clk,
Start => start,
Mode => mode,
load => load,
plt_x => pc_x,
Done => done,
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
C_norm => C_norm,
C_residual => C_residual,
C_zval => C_zval
);

filterl_inst: Filter_L port map (
Clk => clk,
Start => start,
flag => flag,
Mode => mode,
load => load,
plt_x => pc_x,
Done => L_done,
L_norm => L_norm,
L_residual => L_residual,
L_zval => L_zval
);

filterSW_inst: Filter_SW port map (
Clk => clk,
Start => start,
flag => flag,
Mode => mode,
load => load,
plt_x => pc_x,
Done => SW_done,
SW_norm => SW_norm,
SW_residual => SW_residual,
SW_zval => SW_zval
);

filterR_inst: Filter_R port map (
Clk => clk,
Start => start,
Mode => mode,
load => load,
plt_x => pc_x,
Done => R_done,
R_norm => R_norm,
R_residual => R_residual,
R_zval => R_zval
);
-------- Fault Identification logic --------
moving_avg_inst_C: moving_avg port map (
clk => clk,
start => start,
datain => C_residual,
done => C_done_avg,
avg => C_residual_avg
 );
 
moving_avg_inst_L: moving_avg port map (
 clk => clk,
 start => start,
 datain => L_residual,
 done => L_done_avg,
 avg => L_residual_avg
  );
  
moving_avg_inst_SW: moving_avg port map (
  clk => clk,
  start => start,
  datain => SW_residual,
  done => SW_done_avg,
  avg => SW_residual_avg
   );
 
FI_inst: fault_identification port map (
  clk => clk,
  start => start,
  FD_flag => flag,
  Residual => Residual,
  done => FI_done,
  FI_flag => FI_flag
  );


CoreLOOP: process(clk, pc_pwm)
begin

if clk'event and clk = '1' then
            -- Output to main
            pc_z <= z_val;
            err_val <= err_val_out;
            residual_funct <= residual_funct_out;
            norm <= norm_out;
            --residual_eval <= residual_eval_out;
            FD_flag <= flag;
            C_Residual_out <= C_residual;
            L_Residual_out <= L_residual;
            SW_Residual_out <= SW_residual;
            
            
            -- FI logic
            Residual(0) <= C_Residual_avg;
            Residual(1) <= L_Residual_avg;
            Residual(2) <= SW_Residual_avg;
             
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

---------- Fault detection logic -------------------------
fault_detection: process(clk, reset_fd)
            
    type state_value is (S0, S1, S2, S3, S4, S5, S6);
    variable State : state_value := S0;
              begin
                  if (clk = '1' and clk'event) then
                   -- Fault detection
                   
                     flag <= '0';
                     if residual_eval_out > fd_th or flag = '1' then
                     
                     flag <= '1';
                         if (reset_fd = '1') then
                         flag <= '0';
                         else
                         flag <= '1';
                         end if;
                     else
                     flag <= '0';
                     end if;
                     
                    case state is
                            
                            when S0 =>
                                       if( Start = '1' ) then
                                           err_val_out(0) <= resize(pc_x(0) - z_val(0), n_left, n_right);
                                           err_val_out(1) <= resize(pc_x(1) - z_val(1), n_left, n_right);
                                           State := S1;
                                       else
                                           State := S0;
                                       end if;
                            when S1 =>
                            A_ref <= err_val_out(0);
                            B_ref <= err_val_out(0);
                            State := S2;
                            
                            when S2 =>
                            A_ref <= err_val_out(1);
                            B_ref <= err_val_out(1);
                            P_ref <= resize(A_ref*B_ref, n_left, n_right);
                            State := S3;
                            
                            when S3 =>
                            P_ref <= resize(A_ref*B_ref, n_left, n_right);
                            Sum_ref <= P_ref;
                            State := S4;
                            
                            when S4 =>
                            norm_out <= resize(Sum_ref + P_ref, n_left, n_right);
                            State := S5;
                            
                            when S5 =>
                            A_ref <= resize(to_sfixed(0.999995,d_left,d_right) * residual_funct_out, n_left, n_right);
                            Ad_ref <= resize(h*norm_out, d_left, d_right);
                            State := S6;
                            
                            when S6 =>
                            residual_funct_out <= resize(A_ref + Ad_ref, n_left, n_right);
                            residual_eval_out <= resize(norm_out + residual_funct_out, n_left, n_right);                             
                            State := S0;  
                   end case;
             end if;
     end process;
 end Behavioral;
