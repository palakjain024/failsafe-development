-- Dead time for PWM
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library work;
use work.input_pkg.all;

entity deadtime is
     Port ( clk : in STD_LOGIC;
           p_Pwm_In : in STD_LOGIC;
           p_Pwm1_Out : out STD_LOGIC := '0';
           p_Pwm2_Out : out STD_LOGIC := '0');
end deadtime;

architecture Behavioral of deadtime is

signal sig_Not_Pwm_In: std_logic := '0';

begin
    sig_Not_Pwm_In <= not p_Pwm_In;
    
    process (CLK)
        variable var_Dead_Count1: integer range 0 to 1000 := 0;
        variable var_Dead_Count2: integer range 0 to 1000 := 0;
       
    begin
        if (CLK 'event and CLK = '1') then
            if (p_Pwm_In = '1') then
                if (var_Dead_Count1 < c_Dead_t) then
                    var_Dead_Count1 := var_Dead_Count1 + 1;
                else null;
                end if;
            else 
                var_Dead_Count1 := 0;
                p_Pwm1_Out <= p_Pwm_In;
            end if;
            
            if (var_Dead_Count1 = c_Dead_t) then
                p_Pwm1_Out <= p_Pwm_In;
            else null;
            end if;
-----------------------------------
            if (sig_Not_Pwm_In = '1') then
                if (var_Dead_Count2 < c_Dead_t) then
                    var_Dead_Count2 := var_Dead_Count2 + 1;
                else null;
                end if;
            else 
                var_Dead_Count2 := 0;
                p_Pwm2_Out <= sig_Not_Pwm_In;
            end if;
            
            if (var_Dead_Count2 = c_Dead_t) then
                p_Pwm2_Out <= sig_Not_Pwm_In;
            else null;
            end if;
        end if;
    end process;
end Behavioral;
