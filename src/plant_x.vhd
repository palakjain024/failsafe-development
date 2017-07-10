-- With C = 2.85e-3 and L = 5 mH
-- Luneberger Observer
library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.input_pkg.all;

entity plant_x is
 port (  Clk : in STD_LOGIC;
         Start : in STD_LOGIC;
         Mode : in INTEGER range 1 to 4;
         load : in sfixed(n_left downto n_right);
         plt_y : in vect2;
         done : out STD_LOGIC := '0';
         FD_residual : out sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
         plt_z : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right))
        );
end plant_x;

architecture Behavioral of plant_x is
      -- Matrix cal 
      signal	Count0	: UNSIGNED (3 downto 0):="0000";
	  signal	A       : sfixed(d_left downto d_right);
	  -- signal	An      : sfixed(n_left downto n_right);
	  signal	B       : sfixed(n_left downto n_right);
	  signal	P       : sfixed(n_left downto n_right);
	  signal	Sum	    : sfixed(n_left downto n_right);
      signal 	j0, k0, k1, k2 : INTEGER := 0;
      
      -- For z calculation
      signal  z_val : vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
begin
mult: process(Clk, load, plt_y)

   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8);
   variable     State         : STATE_VALUE := S0;

   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat35;
   variable State_inp_Matrix     : vect5:= (il0, il0,  vc0, v_in, load);
   variable C_Matrix             : vect3;
   
   begin
              
   if (Clk'event and Clk = '1') then
      
      if Mode = 1 then
                 
                 -- A matrix
                 A_Aug_Matrix(0,0) := to_sfixed( 0.999988000000000,d_left,d_right);
                 A_Aug_Matrix(0,1) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(0,2) := to_sfixed(-0.000100000000000,d_left,d_right);
                 A_Aug_Matrix(1,0) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(1,1) := to_sfixed( 0.999991800000000,d_left,d_right);
                 A_Aug_Matrix(1,2) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(2,0) := to_sfixed( 0.000175438596491,d_left,d_right);
                 A_Aug_Matrix(2,1) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(2,2) := to_sfixed( 1,d_left,d_right);
                 
                 -- B matrix
                 A_Aug_Matrix(0,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(0,4) := to_sfixed(0.0000038,d_left,d_right);
                 A_Aug_Matrix(1,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(1,4) := to_sfixed(0,d_left,d_right);
                 A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right); 
                 A_Aug_Matrix(2,4) := to_sfixed(-0.000175438596491,d_left,d_right);
                 
       elsif Mode = 2 then
                 
                 -- A matrix
                 A_Aug_Matrix(0,0) := to_sfixed( 0.999991800000000,d_left,d_right);
                 A_Aug_Matrix(0,1) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(0,2) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(1,0) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(1,1) := to_sfixed( 0.999991800000000,d_left,d_right);
                 A_Aug_Matrix(1,2) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(2,0) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(2,1) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(2,2) := to_sfixed( 1,d_left,d_right);
                 
                 -- B matrix
                 A_Aug_Matrix(0,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(0,4) := to_sfixed(0,d_left,d_right);
                 A_Aug_Matrix(1,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(1,4) := to_sfixed(0,d_left,d_right);
                 A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right); 
                 A_Aug_Matrix(2,4) := to_sfixed(-0.000175438596491,d_left,d_right);  
                                
      elsif Mode = 3 then
                 -- A matrix
                 A_Aug_Matrix(0,0) := to_sfixed( 0.999991800000000,d_left,d_right);
                 A_Aug_Matrix(0,1) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(0,2) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(1,0) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(1,1) := to_sfixed( 0.999988000000000,d_left,d_right);
                 A_Aug_Matrix(1,2) := to_sfixed(-0.000100000000000,d_left,d_right);
                 A_Aug_Matrix(2,0) := to_sfixed( 0,d_left,d_right);
                 A_Aug_Matrix(2,1) := to_sfixed( 0.000175438596491,d_left,d_right);
                 A_Aug_Matrix(2,2) := to_sfixed( 1,d_left,d_right);
                 
                 -- B matrix
                 A_Aug_Matrix(0,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(0,4) := to_sfixed(0,d_left,d_right);
                 A_Aug_Matrix(1,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(1,4) := to_sfixed(0.0000038,d_left,d_right);
                 A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right); 
                 A_Aug_Matrix(2,4) := to_sfixed(-0.000175438596491,d_left,d_right);
         
      elsif Mode = 4 then
                 -- A matrix
                 A_Aug_Matrix(0,0) := to_sfixed( 0.999988000000000,d_left,d_right);
                 A_Aug_Matrix(0,1) := to_sfixed(-0.000003800000000,d_left,d_right);
                 A_Aug_Matrix(0,2) := to_sfixed(-0.000100000000000,d_left,d_right);
                 A_Aug_Matrix(1,0) := to_sfixed(-0.000003800000000,d_left,d_right);
                 A_Aug_Matrix(1,1) := to_sfixed( 0.999988000000000,d_left,d_right);
                 A_Aug_Matrix(1,2) := to_sfixed(-0.000100000000000,d_left,d_right);
                 A_Aug_Matrix(2,0) := to_sfixed( 0.000175438596491,d_left,d_right);
                 A_Aug_Matrix(2,1) := to_sfixed( 0.000175438596491,d_left,d_right);
                 A_Aug_Matrix(2,2) := to_sfixed( 1,d_left,d_right);
                 
                 -- B matrix
                 A_Aug_Matrix(0,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(0,4) := to_sfixed(0.0000038,d_left,d_right);
                 A_Aug_Matrix(1,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(1,4) := to_sfixed(0.0000038,d_left,d_right);
                 A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right); 
                 A_Aug_Matrix(2,4) := to_sfixed(-0.000175438596491,d_left,d_right); 
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
                  -- Initialization  
                  State_inp_Matrix(3) := v_in;
                  State_inp_Matrix(4) := load;
                  
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
              
              k1 <= k1+1;
              k0 <= k0+1;
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
   
              if (k1 = 4) then
                  k1 <= 0;
                  else
                  k1 <= k1 + 1;
              end if;
              
           
              ----------------------------------
              -- check if all initiations done
              ----------------------------------
              if (Count0 = 14) then
                  State := S5;
              else
                  State := S4;                
                  Count0 <= Count0 + 1;
                 if (k0 = 4) then
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
           State_inp_Matrix(0) := C_Matrix(0);
           State_inp_Matrix(1) := C_Matrix(1);
           State_inp_Matrix(2) := C_Matrix(2);
           plt_z <=  C_Matrix;
           z_val <= C_Matrix;
           State := S0;
  end case;
                 
        end if;         
    end process;             
end Behavioral;
