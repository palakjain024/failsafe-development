-- With C = 100e-06 and L = 5 mH
library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use work.input_pkg.all;

entity plant_x is
       port (  Clk : in STD_LOGIC;
               ena : in STD_LOGIC;
               Start : in STD_LOGIC;
               pc_x : in sfixed(n_left downto n_right);
               vpv : in sfixed(n_left downto n_right);
               Done : out STD_LOGIC := '0';
               pc_theta : out vect3Q := (theta_L_star,theta_C_star,theta_RC_star);
               pc_err : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
               pc_z : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right)
           );
end plant_x;

architecture Behavioral of plant_x is
    
   	signal	Count0 : UNSIGNED (2 downto 0):= "000";
    signal	A      : sfixed(d_left downto d_right);
    signal	B      : sfixed(n_left downto n_right);
    signal	P      : sfixed(n_left + d_left + 1 downto n_right + d_right);
    signal	Sum	   : sfixed(n_left + d_left + 4 downto n_right + d_right); 
     -- +3 because of 3 sums would be done for one element [A:B]*[state input] = State(element)
    signal 	j0, k0, k2, k3 : INTEGER := 0;
     
    -- For error calculation
    signal err_val   : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
       
    -- For z estimation
    signal     z_val : vect2 := (to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
    
    -- For Gain matrix
    signal G : gain_mat; -- Negative of G matrix
    
    -- For w discretized matrix
    signal wa : sfixed(n_left downto n_right);
    signal w : discrete_mat23 := ((to_sfixed(0,d_left,d_right),to_sfixed(0,d_left,d_right),to_sfixed(0,d_left,d_right)),
                                  (to_sfixed(0,d_left,d_right),to_sfixed(0,d_left,d_right),to_sfixed(0,d_left,d_right)));
                                  
    -- H and L matrix
   signal L_est : L_mat23 := ((to_sfixed(0.001, lmat_left, lmat_right), to_sfixed(0.001, lmat_left, lmat_right), to_sfixed(0.001, lmat_left, lmat_right)),
                              (to_sfixed(0.001, lmat_left, lmat_right), to_sfixed(0.001, lmat_left, lmat_right), to_sfixed(0.001, lmat_left, lmat_right))); 
   signal L_mem : L_mat23 := ((to_sfixed(0.001, lmat_left, lmat_right), to_sfixed(0.001, lmat_left, lmat_right), to_sfixed(0.001, lmat_left, lmat_right)),
                              (to_sfixed(0.001, lmat_left, lmat_right), to_sfixed(0.001, lmat_left, lmat_right), to_sfixed(0.001, lmat_left, lmat_right)));
   
   signal H_est : vect3H := (to_sfixed(0.001, lmat_left, lmat_right), to_sfixed(0.001, lmat_left, lmat_right), to_sfixed(0.001, lmat_left, lmat_right));
    -- H_est transpose * discretixed error * gain
    signal h_err : vect3;
    signal g_h_err : vect3;
    -- Theta
    signal theta_est : vect3Q := (theta_L_star,theta_C_star,theta_RC_star);
    
begin

mult: process(Clk, vpv)
  
   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19);
   variable     State         : STATE_VALUE := S0;
   variable A_Aug_Matrix         : mat24;
   variable State_inp_Matrix     : vect4:= (il0, vc0, vpv, to_sfixed(0,n_left,n_right));
   variable C_Matrix             : vect2;

   begin
           
   if (Clk'event and Clk = '1') then
   State_inp_Matrix(2) := vpv;
   State_inp_Matrix(3) := to_sfixed(0, n_left, n_right);
   
                 
              
       case State is
       ------------------------------------------
       --    State S0 (wait for start signal)
       ------------------------------------------
       when S0 =>
       
       -- To enable parameter estimator algorithm
       -- Gain are multiplied by h so lesser precision will be fine
           if ena = '1' then
             G <= (e11, e22, e33);
             else
             G <= (e00, e00, e00);
                 
           end if;
        -- For starting the computation process
           j0 <= 0; k0 <= 0; k2 <= 0; k3 <= 0;
            Done <= '0';
            Count0 <= "000";
           if( Start = '1' ) then
               State := S1;
           else
               State := S0;
           end if;
         -- For State Matrix calculation
         A_Aug_Matrix(0,0) := resize(to_sfixed(1, n_left, n_right) + (h*r)*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,1) := resize(to_sfixed(-1, n_left, n_right)*h * theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,2) := resize(h * theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,3) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,0) := resize(h * theta_est(1), d_left, d_right);
         A_Aug_Matrix(1,1) := resize(to_sfixed(1, n_left, n_right) - h*theta_est(2), d_left, d_right);
         A_Aug_Matrix(1,2) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,3) := to_sfixed(0, d_left, d_right);          
                     
        

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

        P <= A * B;
        k0 <= k0 +1;
        Count0 <= Count0 + 1;
        State := S3;

    -------------------------------------------
    --    State S3 (even more of filling up)
    -------------------------------------------
    when S3 =>
        A <= A_Aug_Matrix(j0, k0);  
        B <= State_inp_Matrix(k0);

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
        B <= State_inp_Matrix(k0);

        P <= A * B;

        if (k2 = 0) then
            Sum <= resize(P, Sum'high, Sum'low);
            C_Matrix(k3) := resize(Sum, n_left, n_right);
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
                          
                  C_Matrix(k3) := resize(Sum, n_left, n_right);                 
                  State := S8;
                  Count0 <= "000";
                  k0 <= 0;
               
       ------------------------------------
       --    State S8 (output the data)
       ------------------------------------
       when S8 =>
       
        State_inp_Matrix(0) := C_Matrix(0);
        State_inp_Matrix(1) := C_Matrix(1);
        -- remember to revert sign of z in W mat
        z_val(0) <= resize(to_sfixed(-1, n_left, n_right) * C_Matrix(0), n_left, n_right);
        z_val(1) <= C_Matrix(1);
        pc_z <=  resize(to_sfixed(-1, n_left, n_right) * C_Matrix(0), n_left, n_right);
        State := S9;
        
       when S9 =>
       err_val <= resize(z_val(0) - pc_x, n_left, n_right);
       State := S10;
      
       when S10 =>
       pc_err <= err_val;
       B <= resize(r*C_Matrix(0), B'high, B'low);
       State := S11;
       -------------------------------------
       -- W martix calculation 
       --------------------------------------    
        when S11 =>
        wa <= resize(B - z_val(1) + vpv, wa'high, wa'low);
        State := S12;
        ---------------------------------------
        -- Discretization of W matrix
        ---------------------------------------
        when S12 =>
        w(0,0) <= resize(h*wa, d_left, d_right);
        w(1,1) <= resize(h*C_Matrix(0), d_left, d_right);
        w(1,2) <= resize(h*to_sfixed(-1,n_left,n_right)*C_Matrix(1), d_left, d_right);
        
        State := S13;
       ------------------------------------------------
       -- H matrix calculation 
       -----------------------------------------------
        when S13 =>
        L_est(0,0) <= resize(A_Aug_Matrix(0,0) * L_mem(0,0) + A_Aug_Matrix(0,1) * L_mem(1,0) + w(0,0), lmat_left, lmat_right);
        L_est(0,1) <= resize(A_Aug_Matrix(0,0) * L_mem(0,1) + A_Aug_Matrix(0,1) * L_mem(1,1), lmat_left, lmat_right);
        L_est(0,2) <= resize(A_Aug_Matrix(0,0) * L_mem(0,2) + A_Aug_Matrix(0,1) * L_mem(1,2), lmat_left, lmat_right);
        L_est(1,0) <= resize(A_Aug_Matrix(1,0) * L_mem(0,0) + A_Aug_Matrix(1,1) * L_mem(1,0), lmat_left, lmat_right);
        L_est(1,1) <= resize(A_Aug_Matrix(1,0) * L_mem(0,1) + A_Aug_Matrix(1,1) * L_mem(1,1) + w(1,1), lmat_left, lmat_right);
        L_est(1,2) <= resize(A_Aug_Matrix(1,0) * L_mem(0,2) + A_Aug_Matrix(1,1) * L_mem(1,2) + w(1,2), lmat_left, lmat_right);
        State := S14;
       
       When S14 =>
         L_mem(0,0) <= L_est(0,0);
         L_mem(0,1) <= L_est(0,1);
         L_mem(0,2) <= L_est(0,2);
         L_mem(1,0) <= L_est(1,0);
         L_mem(1,1) <= L_est(1,1);
         L_mem(1,2) <= L_est(1,2);
         State := S15;
                 
     -----------------------------------------
     -- Error discretization
     -----------------------------------------
       when S15 =>
        H_est(0) <= resize(to_sfixed(-1, n_left, n_right) * L_est(0,0), n_left, n_right);
        H_est(1) <= resize(to_sfixed(-1, n_left, n_right) * L_est(0,1), n_left, n_right);
        H_est(2) <= resize(to_sfixed(-1, n_left, n_right) * L_est(0,2), n_left, n_right);
        State := S16;
        
       when S16 =>
        h_err(0) <= resize(L_est(0,0)*err_val, n_left, n_right);
        h_err(1) <= resize(L_est(0,1)*err_val, n_left, n_right);
        h_err(2) <= resize(L_est(0,2)*err_val, n_left, n_right);
        State := S17;
       
       when S17 =>
        g_h_err(0) <= resize(G(0)*h_err(0), n_left, n_right);
        g_h_err(1) <= resize(G(1)*h_err(1), n_left, n_right);
        g_h_err(2) <= resize(G(2)*h_err(2), n_left, n_right);
        State := S18;
        
       when S18 =>
        theta_est(0) <= resize(theta_est(0) + g_h_err(0), 29, -2);
        theta_est(1) <= resize(theta_est(1) + g_h_err(1), 29, -2);
        theta_est(2) <= resize(theta_est(2) + g_h_err(2), 29, -2);
        State := S19;
                 
       When S19 =>
        Done <= '1';
        pc_theta <= theta_est; 
        State := S0;
       
     end case;
   end if;
 end process;
end Behavioral;