library IEEE;
library IEEE_PROPOSED;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
library work;
use work.input_pkg.all;

entity tb_theta is
end tb_theta;

architecture Behavioral of tb_theta is
 
 -- Component definitions
 component processor_core
        Port ( -- General
        Clk : in STD_LOGIC;
        ena : in STD_LOGIC;
        -- Converter state estimator
        pc_pwm : in STD_LOGIC;
        load : in sfixed(n_left downto n_right);
        pc_x : in vect2;
        theta_done : out STD_LOGIC;
        pc_theta : out vect2 := (to_sfixed(200,n_left,n_right),to_sfixed(6667,n_left,n_right));
        pc_err : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
        pc_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
           );   
 end component processor_core;
 
 component actual_x
   port (   Clk : in STD_LOGIC;
            Start : in STD_LOGIC;
            Mode : in INTEGER range 0 to 2;
            pulsed_load : in sfixed(n_left downto n_right);
            Done : out STD_LOGIC := '0';
            plt_x : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
            );
 end component actual_x;
 
 component perturb_load
 Port ( clk : in STD_LOGIC;
        pulsed_load : out sfixed(n_left downto n_right) := to_sfixed(2, n_left, n_right) );
 end component perturb_load;
 
 component pwm
   PORT(
       clk       : IN  STD_LOGIC;                                    --system clock
       reset_n   : IN  STD_LOGIC;                                    --asynchronous reset
       ena       : IN  STD_LOGIC;                                    --latches in new duty cycle
       duty      : IN  sfixed(n_left downto n_right);                       --duty cycle (range given by bit resolution)
       pwm_out   : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '0');          --pwm outputs
       pwm_n_out : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '0'));   
 end component pwm;
 
 component deadtime_test
        Port ( clk : in STD_LOGIC;
              p_Pwm_In : in STD_LOGIC;
              p_Pwm1_Out : out STD_LOGIC := '0';
              p_Pwm2_Out : out STD_LOGIC := '0');
 end component deadtime_test;  
   
 -- signal definitions
 -- INPUT  Mult_Mat
  signal clk :  STD_LOGIC;
  signal pulsed_load : sfixed(15 downto -16);
  signal plt_x : vect2;
  signal start : STD_LOGIC := '0';
  signal done, theta_done  : STD_LOGIC;
  signal mode : integer range 0 to 2;
  -- OUTPUT
  signal theta_val: vect2;
  signal z, err : vect2;
  -- Misc
  signal counter: integer range -1 to f_load;
  -- pwm
  signal pwm_out   : STD_LOGIC_VECTOR(phases-1 DOWNTO 0);        --pwm outputs
  signal pwm_n_out : STD_LOGIC_VECTOR(phases-1 DOWNTO 0);         --pwm inverse outputs
  -- Deadtime
  signal p_pwm1_out: std_logic;  --pwm outputs with dead band
  signal p_pwm2_out: std_logic;  --pwm inverse outputs with dead band  
  --Syn
  signal ena : STD_LOGIC := '0';
  
begin
pwm_inst: pwm 
 port map(
    clk => clk, 
    reset_n => '1', 
    ena => '1', 
    duty => to_sfixed(0.5, n_left, n_right), 
    pwm_out => pwm_out, 
    pwm_n_out => pwm_n_out);

deadtime_inst: deadtime_test  
port map(
    p_pwm_in => pwm_out(0), 
    clk => clk, 
    p_pwm1_out => p_pwm1_out, 
    p_pwm2_out => p_pwm2_out);
    
Load: perturb_load port map (
        clk => clk,
        pulsed_load => pulsed_load);
        
clk_p: process
begin
clk <= '1';
wait for 5 ns;
clk <= '0';
wait for 5 ns;
end process;

pc_inst: processor_core port map (
clk => clk,
ena => ena,
pc_pwm => p_pwm1_out,
load => pulsed_load,
pc_x => plt_x,
theta_done => theta_done,
pc_theta => theta_val,
pc_err => err,
pc_z => z);
 
pmm_inst: actual_x port map (
clk => clk,
start => start,
mode => mode,
pulsed_load => pulsed_load,
done => done,
plt_x => plt_x);
        
mainLOOP: process(clk, p_pwm1_out)
begin

if p_pwm1_out'event and p_pwm1_out = '1' then
ena <= '1';
end if;

if clk'event and clk = '1' then
  --- For Mode Selection
               
       if counter = 0 then
               if (p_pwm1_out = '0') then
                mode <= 0;
                elsif(p_pwm1_out = '1') then
                mode <= 1; 
                else mode <= 0;
                -- fault <= '1';
                end if;
       end if;   
 -- For constant time step 500 ns Matrix Mutiplication to run  
                    if (counter = 2) then
                      start <= '1';
                      elsif (counter = 6) then
                        start <= '0';
                    end if;
                     
                     if (counter = 49) then
                        counter <= 0;
                        else
                        counter <= counter + 1;
                     end if;             
end if;
end process;                     

end Behavioral;