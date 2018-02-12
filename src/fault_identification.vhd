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
           gavg_norm_out : out vect4 := (zer0, zer0, zer0, zer0); -- norm of gamma average
           ip_out : out ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
           FI_flag : out STD_LOGIC_Vector(3 downto 0):= (others => '0')
         );
end fault_identification;

architecture Behavioral of fault_identification is

--Signals   
--  Inner product          
signal	A       : ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
signal  B       : ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
signal  C       : ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
signal  D       : ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
signal  ip      : ip_array := (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
signal  gavg_norm : vect4 := (zer0, zer0, zer0, zer0); -- norm of gamma average

-- Fault signature lib
signal f1 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
signal f2 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
signal f3 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
signal f4 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
signal f5 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
signal f6 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
signal f7 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
signal f8 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
signal f9 : vect4 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
    
begin
main_loop: process(clk)

        type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7);
        variable State : STATE_VALUE := S0;
        variable max_ip : sfixed(n_left downto n_right) := zer0;
        variable index : integer range 0 to 9 := 0;
        
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
                   ip   <= (zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0, zer0);
                   FI_flag <= "0000";
                   State := S0;
               end if; 
                       
               
          --------------------------------------------------------
           -- state S1 (Calculate inner product)
          ---------------------------------------------------------
            When S1 =>
            gavg_norm_out <= gavg_norm;
            
            A(0) <= resize(f1(0) * gavg_norm(0), n_left, n_right);
            A(1) <= resize(f2(0) * gavg_norm(0), n_left, n_right); 
            A(2) <= resize(f3(0) * gavg_norm(0), n_left, n_right);
            A(3) <= resize(f4(0) * gavg_norm(0), n_left, n_right);
            A(4) <= resize(f5(0) * gavg_norm(0), n_left, n_right); 
            A(5) <= resize(f6(0) * gavg_norm(0), n_left, n_right);
            A(6) <= resize(f7(0) * gavg_norm(0), n_left, n_right);
            A(7) <= resize(f8(0) * gavg_norm(0), n_left, n_right); 
            A(8) <= resize(f9(0) * gavg_norm(0), n_left, n_right); 
            
            B(0) <= resize(f1(1) * gavg_norm(1), n_left, n_right);
            B(1) <= resize(f2(1) * gavg_norm(1), n_left, n_right); 
            B(2) <= resize(f3(1) * gavg_norm(1), n_left, n_right);
            B(3) <= resize(f4(1) * gavg_norm(1), n_left, n_right);
            B(4) <= resize(f5(1) * gavg_norm(1), n_left, n_right); 
            B(5) <= resize(f6(1) * gavg_norm(1), n_left, n_right);
            B(6) <= resize(f7(1) * gavg_norm(1), n_left, n_right);
            B(7) <= resize(f8(1) * gavg_norm(1), n_left, n_right); 
            B(8) <= resize(f9(1) * gavg_norm(1), n_left, n_right); 
            State := S2;
            --------------------------------------------------------
            -- state S2 (Integrate inner product)
            ---------------------------------------------------------
            When S2 =>
           
            C(0) <= resize(f1(2) * gavg_norm(2), n_left, n_right);
            C(1) <= resize(f2(2) * gavg_norm(2), n_left, n_right);
            C(2) <= resize(f3(2) * gavg_norm(2), n_left, n_right);
            C(3) <= resize(f4(2) * gavg_norm(2), n_left, n_right);
            C(4) <= resize(f5(2) * gavg_norm(2), n_left, n_right); 
            C(5) <= resize(f6(2) * gavg_norm(2), n_left, n_right);
            C(6) <= resize(f7(2) * gavg_norm(2), n_left, n_right);
            C(7) <= resize(f8(2) * gavg_norm(2), n_left, n_right); 
            C(8) <= resize(f9(2) * gavg_norm(2), n_left, n_right); 
           
            D(0) <= resize(f1(3) * gavg_norm(3), n_left, n_right);
            D(1) <= resize(f2(3) * gavg_norm(3), n_left, n_right); 
            D(2) <= resize(f3(3) * gavg_norm(3), n_left, n_right);
            D(3) <= resize(f4(3) * gavg_norm(3), n_left, n_right);
            D(4) <= resize(f5(3) * gavg_norm(3), n_left, n_right); 
            D(5) <= resize(f6(3) * gavg_norm(3), n_left, n_right);
            D(6) <= resize(f7(3) * gavg_norm(3), n_left, n_right);
            D(7) <= resize(f8(3) * gavg_norm(3), n_left, n_right); 
            D(8) <= resize(f9(3) * gavg_norm(3), n_left, n_right);       
            State := S3;
          
           When S3 =>
           
           ip(0) <= resize(A(0) + B(0), n_left, n_right);
           ip(1) <= resize(A(1) + B(1), n_left, n_right);
           ip(2) <= resize(A(2) + B(2), n_left, n_right);
           ip(3) <= resize(A(3) + B(3), n_left, n_right);
           ip(4) <= resize(A(4) + B(4), n_left, n_right);
           ip(5) <= resize(A(5) + B(5), n_left, n_right);
           ip(6) <= resize(A(6) + B(6), n_left, n_right);
           ip(7) <= resize(A(7) + B(7), n_left, n_right);
           ip(8) <= resize(A(8) + B(8), n_left, n_right);
           State := S4;
         
           When S4 =>            
           ip(0) <= resize(ip(0) + C(0), n_left, n_right);
           ip(1) <= resize(ip(1) + C(1), n_left, n_right);
           ip(2) <= resize(ip(2) + C(2), n_left, n_right);
           ip(3) <= resize(ip(3) + C(3), n_left, n_right);
           ip(4) <= resize(ip(4) + C(4), n_left, n_right);
           ip(5) <= resize(ip(5) + C(5), n_left, n_right);
           ip(6) <= resize(ip(6) + C(6), n_left, n_right);
           ip(7) <= resize(ip(7) + C(7), n_left, n_right);
           ip(8) <= resize(ip(8) + C(8), n_left, n_right);
           State := S5; 
            
           When S5 =>
           ip(0) <= resize(ip(0) + D(0), n_left, n_right);
           ip(1) <= resize(ip(1) + D(1), n_left, n_right);
           ip(2) <= resize(ip(2) + D(2), n_left, n_right);
           ip(3) <= resize(ip(3) + D(3), n_left, n_right);
           ip(4) <= resize(ip(4) + D(4), n_left, n_right);
           ip(5) <= resize(ip(5) + D(5), n_left, n_right);
           ip(6) <= resize(ip(6) + D(6), n_left, n_right);
           ip(7) <= resize(ip(7) + D(7), n_left, n_right);
           ip(8) <= resize(ip(8) + D(8), n_left, n_right);
           State := S6;
           
           When S6 =>
             ip_out <= ip;                  
          -- Finding max ip
              for i in 0 to 8 loop
                 if ip(i) > max_ip then
                    max_ip := ip(i);
                    index := i;
                 end if;
                 end loop;
                State := S7;
                   
           When S7 =>            
           --Fault identification flag
             done <= '1';
             if max_ip > to_sfixed(0.8, n_left, n_right) then
             FI_flag <= std_logic_vector(to_unsigned(index, FI_flag'length));       
             end if; 
            State := S0;       
        end case;  
     end if; -- Clk     
  end process;
  
end Behavioral;