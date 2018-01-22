-- With C = 1.85e-3 and L = 5 mH
-- State estimator
-- Use matlab file matrix_discretization.m in 2018 Jain_JESTPE Rewrite->simulation
library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.input_pkg.all;

entity plant_x is
    port (clk : in STD_LOGIC;
          start : in STD_LOGIC;
          -- Buck-boost operation
          mode : in INTEGER range 1 to 2;
          -- Plant input
          plt_u : in vect3; -- see through CRO
          -- Plant output
          plt_y : in vect2;
          -- Estimator outputs
          done : out STD_LOGIC := '0';
          fd_residual : out sfixed(n_left downto n_right) := zer0;
          plt_z : out vect4 := (zer0,zer0,zer0,zer0)
         );
end plant_x;

architecture Behavioral of plant_x is

---- Signals ----     
 
 -- Matrix
    signal	  Count0  : UNSIGNED (2 downto 0):="000";
    signal    A       : sfixed(d_left downto d_right);
    signal    B       : sfixed(n_left downto n_right);
    signal    P       : sfixed(A'left+B'left+1 downto A'right+B'right);
    signal    Sum        : sfixed(P'left+3 downto P'right);  -- +3 because of 3 sums would be done for one element [A:B]*[state input] = State(element)
    signal    j0, k0, k2, k3 : INTEGER := 0;
 -- Gamma cal
    signal gamma : vect4 := (zer0, zer0, zer0, zer0);

 -- digital twin estimate
    signal z_est : vect2 := (il0, vc0);
    signal pv_est : vect2 := (ipv, vpv);
    signal norm: sfixed(n_left downto n_right) := zer0;
    
begin
                
mult: process(clk, plt_u, plt_y, gamma)

   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10);
   variable     State         : STATE_VALUE := S0;
    
   -- digital twin cal
   -- Augmented A and B matrix   
   variable A_Aug_Matrix       : mat24 := ((zer0h, zer0h, zer0h, zer0h),
                                           (zer0h, zer0h, zer0h, zer0h));
   -- Output vector   
   variable C_vect             : vect2;
   -- Augmented estimation and input vector
   variable State_inp_vect     : vect4 := (il0, vc0, plt_u(0), plt_u(1));
  
   
   begin
              
   if (Clk'event and Clk = '1') then
    
   -- Update the inputs with latest value
    State_inp_vect(2) := plt_u(0);
    State_inp_vect(3) := plt_u(1);
   -- Outputs to main 
    plt_z <= z_est;
           
   
        case State is
         
               when S0 =>
               
           -- For starting the computation process
           j0 <= 0; k0 <= 0; k2 <= 0; k3 <= 0;
           Count0 <= "000";
           done <= '0';
           if( start = '1' ) then   
               State := S1;
           else
               State := S0;
           end if;
           
          -- For State Matrix calculation
           if mode = 1 then
           ----------------------------------------
           -- Mode 1:common mode
           ----------------------------------------
           A_Aug_Matrix(0,0) := a00d;
           A_Aug_Matrix(0,1) := a01d;
           A_Aug_Matrix(0,2) := a10d;
           A_Aug_Matrix(0,3) := a11d;
           A_Aug_Matrix(1,0) := b00d;
           A_Aug_Matrix(1,1) := zer0;
           A_Aug_Matrix(1,2) := zer0;
           A_Aug_Matrix(1,3) := b11d;          
                       
           elsif mode = 2 then
           ----------------------------------------
           -- Mode 2: Buck mode
           ----------------------------------------
           A_Aug_Matrix(0,0) := a00d;
           A_Aug_Matrix(0,1) := a01d;
           A_Aug_Matrix(0,2) := a10d;
           A_Aug_Matrix(0,3) := a11d;
           A_Aug_Matrix(1,0) := zer0;
           A_Aug_Matrix(1,1) := zer0;
           A_Aug_Matrix(1,2) := zer0;
           A_Aug_Matrix(1,3) := b11d;  
                      
           elsif mode = 3 then
          ----------------------------------------
          -- Mode 3: Boost mode
          ----------------------------------------
            A_Aug_Matrix(0,0) := a00d;
            A_Aug_Matrix(0,1) := zer0;
            A_Aug_Matrix(0,2) := zer0;
            A_Aug_Matrix(0,3) := a11d;
            A_Aug_Matrix(1,0) := b00d;
            A_Aug_Matrix(1,1) := zer0;
            A_Aug_Matrix(1,2) := zer0;
            A_Aug_Matrix(1,3) := b11d;    
           
           else null;       
           end if;
                   
    -------------------------------------------
    --    State S1 (filling up of pipeline)
    -------------------------------------------
       when S1 =>
       A <= A_Aug_Matrix(j0, k0);  
       B <= State_inp_vect(k0);
       k0 <= k0 +1;
       Count0 <= Count0 + 1;
       State := S2;

   ---------------------------------------
   --    State S2 (more of filling up)
   ---------------------------------------
   when S2 =>
       A <= A_Aug_Matrix(j0, k0);  
       B <= State_inp_vect(k0);

       P <= A * B;
       k0 <= k0 +1;
       Count0 <= Count0 + 1;
       State := S3;

   -------------------------------------------
   --    State S3 (even more of filling up)
   -------------------------------------------
   when S3 =>
       A <= A_Aug_Matrix(j0, k0);  
       B <= State_inp_vect(k0);

       P <= A * B;
       
       if (k2 = 0) then
           Sum <= resize(P, Sum'high, Sum'low);
       else             
           Sum <= resize(Sum + P, Sum'high, Sum'low);
       end if;
       k2 <= k2+1;
       k0 <= k0+1;
       Count0 <= Count0 + 1;
       State := S4;

   -------------------------------------------------
   --    State S4 (pipeline full, complete work)
   -------------------------------------------------
   when S4 =>
       A <= A_Aug_Matrix(j0, k0);  
       B <= State_inp_vect(k0);

       P <= A * B;

       if (k2 = 0) then
           Sum <= resize(P, Sum'high, Sum'low);
           C_vect(k3) := resize(Sum, n_left, n_right);
           k3 <= k3 +1;
       else
           Sum <= resize(Sum + P, Sum'high, Sum'low);
       end if;

       if (k2 = 3) then
           k2 <= 0;
           else
              k2 <= k2 + 1;
       end if;
       
    
       ----------------------------------
       -- check if all initiations done
       ----------------------------------
       if (Count0 = 7) then
           State := S5;
       else
           State := S4;                
           Count0 <= Count0 + 1;
          if (k0 = 3) then
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
              P <= A * B;           
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
                         
                 C_vect(k3) := resize(Sum, n_left, n_right);                 
                 State := S8;
                 Count0 <= "000";
                 k0 <= 0;
              
      ------------------------------------
      --    State S8 (output the data)
      ------------------------------------
      when S8 =>
      
       State_inp_vect(0) := C_vect(0);
       State_inp_vect(1) := C_vect(1);
       z_val <= C_vect;
       plt_z <=  C_vect;
       State := S9;
       
      when S9 =>
      gamma(0) <= resize(z_val(0) - plt_y(0), n_left, n_right);
      gamma(1) <= resize(z_val(1) - plt_y(1), n_left, n_right);
      gamma(2) <= resize(ipv - plt_u(2), n_left, n_right);
      gamma(3) <= resize(vpv - plt_u(0), n_left, n_right);
      State := S10;
                
     when S10 =>
        done <= '1';
        State := S0;
        
        end case;
        end if; -- clk
    end process;            
end Behavioral;
