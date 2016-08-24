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
     port (   Clk : in STD_LOGIC;
              ena : in STD_LOGIC;
              Start : in STD_LOGIC;
              Mode : in INTEGER range 0 to 2;
              pc_x : in vect2;
              load : in sfixed(n_left downto n_right);
              Done : out STD_LOGIC := '0';
              pc_theta : out vect2 := (theta_L_star,theta_C_star);
              pc_err : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
              pc_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
           );
end plant_x;

architecture Behavioral of plant_x is
    
   	signal	Count0 : UNSIGNED (2 downto 0):="000";
    signal	A      : sfixed(d_left downto d_right);
    signal	B      : sfixed(n_left downto n_right);
    signal	P      : sfixed(n_left + d_left + 1 downto n_right + d_right);
    signal	Sum	   : sfixed(n_left + d_left + 4 downto n_right + d_right);  -- +3 because of 3 sums would be done for one element [A:B]*[state input] = State(element)
    signal 	j0, k0, k2, k3 : INTEGER := 0;
    signal wa : sfixed(n_left downto n_right);
    signal wb : sfixed(n_left downto n_right);
    -- For error calculation
    signal err_val : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
    signal err_val_d : discrete_vect2 := (to_sfixed(0,d_left,d_right),to_sfixed(0,d_left,d_right));
    signal   z_val : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
    
    -- For Gain matrix
    signal G : gain_mat; -- Negative of G matrix
    
    -- For w discretized matrix
    signal w : discrete_mat22 := ((to_sfixed(0,d_left,d_right),to_sfixed(0,d_left,d_right)),
                                  (to_sfixed(0,d_left,d_right),to_sfixed(0,d_left,d_right)));
    -- H matrix
   signal H_est : H_mat22 := ((to_sfixed(0.00100, 2, d_right), to_sfixed(0, 2, d_right)),
                                      (to_sfixed(0, 2, d_right), to_sfixed(0.00100, 2, d_right))); 
   signal H_mem : H_mat22 := ((to_sfixed(0.00100, 2, d_right), to_sfixed(0, 2, d_right)),
                                      (to_sfixed(0, 2, d_right), to_sfixed(0.00100, 2, d_right)));
    -- H_est transpose * discretixed error * gain
    signal h_err : discrete_vect2;
    signal g_h_err : vect2;
    -- Theta
    signal theta_est : vect2 := (theta_L_star,theta_C_star);
    
begin

mult: process(Clk, load)
  
   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20);
   variable     State         : STATE_VALUE := S0;
   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat24;
   variable State_inp_Matrix     : vect4:= (il0, vc0, v_in, load);
   variable C_Matrix             : vect2;

   begin
           
   if (Clk'event and Clk = '1') then
   State_inp_Matrix(2) := v_in;
   State_inp_Matrix(3) := load;
   
                 
              
       case State is
       ------------------------------------------
       --    State S0 (wait for start signal)
       ------------------------------------------
       when S0 =>
       
       -- To enable parameter estimator algorithm
           if ena = '1' then
             G <= ((e11, to_sfixed(0,24,-10)),
                   (to_sfixed(0,24,-10), e22));
             else
             G <= ((to_sfixed(0,24,-10), to_sfixed(0,24,-10)),
                   (to_sfixed(0,24,-10), to_sfixed(0,24,-10)));
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
         if Mode = 0 then
         ----------------------------------------
         -- Mode 0 - A:B matrix diode is conducting
         ----------------------------------------
         A_Aug_Matrix(0,0) := resize(to_sfixed(1, n_left, n_right) + (h*r)*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,1) := resize(-h*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,2) := resize(h*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,3) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,0) := resize(h*theta_est(1), d_left, d_right);
         A_Aug_Matrix(1,1) := to_sfixed(1, d_left, d_right);
         A_Aug_Matrix(1,2) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,3) := resize(-h*theta_est(1), d_left, d_right);          
                     
         elsif Mode = 1 then
         ----------------------------------------
         -- Mode 1 - A:B matrix Switch is conducting current building up
         ----------------------------------------
         A_Aug_Matrix(0,0) := resize(to_sfixed(1, n_left, n_right) + (h*r)*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,1) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(0,2) := resize(h*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,3) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,0) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,1) := to_sfixed(1, d_left, d_right);
         A_Aug_Matrix(1,2) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,3) := resize(-h*theta_est(1), d_left, d_right); 
                    
         else
         A_Aug_Matrix(0,0) := resize(to_sfixed(1, n_left, n_right) + (h*r)*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,1) := resize(-h*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,2) := resize(h*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,3) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,0) := resize(h*theta_est(1), d_left, d_right);
         A_Aug_Matrix(1,1) := to_sfixed(1, d_left, d_right);
         A_Aug_Matrix(1,2) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,3) := resize(-h*theta_est(1), d_left, d_right);          
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
        z_val <= C_Matrix;
        pc_z <=  C_Matrix;
        State := S9;
        
       when S9 =>
       err_val(0) <= resize(z_val(0) - pc_x(0), n_left, n_right);
       err_val(1) <= resize(z_val(1) - pc_x(1), n_left, n_right);
       State := S10;
       ---------------------------------------
       -- Calculation of W matrix
       ---------------------------------------
       when S10 =>
       pc_err <= err_val;
       
       -- mode 1 means less terms, mode 0 means more term
        if mode = 1 then
        State := S12;
        else
        State := S11;
        end if;
        B <= resize(r*z_val(0), B'high, B'low);
      -- W martix calculation     
        when S11 =>
        wa <= resize((B - z_val(1)) + v_in, wa'high, wa'low);
        wb <= resize(z_val(0) - load, wb'high, wb'low);
        State := S13;
        when S12 =>
        wa <= resize(B + v_in, wa'high, wa'low);
        wb <= resize(to_sfixed(-1,n_left,n_right) * load, wb'high, wb'low);
        State := S13;
        
        when S13 =>
        w(0,0) <= resize(h*wa, d_left, d_right);
        w(1,1) <= resize(h*wb, d_left, d_right);
        State := S14;
       ------------------------------------------------
       -- H matrix calculation 
       -----------------------------------------------
        when S14 =>
        H_est(0,0) <= resize(A_Aug_Matrix(0,0) * H_mem(0,0) + A_Aug_Matrix(0,1) * H_mem(1,0) + w(0,0),2, d_right);
        H_est(0,1) <= resize(A_Aug_Matrix(0,0) * H_mem(0,1) + A_Aug_Matrix(0,1) * H_mem(1,1),2, d_right);
        H_est(1,0) <= resize(A_Aug_Matrix(1,0) * H_mem(0,0) + A_Aug_Matrix(1,1) * H_mem(1,0),2, d_right);
        H_est(1,1) <= resize(A_Aug_Matrix(1,0) * H_mem(0,1) + A_Aug_Matrix(1,1) * H_mem(1,1) + w(1,1),2, d_right);
        State := S15;
       
       When S15 =>
         H_mem(0,0) <= H_est(0,0);
         H_mem(0,1) <= H_est(0,1);
         H_mem(1,0) <= H_est(1,0);
         H_mem(1,1) <= H_est(1,1);
         State := S16;
                 
     -----------------------------------------
     -- Error discretization
     -----------------------------------------
       when S16 =>
        err_val_d(0) <= resize(h*err_val(0), d_left, d_right);
        err_val_d(1) <= resize(h*err_val(1), d_left, d_right);
        State := S17;
        
       when S17 =>
        h_err(0) <= resize((H_est(0,0)*err_val_d(0)) + (H_est(1,0)*err_val_d(1)), d_left, d_right);
        h_err(1) <= resize((H_est(0,1)*err_val_d(0)) + (H_est(1,1)*err_val_d(1)), d_left, d_right);
        State := S18;
       
       when S18 =>
        g_h_err(0) <= resize(G(0,0)*h_err(0), n_left, n_right);
        g_h_err(1) <= resize(G(1,1)*h_err(1), n_left, n_right);
        State := S19;
        
       when S19 =>
        theta_est(0) <= resize(theta_est(0) + g_h_err(0), n_left, n_right);
        theta_est(1) <= resize(theta_est(1) + g_h_err(1), n_left, n_right);
        State := S20;
                 
       When S20 =>
        Done <= '1';
        pc_theta <= theta_est; 
        State := S0;
       
     end case;
   end if;
 end process;
end Behavioral;