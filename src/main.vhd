-- Top Module
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;

entity main is
    Port ( -- General
           clk : in STD_LOGIC;
           pwm_f: in STD_LOGIC;
           -- PWM ports
           pwm_out_t : out STD_LOGIC_VECTOR(phases-1 downto 0);
           pwm_n_out_t : out STD_LOGIC_VECTOR(phases-1 downto 0);
           -- Flags
           FD_flag : out STD_LOGIC;
           reset_fd : in STD_LOGIC;
           FI_flag : out STD_LOGIC_Vector(2 downto 0):= (others => '0');
           -- DAC ports 1
           DA_DATA1 : out STD_LOGIC;
           DA_DATA2 : out STD_LOGIC;
           DA_CLK_OUT_1 : out STD_LOGIC;
           DA_nSYNC_1 : out STD_LOGIC;
           -- DAC ports 2
           DA_DATA3 : out STD_LOGIC;
           DA_DATA4 : out STD_LOGIC;
           DA_CLK_OUT_2 : out STD_LOGIC;
           DA_nSYNC_2 : out STD_LOGIC;
           -- ADC ports 1
           AD_CS_1 : out STD_LOGIC;
           AD_D0_1 : in STD_LOGIC;
           AD_D1_1 : in STD_LOGIC;
           AD_SCK_1 : out STD_LOGIC;
           -- ADC ports 2
           AD_CS_2 : out STD_LOGIC;
           AD_D0_2 : in STD_LOGIC;
           AD_D1_2 : in STD_LOGIC;
           AD_SCK_2 : out STD_LOGIC
         );
end main;

architecture Behavioral of main is

-- Component definitions
-- PWM Module
component pwm
    PORT(
        clk       : IN  STD_LOGIC;                                    --system clock
        reset_n   : IN  STD_LOGIC;                                    --asynchronous reset
        ena       : IN  STD_LOGIC;                                    --latches in new duty cycle
        duty      : IN  sfixed(n_left downto n_right);                       --duty cycle
        pwm_out   : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '0');          --pwm outputs
        pwm_n_out : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '0'));          --pwm inverse outputs
end component pwm;
-- Dead Time Module
component deadtime_test
         Port ( clk : in STD_LOGIC;
               p_Pwm_In : in STD_LOGIC;
               p_Pwm1_Out : out STD_LOGIC := '0';
               p_Pwm2_Out : out STD_LOGIC := '0');
end component deadtime_test;
-- DAC Module
component pmodDA2_ctrl
     Port ( 
      CLK : in STD_LOGIC;
      RST : in STD_LOGIC;
      D1 : out STD_LOGIC;
      D2 : out STD_LOGIC;
      CLK_OUT : out STD_LOGIC;
      nSYNC : out STD_LOGIC;
      DATA1 : in STD_LOGIC_VECTOR(11 downto 0);
      DATA2 : in STD_LOGIC_VECTOR(11 downto 0);
      START : in STD_LOGIC;
      DONE : out STD_LOGIC
            );
end component;
-- ADC Module
component pmodAD1_ctrl
    Port    (    

    CLK      : in std_logic;         
    RST      : in std_logic;
    SDATA1   : in std_logic;
    SDATA2   : in std_logic;
    SCLK     : out std_logic;
    nCS      : out std_logic;
    DATA1    : out std_logic_vector(11 downto 0);
    DATA2    : out std_logic_vector(11 downto 0);
    START    : in std_logic; 
    DONE     : out std_logic
            );
end component;
-- Descaler for ADC
component descaler
     Generic(
  adc_Factor : sfixed(15 downto -16));
  Port ( clk : in STD_LOGIC;
         start : in STD_LOGIC;
         adc_in : in STD_LOGIC_VECTOR(11 downto 0);
         done : out STD_LOGIC := '0';
         adc_val : out sfixed(n_left downto n_right)
       );
end component;     
-- Scaler for DAC
component scaler
Generic(
    dac_left : integer range -100 to 100;
    dac_right : integer range -100 to 100;
    dac_max : sfixed(n_left downto n_right);
    dac_min : sfixed(n_left downto n_right));
    Port ( clk : in STD_LOGIC;
           dac_in : in sfixed(dac_left downto dac_right);
           dac_val : out STD_LOGIC_VECTOR(11 downto 0));
end component;
-- Processor core
component processor_core
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
       --C_residual_avg_out : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       C_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
       -- L Filter
       L_residual_out : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       L_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
       -- SW Filter
       SW_residual_out : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       SW_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
       ); 
end component processor_core;

 
-- Signal Definition 

-- pwm
signal pwm_out   : STD_LOGIC_VECTOR(phases-1 DOWNTO 0);        --pwm outputs
signal pwm_n_out : STD_LOGIC_VECTOR(phases-1 DOWNTO 0);         --pwm inverse outputs
signal ena : STD_LOGIC := '0';
signal duty_ratio : sfixed(n_left downto n_right) := to_sfixed(0.5,n_left,n_right);
signal duty : sfixed(n_left downto n_right) := to_sfixed(0.5,n_left,n_right);

-- Deadtime
signal p_pwm1_out: std_logic;  --pwm outputs with dead band
signal p_pwm2_out: std_logic;  --pwm inverse outputs with dead band  

-- DAC signals         
signal DA_sync1: STD_LOGIC;
signal DA_sync2: STD_LOGIC;
-- DAC scaler output
signal dac_1: std_logic_vector(11 downto 0);
signal dac_2: std_logic_vector(11 downto 0);
signal dac_3: std_logic_vector(11 downto 0);
signal dac_4: std_logic_vector(11 downto 0);

-- ADC Descaler inputs
signal load : sfixed(n_left downto n_right) := to_sfixed(2,n_left,n_right) ;
signal il_offset : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right) ;
signal plt_x : vect2 := (to_sfixed(3,n_left,n_right),to_sfixed(175,n_left,n_right));
signal de_done_il, de_done_vc, de_done_load : STD_LOGIC;

-- ADC signals
signal AD_sync_1, AD_sync_2: STD_LOGIC;
signal adc_load, adc_no_use : std_logic_vector(11 downto 0) := (others => '0');
signal adc_vc, adc_il : std_logic_vector(11 downto 0) := (others => '0');

-- Processor core
signal FD_residual:  sfixed(n_left downto n_right);
signal z_val : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
signal C_residual:  sfixed(n_left downto n_right);
signal C_zval: vect2;
signal L_residual:  sfixed(n_left downto n_right);
signal L_zval : vect2;
signal SW_residual:  sfixed(n_left downto n_right);
signal SW_zval : vect2;
--signal C_residual_avg:  sfixed(n_left downto n_right);

begin

-- PWM and Deadtime module
pwm_inst: pwm 
 port map(
    clk => clk, 
    reset_n => '1', 
    ena => ena, 
    duty => duty, 
    pwm_out => pwm_out, 
    pwm_n_out => pwm_n_out);

deadtime_inst: deadtime_test  
port map(
    p_pwm_in => pwm_out(0), 
    clk => clk, 
    p_pwm1_out => p_pwm1_out, 
    p_pwm2_out => p_pwm2_out);
 
-- ADC and DAC
dac_1_inst: pmodDA2_ctrl port map (
    CLK => CLK,
    RST => '0', 
    D1 => DA_DATA1, 
    D2 => DA_DATA2, 
    CLK_OUT => DA_CLK_OUT_1, 
    nSYNC => DA_nSYNC_1, 
    DATA1 => dac_1, 
    DATA2 => dac_2, 
    START => DA_sync1, 
    DONE => DA_sync1);
dac_2_inst: pmodDA2_ctrl port map (
        CLK => CLK,
        RST => '0', 
        D1 => DA_DATA3, 
        D2 => DA_DATA4, 
        CLK_OUT => DA_CLK_OUT_2, 
        nSYNC => DA_nSYNC_2, 
        DATA1 => dac_3, 
        DATA2 => dac_4, 
        START => DA_sync2, 
        DONE => DA_sync2);
adc_1_inst: pmodAD1_ctrl port map (
    CLK => CLK,       
    RST => '0',
    SDATA1 => AD_D0_1,
    SDATA2 => AD_D1_1, 
    SCLK   => AD_SCK_1,
    nCS    => AD_CS_1,
    DATA1  => adc_load,    -- Load
    DATA2  => adc_no_use,  -- Not using 
    START  => AD_sync_1, 
    DONE   => AD_sync_1
);
adc_2_inst: pmodAD1_ctrl port map (
        CLK => CLK,       
        RST => '0',
        SDATA1 => AD_D0_2,
        SDATA2 => AD_D1_2, 
        SCLK   => AD_SCK_2,
        nCS    => AD_CS_2,
        DATA1  => adc_il,  --Inductor current
        DATA2  => adc_vc,  --Capacitor voltage 
        START  => AD_sync_2, 
        DONE   => AD_sync_2
        );  
        
-- ADC Retrieval
de_inst_load: descaler generic map (adc_factor => to_sfixed(10,15,-16) )
            port map (
            clk => clk,
            start => AD_sync_1,
            adc_in => adc_load,
            done => de_done_load,
            adc_val => load);
de_inst_il: descaler generic map (adc_factor => to_sfixed(10,15,-16) )
            port map (
            clk => clk,
            start => AD_sync_2,
            adc_in => adc_il,
            done => de_done_il,
            adc_val => plt_x(0));
de_inst_vc: descaler generic map (adc_factor => to_sfixed(200,15,-16) )
            port map (
            clk => clk,
            start => AD_sync_2,
            adc_in => adc_vc,
            done => de_done_vc,
            adc_val => plt_x(1));   
        
-- DAC Scaler       
scaler_theta_l: scaler generic map (
              dac_left => n_left,
              dac_right => n_right,
              dac_max => to_sfixed(1000,15,-16),
              dac_min => to_Sfixed(0,15,-16)
              )
              port map (
              clk => clk,
              dac_in => C_residual,  -- For capacitor
              dac_val => dac_1);                  
scaler_theta_c: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(1000,15,-16),
            dac_min => to_sfixed(0,15,-16)
            )
            port map (
            clk => clk,
            dac_in => L_residual,  -- For inductor
            dac_val => dac_2);
scaler_theta_sw: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(1000,15,-16),
            dac_min => to_sfixed(0,15,-16)
            )
            port map (
            clk => clk,
            dac_in => SW_residual,  -- For switch
            dac_val => dac_3);
scaler_theta_fd: scaler generic map (
            dac_left => n_left,
            dac_right => n_right,
            dac_max => to_sfixed(10,15,-16),
            dac_min => to_sfixed(0,15,-16)
            )
            port map (
            clk => clk,
            dac_in => FD_residual,  -- For FD observer
            dac_val => dac_4);
            
-- Processor_core
pc_inst: processor_core port map (
            Clk => clk,
            FD_flag => FD_flag,
            reset_fd => reset_fd,
            FI_flag => FI_flag,
            pc_pwm => p_pwm2_out,
            load => load,
            pc_x => plt_x,
            FD_residual_out => FD_residual,
            pc_z => z_val,
            C_residual_out => C_residual,
            C_zval => C_zval,
            L_residual_out => L_residual,
            L_zval => L_zval,
            SW_residual_out => SW_residual,
            SW_zval => SW_zval
            ); 
                         
-- Main loop
main_loop: process (clk)
 begin
     if (clk = '1' and clk'event) then
              
              -- ADC value (Switch fault causes current to go negative)
              -- plt_x(0) <= resize(il_offset - offset_adc, n_left, n_right);
             if pwm_f = '0' then
               pwm_out_t(0) <= p_pwm1_out;
               pwm_n_out_t(0)  <= p_pwm2_out;
             else
               pwm_out_t(0) <= '0';
               pwm_n_out_t(0)  <= '1';
             end if;                                 
 
      end if;
 end process main_loop;


-- duty cycle cal
duty_cycle_uut: process (clk)

type state_variable is (S0, S1);
variable state: state_variable := S0;

begin
   if (clk = '1' and clk'event) then
      case state is

       when S0 =>
       ena <= '0';
       duty_ratio <= resize(v_in/v_out, n_left, n_right);
       state := S1;
       
       when S1 =>
       ena <= '1';
       duty <= resize(to_sfixed(1, n_left, n_right) - duty_ratio, n_left, n_right);
       state := S0;  
       end case;  
     end if;
end process;
    
end Behavioral;
