-- Fault identification --
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use ieee.std_logic_unsigned.all;
library work;
use work.input_pkg.all;

entity fault_identification is
    Port ( 
           clk : in STD_LOGIC;
           start : in STD_LOGIC;
           FD_flag : in STD_LOGIC;
           FR_flag : in STD_LOGIC;
           gamma_avg : in vect4;
           done : out STD_LOGIC := '0';
           max_ip_out : out sfixed(n_left downto n_right) := zer0;
           gavg_norm_out : out vect4 := (zer0, zer0, zer0, zer0); -- norm of gamma average
           -- Inner products
           ip_out : out ip_array := (zer0, zer0, zer0, zer0);
           FI_flag : out STD_LOGIC_Vector(3 downto 0):= (others => '0')
         );
end fault_identification;

architecture Behavioral of fault_identification is

--Signals   
--  Inner product          
signal	A       : ip_array := (zer0, zer0, zer0, zer0);
signal  B       : ip_array := (zer0, zer0, zer0, zer0);
signal  C       : ip_array := (zer0, zer0, zer0, zer0);
signal  D       : ip_array := (zer0, zer0, zer0, zer0);
signal  ip      : ip_array := (zer0, zer0, zer0, zer0);
signal  gavg_norm : vect4 := (zer0, zer0, zer0, zer0); -- norm of gamma average

-- Max inner product
signal max_ip : sfixed(n_left downto n_right) := zer0;
signal index, itr : integer range 0 to 16 := 0;


-- Fault signature lib (Normalized it)

------------------------------------- PV faults -------------------------------------------
signal f1 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0.3070,n_left,n_right), to_sfixed(0.9517,n_left,n_right));
---------------------------------------------------------------------------------------------
------------------------------------- Open Switch -------------------------------------------
-- SW1(f4)
signal f2 : vect4 := (to_sfixed(0.1773,n_left,n_right), to_sfixed(0.9794,n_left,n_right), to_sfixed(0.0960,n_left,n_right), to_sfixed(-0.0096,n_left,n_right));
---------------------------------------------------------------------------------------------
------------------------------------- Short Switch -------------------------------------------
--SW2 (f7)
signal f3 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(-0.07,n_left,n_right), to_sfixed(0.9979,n_left,n_right));
---------------------------------------------------------------------------------------------
---------------------------------- Sensor fault --------------------------------------------
-- ipv
signal f4 : vect4 := (to_sfixed(-0.6493,n_left,n_right), to_sfixed(0.3135,n_left,n_right), to_sfixed(0.3135,n_left,n_right), to_sfixed(0.6180,n_left,n_right));
---------------------------------------------------------------------------------------------

    
begin
main_loop: process(clk)

        type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9);
        variable State : STATE_VALUE := S0;

        
        begin
       if clk ='1' and clk'event then  
            
             case state is
             
         --------------------------------------------------------
         -- state S0(Check if fault has happened) FD = '1'
         ---------------------------------------------------------
              When S0 => 
              
              -- initilization            
              done <= '0';
              -- Gamma normalization
              gavg_norm(0) <= resize(gamma_avg(0)*ibase, n_left, n_right);
              gavg_norm(1) <= resize(gamma_avg(1)*vbase, n_left, n_right);
              gavg_norm(2) <= resize(gamma_avg(2)*ibase, n_left, n_right);
              gavg_norm(3) <= resize(gamma_avg(3)*vbase, n_left, n_right);     
              -- 500 ns wait
                if Start = '1' then
                
                if FR_flag = '1' then
                State := S0;
                else
                State := S1;
                end if;
                
                else
                State := S0;
                end if;
                                     
               
          --------------------------------------------------------
           -- state S1 (Calculate inner product)
          ---------------------------------------------------------
            When S1 =>
          
            
            A(0) <= resize(f1(0) * gavg_norm(0), n_left, n_right);
            A(1) <= resize(f2(0) * gavg_norm(0), n_left, n_right); 
            A(2) <= resize(f3(0) * gavg_norm(0), n_left, n_right);
            A(3) <= resize(f4(0) * gavg_norm(0), n_left, n_right);
            State := S2;
            
            When S2 =>
            
            B(0) <= resize(f1(1) * gavg_norm(1), n_left, n_right);
            B(1) <= resize(f2(1) * gavg_norm(1), n_left, n_right); 
            B(2) <= resize(f3(1) * gavg_norm(1), n_left, n_right);
            B(3) <= resize(f4(1) * gavg_norm(1), n_left, n_right);
            State := S3;
          
            When S3 =>
           
            C(0) <= resize(f1(2) * gavg_norm(2), n_left, n_right);
            C(1) <= resize(f2(2) * gavg_norm(2), n_left, n_right);
            C(2) <= resize(f3(2) * gavg_norm(2), n_left, n_right);
            C(3) <= resize(f4(2) * gavg_norm(2), n_left, n_right);
            State := S4;
            
            When S4 =>
            
            D(0) <= resize(f1(3) * gavg_norm(3), n_left, n_right);
            D(1) <= resize(f2(3) * gavg_norm(3), n_left, n_right); 
            D(2) <= resize(f3(3) * gavg_norm(3), n_left, n_right);
            D(3) <= resize(f4(3) * gavg_norm(3), n_left, n_right);
            State := S5;
          
           When S5 =>
           
           ip(0) <= resize(A(0) + B(0), n_left, n_right);
           ip(1) <= resize(A(1) + B(1), n_left, n_right);
           ip(2) <= resize(A(2) + B(2), n_left, n_right);
           ip(3) <= resize(A(3) + B(3), n_left, n_right);
           State := S6;
         
           When S6 =>            
           ip(0) <= resize(ip(0) + C(0), n_left, n_right);
           ip(1) <= resize(ip(1) + C(1), n_left, n_right);
           ip(2) <= resize(ip(2) + C(2), n_left, n_right);
           ip(3) <= resize(ip(3) + C(3), n_left, n_right);
           State := S7; 
            
           When S7 =>
           ip(0) <= resize(ip(0) + D(0), n_left, n_right);
           ip(1) <= resize(ip(1) + D(1), n_left, n_right);
           ip(2) <= resize(ip(2) + D(2), n_left, n_right);
           ip(3) <= resize(ip(3) + D(3), n_left, n_right);
           -- Initial values for max inner product
           max_ip <= zer0;
           index  <= 0;
           itr <= 0;
           -- Next state
           State := S8;
           
           When S8 =>
           
                       
                if ip(itr) > max_ip then
                    max_ip <= ip(itr);
                    index <= itr + 1;
                 end if;
                 
                if itr > 3  or itr = 3 then
                itr <= 0; 
                State := S9;
                else
                itr <= itr + 1;
                State := S8;
                end if;
                
                   
           When S9 => 
            -- outputs of the component  
            done <= '1';    
            max_ip_out <= max_ip;
            ip_out <= ip;
            gavg_norm_out <= gavg_norm;
                
           -- Fault identification flag
             if max_ip > fi_th and FD_flag = '1' then
               
          
                    if index = 1 then -- -- f3 for PV fault in APEC
                            FI_flag <= "0100";
                            elsif index = 2 then -- f4 for converter open fault in APEC
                                FI_flag <= "0001";
                                      elsif index = 3 then  -- f7 converter short fault in APEC
                                          FI_flag <= "0001";
                                             elsif index = 4 then -- f12 for sensor fault in APEC
                                                FI_flag <= "0010";
                                                    else null;
                                                        end if;
             else
             FI_flag <= "0000";   
             end if; 
             
            State := S0;       
        end case;  
     end if; -- Clk     
  end process;
  
end Behavioral;