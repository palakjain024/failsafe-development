library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.input_pkg.all;

entity lamdda is
port (    Clk   : in STD_LOGIC;
          Start : in STD_LOGIC;
          Mode  : in INTEGER range 1 to 4;
          sigh  : in vecth3;
          done  : out STD_LOGIC := '0';
          lambda_out : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right))
      );
end lamdda;

architecture Behavioral of lamdda is
  -- Matrix cal
  signal    Count0      : UNSIGNED (3 downto 0):="0000";
  signal    A       : sfixed(d_left downto d_right);
  signal    B       : sfixed(n_left downto n_right);
  signal    P       : sfixed(n_left downto n_right);
  signal    Sum     : sfixed(n_left downto n_right);
  signal    j0, k0, k1, k2 : INTEGER := 0;
  -- Lambda cal
  signal lambda : vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));

begin

mult: process(Clk, sigh)
  
   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15);
   variable     State         : STATE_VALUE := S0;

   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat33;
   variable State_inp_Matrix     : vect3 := (zer0, zer0, zer0);
   variable C_Matrix             : vect3;

   begin
           
   if (Clk'event and Clk = '1') then
    
       if Mode = 1 then
                    
                    -- A matrix
                    A_Aug_Matrix(0,0) := to_sfixed( 0.999993346944000,d_left,d_right);
                    A_Aug_Matrix(0,1) := to_sfixed( 0.000001558800000,d_left,d_right);
                    A_Aug_Matrix(0,2) := to_sfixed(-0.000000312000000,d_left,d_right);
                    A_Aug_Matrix(1,0) := to_sfixed( 0.000005346944000,d_left,d_right);
                    A_Aug_Matrix(1,1) := to_sfixed( 0.999993358800000,d_left,d_right);
                    A_Aug_Matrix(1,2) := to_sfixed( 0.000099688000000,d_left,d_right);
                    A_Aug_Matrix(2,0) := to_sfixed(-0.000000044196309,d_left,d_right);
                    A_Aug_Matrix(2,1) := to_sfixed(-0.000175197200000,d_left,d_right);
                    A_Aug_Matrix(2,2) := to_sfixed( 0.999992484400000,d_left,d_right);
                                    
        elsif Mode = 2 then
                   -- A matrix
                    A_Aug_Matrix(0,0) := to_sfixed( 0.999993358800000,d_left,d_right);
                    A_Aug_Matrix(0,1) := to_sfixed( 0.000001558800000,d_left,d_right);
                    A_Aug_Matrix(0,2) := to_sfixed( 0.000099688000000,d_left,d_right);
                    A_Aug_Matrix(1,0) := to_sfixed( 0.000001558800000,d_left,d_right);
                    A_Aug_Matrix(1,1) := to_sfixed( 0.999993358800000,d_left,d_right);
                    A_Aug_Matrix(1,2) := to_sfixed( 0.000099688000000,d_left,d_right);
                    A_Aug_Matrix(2,0) := to_sfixed(-0.000175197200000,d_left,d_right);
                    A_Aug_Matrix(2,1) := to_sfixed(-0.000175197200000,d_left,d_right);
                    A_Aug_Matrix(2,2) := to_sfixed( 0.999992484400000,d_left,d_right);
                    
 
                                   
         elsif Mode = 3 then
                    -- A matrix
                    A_Aug_Matrix(0,0) := to_sfixed( 0.999993358800000,d_left,d_right);
                    A_Aug_Matrix(0,1) := to_sfixed( 0.000005346944000,d_left,d_right);
                    A_Aug_Matrix(0,2) := to_sfixed( 0.000099688000000,d_left,d_right);
                    A_Aug_Matrix(1,0) := to_sfixed( 0.000001558800000,d_left,d_right);
                    A_Aug_Matrix(1,1) := to_sfixed( 0.999993346944000,d_left,d_right);
                    A_Aug_Matrix(1,2) := to_sfixed(-0.000000312000000,d_left,d_right);
                    A_Aug_Matrix(2,0) := to_sfixed(-0.000175197200000,d_left,d_right);
                    A_Aug_Matrix(2,1) := to_sfixed(-0.000000044196309,d_left,d_right);
                    A_Aug_Matrix(2,2) := to_sfixed( 0.999992484400000,d_left,d_right);

            
         elsif Mode = 4 then
                    -- A matrix
                    A_Aug_Matrix(0,0) := to_sfixed( 0.999993346944000,d_left,d_right);
                    A_Aug_Matrix(0,1) := to_sfixed( 0.000001546944000,d_left,d_right);
                    A_Aug_Matrix(0,2) := to_sfixed(-0.000000312000000,d_left,d_right);
                    A_Aug_Matrix(1,0) := to_sfixed( 0.000001546944000,d_left,d_right);
                    A_Aug_Matrix(1,1) := to_sfixed( 0.999993346944000,d_left,d_right);
                    A_Aug_Matrix(1,2) := to_sfixed(-0.000000312000000,d_left,d_right);
                    A_Aug_Matrix(2,0) := to_sfixed(-0.000000044196300,d_left,d_right);
                    A_Aug_Matrix(2,1) := to_sfixed(-0.000000044196309,d_left,d_right);
                    A_Aug_Matrix(2,2) := to_sfixed( 0.999992484400000,d_left,d_right);

        else null;
                    
        end if;

---- Step 2:  Multiplication -----
   case State is
          ------------------------------------------
          --    State S0 (wait for start signal)
          ------------------------------------------
          when S0 =>
              j0 <= 0; k0 <= 0; k1 <= 0; k2 <= 0;
              done <= '0';
              Count0 <= "0000";
              
              --FD_residual <= residual_eval;
              if( start = '1' ) then                
                  State := S1;
              else
                  State := S0;
              end if;
   
          -------------------------------------------
          --    State S1 (filling up of pipeline)
          -------------------------------------------
          when S1 =>
              A <= A_Aug_Matrix(j0, k0);  
              B <= State_inp_Matrix(k0);
              k0 <= k0 +1;
              Count0 <= Count0 + 1;
              State := S2;
   
          ---------------------------------------
          --    State S2 (more of filling up)
          ---------------------------------------
          when S2 =>
              A <= A_Aug_Matrix(j0, k0);  
              B <= State_inp_Matrix(k0);
   
              P <= resize(A * B, P'high, P'low);
              k0 <= k0 +1;
              Count0 <= Count0 + 1;
              State := S3;
   
          -------------------------------------------
          --    State S3 (even more of filling up)
          -------------------------------------------
          when S3 =>
              A <= A_Aug_Matrix(j0, k0);  
              B <= State_inp_Matrix(k0);
   
              P <= resize(A * B, P'high, P'low);
              Sum <= resize(P, Sum'high, Sum'low);
              
              if (k1 = 2) then
                  k1 <= 0;
                  else
                  k1 <= k1 + 1;
              end if;
              
               if (k0 = 2) then
               j0 <= j0 +1;
               k0 <= 0;
               else 
               k0 <= k0 +1;
               end if;
               
              Count0 <= Count0 + 1;
              State := S4;
   
          -------------------------------------------------
          --    State S4 (pipeline full, complete work)
          -------------------------------------------------
          when S4 =>
              A <= A_Aug_Matrix(j0, k0);  
              B <= State_inp_Matrix(k0);
   
              P <= resize(A * B, P'high, P'low);
   
              if (k1 = 0) then
                  Sum <= resize(P, Sum'high, Sum'low);
                  C_Matrix(k2) := resize(Sum, n_left, n_right);
                  k2 <= k2 +1;
              else
                  Sum <= resize(Sum + P, Sum'high, Sum'low);
              end if;
   
              if (k1 = 2) then
                  k1 <= 0;
                  else
                  k1 <= k1 + 1;
              end if;
              
           
              ----------------------------------
              -- check if all initiations done
              ----------------------------------
              if (Count0 = 8) then
                  State := S5;
              else
                  State := S4;                
                  Count0 <= Count0 + 1;
                 if (k0 = 2) then
                  j0 <= j0 +1;
                  k0 <= 0;
                  else 
                  k0 <= k0 +1;
                  end if;
              end if;
   
          ------------------------------------------------
          --    State S5 (start flushing the pipeline)
          ------------------------------------------------
          when S5 =>
                  P <= resize(A * B, P'high, P'low);          
                  Sum <= resize(Sum + P, Sum'high, Sum'low);
                  State := S6;
   
          -------------------------------------
          --    State S6 (more of flushing)
          -------------------------------------
          when S6 =>
                     
                      Sum <= resize(Sum + P, Sum'high, Sum'low);
                      State := S7;
   
          -------------------------------------------
          --    State S7 (completion of flushing)
          -------------------------------------------
          when S7 =>
                             
                     C_Matrix(k2) := Sum;                 
                     State := S8;
                     Count0 <= "0000";
                     k0 <= 0;
                  
          ------------------------------------
          --    State S8 (output the data)
          ------------------------------------
          when S8 =>
           lambda(0) <= resize(C_Matrix(0) + sigh(0), n_left, n_right);
           State := S9;
           
          when S9 =>
           lambda(1) <= resize(C_Matrix(1) + sigh(1), n_left, n_right);
           State := S10;
           
          when S10 =>
           lambda(2) <= resize(C_Matrix(2) + sigh(2), n_left, n_right);
           State := S11;
           
          when S11 =>
          State_inp_Matrix(0) := lambda(0);
          State_inp_Matrix(1) := lambda(1);
          State_inp_Matrix(2) := lambda(2);
          State := S12;
          
          when S12 =>
          State := S13;
          
          when S13 =>
          State := S14;
           
          when S14 =>
          State := S15; 
                          
          when S15 =>
          lambda_out(0) <= lambda(0);
          lambda_out(1) <= lambda(1);
          lambda_out(2) <= lambda(2);
          done <= '1';
          State := S0;
 
            end case; 
        end if;
    end process;
end Behavioral;
