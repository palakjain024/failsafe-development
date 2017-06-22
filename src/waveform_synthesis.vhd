library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use work.input_pkg.all;

entity waveform_synthesis is
 PORT(
      clk       : IN  STD_LOGIC; 
      Done      : OUT STD_LOGIC;  
      sine_ref  : OUT sine_3p;
      ctrl_freq : OUT INTEGER range 0 to 200 := 0
      );
end waveform_synthesis;

architecture Behavioral of waveform_synthesis is


 -- Component definitions
    COMPONENT dds_compiler_0
      PORT (
        aclk : IN STD_LOGIC;
        m_axis_data_tvalid : OUT STD_LOGIC;
        m_axis_data_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
    END COMPONENT;
    
    COMPONENT dds_compiler_1
       PORT (
         aclk : IN STD_LOGIC;
         m_axis_data_tvalid : OUT STD_LOGIC;
         m_axis_data_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
       );
    END COMPONENT;
     
    COMPONENT dds_compiler_2
        PORT (
          aclk : IN STD_LOGIC;
          m_axis_data_tvalid : OUT STD_LOGIC;
          m_axis_data_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

 -- Signal definitions
  signal data_tvalid_0 :  STD_LOGIC;
  signal m_axis_data_tdata_0: std_logic_vector(7 downto 0) := (others => '0');
  signal sine_0 : INTEGER range 0 to 128 := 0;
    
  signal data_tvalid_1:  STD_LOGIC;
  signal m_axis_data_tdata_1: std_logic_vector(7 downto 0) := (others => '0');
  signal sine_120 : INTEGER range 0 to 128 := 0;
    
  signal data_tvalid_2:  STD_LOGIC;
  signal m_axis_data_tdata_2: std_logic_vector(7 downto 0) := (others => '0');
  signal sine_240 : INTEGER range 0 to 128 := 0;
   
  -- Triangular waveform generation
  signal counter : Integer range 0 to pwm_freq;
  signal ctrl_waveform : Integer range 0 to 200 := 0;
  
begin

dds_instance_0: dds_compiler_0
           PORT MAP (
             aclk => clk,
             m_axis_data_tvalid => data_tvalid_0,
             m_axis_data_tdata => m_axis_data_tdata_0
                    );
                    

dds_instance_1: dds_compiler_1
           PORT MAP (
             aclk => clk,
             m_axis_data_tvalid => data_tvalid_1,
             m_axis_data_tdata => m_axis_data_tdata_1
                    );
                    
dds_instance_2: dds_compiler_2
           PORT MAP (
             aclk => clk,
             m_axis_data_tvalid => data_tvalid_2,
             m_axis_data_tdata => m_axis_data_tdata_2
                    );
                                                            
main_loop: process(clk)

           
 begin  
    
     if (clk'event and clk = '1') then
        
        -- Waveform outputs for PWM
        Done <= data_tvalid_0;
        sine_ref(0) <= sine_0;
        sine_ref(1) <= sine_120;
        sine_ref(2) <= sine_240;
        ctrl_freq   <= ctrl_waveform;
        
        if data_tvalid_0 = '1' then
        sine_0 <= to_integer(signed(m_axis_data_tdata_0)) + 64;
        
        -- Reference wave form generation
               if counter = pwm_freq then
               counter <= 0;
               else
               counter <= counter + 1;
               end if; 
               
        else
        sine_0 <= 0;
        end if;
        
        if data_tvalid_1 = '1' then
        sine_120 <= to_integer(signed(m_axis_data_tdata_1)) + 64;
        else
        sine_120 <= 0;
        end if;
        
        if data_tvalid_2 = '1' then
        sine_240 <= to_integer(signed(m_axis_data_tdata_2)) + 64;
        else
        sine_240 <= 0;
        end if;
       
       -- 62 depends upon modulation value (m) since sine amplitude = 128
       -- m = 0.8 where m = sine_amplitude/tri_amplitude                     
       ctrl_waveform <= counter/62;  
       
       
     end if;
 end process;   

end Behavioral;
