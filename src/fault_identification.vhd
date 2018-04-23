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
           gamma_avg : in vect4;
           done : out STD_LOGIC := '0';
           max_ip_out : out sfixed(n_left downto n_right) := zer0;
           gavg_norm_out : out vect4 := (zer0, zer0, zer0, zer0); -- norm of gamma average
           ip_out : out ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
           FI_flag : out STD_LOGIC_Vector(3 downto 0):= (others => '0')
         );
end fault_identification;

architecture Behavioral of fault_identification is

--Signals   
--  Inner product          
signal	A       : ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
signal  B       : ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
signal  C       : ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
signal  D       : ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
signal  ip      : ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
signal  gavg_norm : vect4 := (zer0, zer0, zer0, zer0); -- norm of gamma average

-- Fault signature lib (Normalized it)

-- PV faults
signal f1 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(1,n_left,n_right), to_sfixed(0,n_left,n_right));
signal f2 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(1,n_left,n_right));
signal f3 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0.707,n_left,n_right), to_sfixed(0.707,n_left,n_right));

-- Open Switch
-- SW1/SW2
signal f4 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0.8269,n_left,n_right), to_sfixed(0.5605,n_left,n_right), to_sfixed(-0.0459,n_left,n_right));
-- SW3
signal f8 : vect4 := (to_sfixed(-0.0048,n_left,n_right), to_sfixed(0.8121,n_left,n_right), to_sfixed(0.5815,n_left,n_right), to_sfixed(-0.0481,n_left,n_right));
-- SW4
signal f10 : vect4 := (to_sfixed(-0.0077,n_left,n_right), to_sfixed(0.6931,n_left,n_right), to_sfixed(0.6854,n_left,n_right), to_sfixed(0.2233,n_left,n_right));

-- Short Switch
--SW2
signal f7 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0.0135,n_left,n_right), to_sfixed(-0.1352,n_left,n_right), to_sfixed(0.9907,n_left,n_right));
-- SW3
signal f9 : vect4 := (to_sfixed(-0.87871,n_left,n_right), to_sfixed(0.2451,n_left,n_right), to_sfixed(-0.0293,n_left,n_right), to_sfixed(0.4098,n_left,n_right));
-- SW4
signal f11 : vect4 := (to_sfixed(-0.8787,n_left,n_right), to_sfixed(0.2416,n_left,n_right), to_sfixed(-0.0366,n_left,n_right), to_sfixed(0.4101,n_left,n_right));

-- Sensor fault
-- iL
signal f12 : vect4 := (to_sfixed(0.9912,n_left,n_right), to_sfixed(0.016,n_left,n_right), to_sfixed(0.1256,n_left,n_right), to_sfixed(0.0380,n_left,n_right));
-- Vpv
signal f14 : vect4 := (to_sfixed(0.0140,n_left,n_right), to_sfixed(-0.8407,n_left,n_right), to_sfixed(0.0981,n_left,n_right), to_sfixed(0.5324,n_left,n_right));
-- Iload
signal f15 : vect4 := (to_sfixed(-0.9322,n_left,n_right), to_sfixed(0.3356,n_left,n_right), to_sfixed(0.1305,n_left,n_right), to_sfixed(0.0373,n_left,n_right));
    
begin
main_loop: process(clk)

        type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9);
        variable State : STATE_VALUE := S0;
        variable max_ip : sfixed(n_left downto n_right) := zer0;
        variable index : integer range 0 to 11 := 0;
        
        begin
       if clk ='1' and clk'event then  
            
             case state is
             
         --------------------------------------------------------
         -- state S0(Check if fault has happened) FD = '1'
         ---------------------------------------------------------
              When S0 => 
              
              -- initilization            
              max_ip := zer0;
              index := 0; 
              done <= '0';
              
                
              -- Gamma normalization
              gavg_norm(0) <= resize(gamma_avg(0)*ibase, n_left, n_right);
              gavg_norm(1) <= resize(gamma_avg(1)*vbase, n_left, n_right);
              gavg_norm(2) <= resize(gamma_avg(2)*ibase, n_left, n_right);
              gavg_norm(3) <= resize(gamma_avg(3)*vbase, n_left, n_right);     
              
              -- If a fault event is detected, fault identification begins
              if FD_flag = '1' then
               
                    if Start = '1' then
                    State := S1;
                    else
                    State := S0;
                    end if;
               else
                   ip   <= (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
                   FI_flag <= "0000";
                   State := S0;
               end if; 
                       
               
          --------------------------------------------------------
           -- state S1 (Calculate inner product)
          ---------------------------------------------------------
            When S1 =>
            gavg_norm_out <= gavg_norm;
            
            A(0) <= resize(f2(0) * gavg_norm(0), n_left, n_right);
            A(1) <= resize(f3(0) * gavg_norm(0), n_left, n_right); 
            A(2) <= resize(f4(0) * gavg_norm(0), n_left, n_right);
            A(3) <= resize(f7(0) * gavg_norm(0), n_left, n_right);
            A(4) <= resize(f8(0) * gavg_norm(0), n_left, n_right); 
            A(5) <= resize(f9(0) * gavg_norm(0), n_left, n_right);
            A(6) <= resize(f10(0) * gavg_norm(0), n_left, n_right);
            A(7) <= resize(f11(0) * gavg_norm(0), n_left, n_right); 
            A(8) <= resize(f12(0) * gavg_norm(0), n_left, n_right); 
            A(9) <= resize(f14(0) * gavg_norm(0), n_left, n_right); 
            A(10) <= resize(f15(0) * gavg_norm(0), n_left, n_right);
            A(11) <= resize(f1(0) * gavg_norm(0), n_left, n_right);
            State := S2;
            
            When S2 =>
            
            B(0) <= resize(f2(1) * gavg_norm(1), n_left, n_right);
            B(1) <= resize(f3(1) * gavg_norm(1), n_left, n_right); 
            B(2) <= resize(f4(1) * gavg_norm(1), n_left, n_right);
            B(3) <= resize(f7(1) * gavg_norm(1), n_left, n_right);
            B(4) <= resize(f8(1) * gavg_norm(1), n_left, n_right); 
            B(5) <= resize(f9(1) * gavg_norm(1), n_left, n_right);
            B(6) <= resize(f10(1) * gavg_norm(1), n_left, n_right);
            B(7) <= resize(f11(1) * gavg_norm(1), n_left, n_right); 
            B(8) <= resize(f12(1) * gavg_norm(1), n_left, n_right); 
            B(9) <= resize(f14(1) * gavg_norm(1), n_left, n_right); 
            B(10) <= resize(f15(1) * gavg_norm(1), n_left, n_right); 
            B(11) <= resize(f1(1) * gavg_norm(1), n_left, n_right); 
            State := S3;
          
            When S3 =>
           
            C(0) <= resize(f2(2) * gavg_norm(2), n_left, n_right);
            C(1) <= resize(f3(2) * gavg_norm(2), n_left, n_right);
            C(2) <= resize(f4(2) * gavg_norm(2), n_left, n_right);
            C(3) <= resize(f7(2) * gavg_norm(2), n_left, n_right);
            C(4) <= resize(f8(2) * gavg_norm(2), n_left, n_right); 
            C(5) <= resize(f9(2) * gavg_norm(2), n_left, n_right);
            C(6) <= resize(f10(2) * gavg_norm(2), n_left, n_right);
            C(7) <= resize(f11(2) * gavg_norm(2), n_left, n_right); 
            C(8) <= resize(f12(2) * gavg_norm(2), n_left, n_right); 
            C(9) <= resize(f14(2) * gavg_norm(2), n_left, n_right); 
            C(10) <= resize(f15(2) * gavg_norm(2), n_left, n_right); 
            C(11) <= resize(f1(2) * gavg_norm(2), n_left, n_right);
            State := S4;
            
            When S4 =>
            
            D(0) <= resize(f2(3) * gavg_norm(3), n_left, n_right);
            D(1) <= resize(f3(3) * gavg_norm(3), n_left, n_right); 
            D(2) <= resize(f4(3) * gavg_norm(3), n_left, n_right);
            D(3) <= resize(f7(3) * gavg_norm(3), n_left, n_right);
            D(4) <= resize(f8(3) * gavg_norm(3), n_left, n_right); 
            D(5) <= resize(f9(3) * gavg_norm(3), n_left, n_right);
            D(6) <= resize(f10(3) * gavg_norm(3), n_left, n_right);
            D(7) <= resize(f11(3) * gavg_norm(3), n_left, n_right); 
            D(8) <= resize(f12(3) * gavg_norm(3), n_left, n_right);  
            D(9) <= resize(f14(3) * gavg_norm(3), n_left, n_right);  
            D(10) <= resize(f15(3) * gavg_norm(3), n_left, n_right);   
            D(11) <= resize(f1(3) * gavg_norm(3), n_left, n_right);      
            State := S5;
          
           When S5 =>
           
           ip(0) <= resize(A(0) + B(0), n_left, n_right);
           ip(1) <= resize(A(1) + B(1), n_left, n_right);
           ip(2) <= resize(A(2) + B(2), n_left, n_right);
           ip(3) <= resize(A(3) + B(3), n_left, n_right);
           ip(4) <= resize(A(4) + B(4), n_left, n_right);
           ip(5) <= resize(A(5) + B(5), n_left, n_right);
           ip(6) <= resize(A(6) + B(6), n_left, n_right);
           ip(7) <= resize(A(7) + B(7), n_left, n_right);
           ip(8) <= resize(A(8) + B(8), n_left, n_right);
           ip(9) <= resize(A(9) + B(9), n_left, n_right);
           ip(10) <= resize(A(10) + B(10), n_left, n_right);
           ip(11) <= resize(A(11) + B(11), n_left, n_right);
           State := S6;
         
           When S6 =>            
           ip(0) <= resize(ip(0) + C(0), n_left, n_right);
           ip(1) <= resize(ip(1) + C(1), n_left, n_right);
           ip(2) <= resize(ip(2) + C(2), n_left, n_right);
           ip(3) <= resize(ip(3) + C(3), n_left, n_right);
           ip(4) <= resize(ip(4) + C(4), n_left, n_right);
           ip(5) <= resize(ip(5) + C(5), n_left, n_right);
           ip(6) <= resize(ip(6) + C(6), n_left, n_right);
           ip(7) <= resize(ip(7) + C(7), n_left, n_right);
           ip(8) <= resize(ip(8) + C(8), n_left, n_right);
           ip(9) <= resize(ip(9) + C(9), n_left, n_right);
           ip(10) <= resize(ip(10) + C(10), n_left, n_right);
           ip(11) <= resize(ip(11) + C(11), n_left, n_right);
           State := S7; 
            
           When S7 =>
           ip(0) <= resize(ip(0) + D(0), n_left, n_right);
           ip(1) <= resize(ip(1) + D(1), n_left, n_right);
           ip(2) <= resize(ip(2) + D(2), n_left, n_right);
           ip(3) <= resize(ip(3) + D(3), n_left, n_right);
           ip(4) <= resize(ip(4) + D(4), n_left, n_right);
           ip(5) <= resize(ip(5) + D(5), n_left, n_right);
           ip(6) <= resize(ip(6) + D(6), n_left, n_right);
           ip(7) <= resize(ip(7) + D(7), n_left, n_right);
           ip(8) <= resize(ip(8) + D(8), n_left, n_right);
           ip(9) <= resize(ip(9) + D(9), n_left, n_right);
           ip(10) <= resize(ip(10) + D(10), n_left, n_right);
           ip(11) <= resize(ip(11) + D(11), n_left, n_right);
           State := S8;
           
           When S8 =>
             ip_out <= ip;                  
          -- Finding max ip
              for i in 0 to 11 loop
                 if ip(i) > max_ip then
                    max_ip := ip(i);
                    index := i + 1;
                 end if;
                 end loop;
                 
                State := S9;
                   
           When S9 => 
              
              done <= '1';    
           -- Fault identification flag
                max_ip_out <= max_ip;
             if max_ip > fi_th then
              
           -- FI_flag <= std_logic_vector(to_unsigned(index, FI_flag'length));   
                    if index = 1 then -- f2
                            FI_flag <= "0010";
                            elsif index = 2 then -- f3
                                FI_flag <= "0011";
                                     elsif index = 3 then  -- f4
                                        FI_flag <= "0100";
                                             elsif index = 4 then -- f7
                                                FI_flag <= "0111";
                                                    elsif index = 5 then -- f8
                                                        FI_flag <= "1000";
                             elsif index = 6 then -- f9
                                FI_flag <= "1001";
                                     elsif index = 7 then -- f10
                                        FI_flag <= "1010";
                                            elsif index = 8 then -- f11
                                                FI_flag <= "1011";
                                                     elsif index = 9 then -- f12
                                                        FI_flag <= "1100";
                                                             elsif index = 10 then -- f14
                                                                FI_flag <= "1110";
                                                                     elsif index = 11 then -- f15
                                                                        FI_flag <= "1111";
                                                                            elsif index = 12 then -- f1
                                                                             FI_flag <= "0001";
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