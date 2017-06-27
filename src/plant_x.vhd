-- With C = 100e-06 and L = 5 mH
-- Note here value of count0 depends on number of MULT operations to be performed
-- 
library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_1164.ALL;
use work.input_pkg.all;

entity plant_x is
 port (Clk   : in STD_LOGIC;
       Start : in STD_LOGIC;
       Mode  : in INTEGER range 1 to 8;
       u_inp : in vect7;
       Done  : out STD_LOGIC := '0';
       plt_z : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right))
       );
end plant_x;

architecture Behavioral of plant_x is
                 
    -- Matrix cal 
      signal	Count0	: INTEGER range 0 to 50 := 0;
	  signal	A       : sfixed(d_left downto d_right);
	  signal	B       : sfixed(n_left downto n_right);
	  signal	P       : sfixed(n_left downto n_right);
	  signal	Sum	    : sfixed(n_left downto n_right);
      signal 	j0, k0, k1, k2 : INTEGER := 0;

   -- For Norm calculation
      signal  z_val : vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
     
    
begin

mult: process(Clk, u_inp)

   -- General Variables for multiplication and addition
  type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8);
  variable     State         : STATE_VALUE := S0;

  -- Matrix values depends on type of mode
  variable A_Aug_Matrix         : mat37;
  variable State_inp_Matrix     : vect7:= (il, il, il, il, il, il, il);
  variable C_Matrix             : vect3;

   begin  
   
   if (Clk'event and Clk = '1') then 
   

     
      -- A matrix
       A_Aug_Matrix(0,0) := a1;
       A_Aug_Matrix(0,1) := a2;
       A_Aug_Matrix(0,2) := a2;
       A_Aug_Matrix(1,0) := a2;
       A_Aug_Matrix(1,1) := a1;
       A_Aug_Matrix(1,2) := a2;
       A_Aug_Matrix(2,0) := a2;
       A_Aug_Matrix(2,1) := a2;
       A_Aug_Matrix(2,2) := a1;
       
        -- Mode selection
         if Mode = 1 then
            A_Aug_Matrix(0,3) := to_sfixed(0,d_left,d_right);
            A_Aug_Matrix(1,3) := to_sfixed(0,d_left,d_right);
            A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right);
                    
         elsif Mode = 2 then
            A_Aug_Matrix(0,3) := to_sfixed( 0.000033333333333,d_left,d_right);
            A_Aug_Matrix(1,3) := to_sfixed( 0.000033333333333,d_left,d_right);
            A_Aug_Matrix(2,3) := to_sfixed(-0.000066666666667,d_left,d_right);
      
         elsif Mode = 3 then
            A_Aug_Matrix(0,3) := to_sfixed( 0.000033333333333,d_left,d_right);
            A_Aug_Matrix(1,3) := to_sfixed(-0.000066666666667,d_left,d_right);
            A_Aug_Matrix(2,3) := to_sfixed( 0.000033333333333,d_left,d_right);
      
         elsif Mode = 4 then
            A_Aug_Matrix(0,3) := to_sfixed( 0.000066666666667,d_left,d_right); 
            A_Aug_Matrix(1,3) := to_sfixed(-0.000033333333333,d_left,d_right);
            A_Aug_Matrix(2,3) := to_sfixed(-0.000033333333333,d_left,d_right);
         
         elsif Mode = 5 then
            A_Aug_Matrix(0,3) := to_sfixed(-0.000066666666667,d_left,d_right);
            A_Aug_Matrix(1,3) := to_sfixed( 0.000033333333333,d_left,d_right);
            A_Aug_Matrix(2,3) := to_sfixed( 0.000033333333333,d_left,d_right);       
      
         elsif Mode = 6 then
            A_Aug_Matrix(0,3) := to_sfixed(-0.000033333333333,d_left,d_right);
            A_Aug_Matrix(1,3) := to_sfixed( 0.000066666666667,d_left,d_right);
            A_Aug_Matrix(2,3) := to_sfixed(-0.000033333333333,d_left,d_right);
      
         elsif Mode = 7 then
            A_Aug_Matrix(0,3) := to_sfixed(-0.000033333333333,d_left,d_right);
            A_Aug_Matrix(1,3) := to_sfixed(-0.000033333333333,d_left,d_right);
            A_Aug_Matrix(2,3) := to_sfixed( 0.000066666666667,d_left,d_right);
      
         elsif Mode = 8 then
            A_Aug_Matrix(0,3) := to_sfixed(0,d_left,d_right);
            A_Aug_Matrix(1,3) := to_sfixed(0,d_left,d_right);
            A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right);
      
         else null;
         end if;
         
       -- B matrix
      A_Aug_Matrix(0,4) := b1;
      A_Aug_Matrix(0,5) := b2;
      A_Aug_Matrix(0,6) := b2;
      A_Aug_Matrix(1,4) := b2;
      A_Aug_Matrix(1,5) := b1;
      A_Aug_Matrix(1,6) := b2;
      A_Aug_Matrix(2,4) := b2;
      A_Aug_Matrix(2,5) := b2;
      A_Aug_Matrix(2,6) := b1;
      
      
             case State is
             ------------------------------------------
             --    State S0 (wait for start signal)
             ------------------------------------------
             when S0 =>
                 j0 <= 0; k0 <= 0; k1 <= 0; k2 <= 0;
                 Done <= '0';
                 Count0 <= 0;
      
                 if( Start = '1' ) then
                 
                     -- Inputs
                  State_inp_Matrix(3) := u_inp(0);
                  State_inp_Matrix(4) := u_inp(1);
                  State_inp_Matrix(5) := u_inp(2);
                  State_inp_Matrix(6) := u_inp(3);
                  
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
              --    State S2 (more of filling up) [1st mult operation]
              ---------------------------------------
              when S2 =>
                   A <= A_Aug_Matrix(j0, k0);
                   B <= State_inp_Matrix(k0);
            
                   P <= resize(A * B, P'high, P'low);
                   k0 <= k0 +1;
                   Count0 <= Count0 + 1;
                   State := S3;
      
             -------------------------------------------
             --    State S3 (even more of filling up) [2nd  mult op]
             -------------------------------------------
             when S3 =>
                  A <= A_Aug_Matrix(j0, k0);  
                  B <= State_inp_Matrix(k0);
            
                  P <= resize(A * B, P'high, P'low);
                  Sum <= resize(P, Sum'high, Sum'low);
                       
                  k1 <= k1+1;
                  k0 <= k0+1;
                  Count0 <= Count0 + 1;
                  State := S4;
            
              -------------------------------------------------
              --    State S4 (pipeline full, complete work) [total - 3] mult operation
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
      
                if (k1 = 6) then
                    k1 <= 0;
                else
                    k1 <= k1 + 1;
                end if;
                       
                    
                       ----------------------------------
                       -- check if all initiations done
                       ----------------------------------
                       if (Count0 = 20) then  -- value = total mult operation - 1 (30 - 1, 3x10 and 10x1)
                           State := S5;
                       else
                           State := S4;                
                           Count0 <= Count0 + 1;
                          if (k0 = 6) then
                           j0 <= j0 +1;
                           k0 <= 0;
                           else 
                           k0 <= k0 +1;
                           end if;
                       end if;
            
                   ------------------------------------------------
                   --    State S5 (start flushing the pipeline) [Last mult operation]
                   ------------------------------------------------
                   when S5 =>
                           P <= resize(A * B, P'high, P'low);
                           Sum <= resize(Sum + P, Sum'high, Sum'low);
                           State := S6;
      
                   -- Total time till here is 320 ns
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
                              Count0 <= 0;
                              k0 <= 0;
      
                   ------------------------------------
                   --    State S8 (output the data)
                   ------------------------------------
                   when S8 =>
                    State_inp_Matrix(0) := C_Matrix(0);
                    State_inp_Matrix(1) := C_Matrix(1);
                    State_inp_Matrix(2) := C_Matrix(2);
                    plt_z <=  C_Matrix;
                    State := S0;
                    done <= '1';
                    
     end case;
    end if;
   end process;

end Behavioral;
