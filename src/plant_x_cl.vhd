-- With C = 2.85e-3 and L = 5e-3
-- State and parameter estimator
library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use work.input_pkg.all;

entity plant_x_cl is
     port (    clk : in STD_LOGIC;
               clk_ila : in STD_LOGIC;
               pc_en : in STD_LOGIC;
               ena : in STD_LOGIC;
               Start : in STD_LOGIC;
               Mode : in INTEGER range 0 to 2;
               pc_x : in vect2;
               load : in sfixed(n_left downto n_right);
               Vin  : in sfixed(n_left downto n_right);
               gain : in vect2;
               Done : out STD_LOGIC := '0';
               pc_theta : out vect2 := (theta_L_star,theta_C_star);
               pc_err : out vect2 := (zer0,zer0);
               pc_z : out vect2 := (zer0,zer0)
            );
end plant_x_cl;

architecture Behavioral of plant_x_cl is
     -- ILA core
    COMPONENT ila_0
    
    PORT (
        clk : IN STD_LOGIC;
    
    
    
        probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe6 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe7 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe8 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe9 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe10 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe11 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe12 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
    END COMPONENT  ;

    -- signal definitions --
    
    -- ILA core
     signal probe_thetaL, probe_thetaC : STD_LOGIC_VECTOR(31 downto 0);
     signal probe_x1, probe_x2 : STD_LOGIC_VECTOR(31 downto 0);
     signal probe_z1, probe_z2 : STD_LOGIC_VECTOR(31 downto 0);
     signal probe_e11, probe_e22 : STD_LOGIC_VECTOR(31 downto 0);
     signal probe_h11, probe_h12, probe_h21, probe_h22 : STD_LOGIC_VECTOR(31 downto 0);
     signal probe_ena : STD_LOGIC_VECTOR(0 downto 0);
     
    -- General purpose
   	signal	Count0 : UNSIGNED (2 downto 0):="000";
    signal	A      : sfixed(d_left downto d_right);
    signal	B      : sfixed(n_left downto n_right);
    signal	P      : sfixed(n_left + d_left + 1 downto n_right + d_right);
    signal	Sum	   : sfixed(n_left + d_left + 4 downto n_right + d_right);  -- +3 because of 3 sums would be done for one element [A:B]*[state input] = State(element)
    signal 	j0, k0, k2, k3 : INTEGER := 0;
    signal wa : sfixed(n_left downto n_right);
    signal wb : sfixed(n_left downto n_right);
    
    -- For error calculation
    signal err_val : vect2 := (zer0,zer0);
    signal   z_val : vect2 := (il0,vc0);
    
    -- For Gain matrix
    signal G : gain_mat := ((zer0h, zer0h),
                            (zer0h, zer0h));
    signal LO_err : discrete_vect2 := (zer0h, zer0h);
    
    -- For w discretized matrix
    signal w : discrete_mat22 := ((zer0h,zer0h),
                                  (zer0h,zer0h));
    -- H matrix
   signal H_est : H_mat22 := ((zer0_H_mat, zer0_H_mat),
                              (zer0_H_mat, zer0_H_mat)); 
   signal H_mem : H_mat22 := ((zer0_H_mat, zer0_H_mat),
                              (zer0_H_mat, zer0_H_mat));
                                
    -- gain * H_est transpose * discretixed error
    signal h_err :   vect2;
    signal g_h_err : vect2;
    signal h_g_h_err : vect2 := (zer0, zer0);
    
    -- Theta
    signal theta_est : vect2 := (theta_L_star,theta_C_star);
    
begin

---- Instances -----
ila_inst_1: ila_0
PORT MAP (
    clk => clk_ila,

    probe0 => probe_thetaL, 
    probe1 => probe_thetaC, 
    probe2 => probe_x1, 
    probe3 => probe_x2, 
    probe4 => probe_z1,
    probe5 => probe_z2,
    probe6 => probe_e11,
    probe7 => probe_e22,
    probe8 => probe_h11,
    probe9 => probe_h12,
    probe10 => probe_h21,
    probe11 => probe_h22,
    probe12 => probe_ena
    
); 
mult: process(Clk, load)
  
   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19, S20, S21);
   variable State         : STATE_VALUE := S0;
   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat24;
   variable State_inp_Matrix     : vect4 := (il0, vc0, v_in, load);
   variable C_Matrix             : vect2;

   begin
           
   if (Clk'event and Clk = '1') then
   
   
   ---- ILA ----
   probe_thetaL  <= result_type(theta_est(0));
   probe_thetaC <= result_type(theta_est(1)) ; 
   probe_x1 <= result_type(pc_x(0));
   probe_x2 <= result_type(pc_x(1));
   probe_z1 <= result_type(z_val(0));
   probe_z2 <= result_type(z_val(1));
   probe_e11 <= result_type(G(0,0));
   probe_e22 <= result_type(G(1,1));
   probe_h11 <= result_type(Vin);
   probe_h12 <= result_type(H_est(0,1));
   probe_h21 <= result_type(H_est(1,0));
   probe_h22 <= result_type(H_est(1,1));
   probe_ena(0) <= ena;
   
                
              
       case State is
       ------------------------------------------
       --    State S0 (wait for start signal)
       ------------------------------------------
       when S0 =>
       
       -- To enable state estimation
       if pc_en = '0' then
       z_val(0) <= il0;
       z_val(1) <= vc0;
       err_val(0) <= zer0;
       err_val(1) <= zer0;
       h_g_h_err(0) <= zer0;
       h_g_h_err(1) <= zer0;
       H_mem(0,0) <= zer0_H_mat;
       H_mem(0,1) <= zer0_H_mat;
       H_mem(1,0) <= zer0_H_mat;
       H_mem(1,1) <= zer0_H_mat;
       end if;
       
       -- To enable parameter estimator algorithm
       if ena = '1' then
         --G(0,0) <= resize(-h * gain, d_left, d_right);
         G(0,0) <= resize(e11, d_left, d_right);
         G(0,1) <= zer0h;
         G(1,0) <= zer0h;
         G(1,1) <= resize(e22, d_left, d_right);
         
         else
         G <= ((zer0h, zer0h),
               (zer0h, zer0h));
         theta_est(0) <= theta_L_star;
         theta_est(1) <= theta_C_star;
         end if;
         
        ----- Dont do this kind of baakchodi -----   
        --  if theta_est(0) < to_sfixed(0,15,-16) or theta_est(1) < to_sfixed(0,15,-16) then
        --  theta_est(0) <= theta_L_star;
        --  theta_est(1) <= theta_C_star;
        --  end if;
           
        -- For starting the computation process
           j0 <= 0; k0 <= 0; k2 <= 0; k3 <= 0;
           Done <= '0';
           Count0 <= "000";
           if( Start = '1' ) then
               State := S1;
              ---- Vector initialization ----
               State_inp_Matrix(0) := z_val(0);
               State_inp_Matrix(1) := z_val(1);
               State_inp_Matrix(2) := Vin;
               State_inp_Matrix(3) := load;
                       
                       
           else
               State := S0;
           end if;
           
         -- For State Matrix calculation
         if Mode = 1 then
         ----------------------------------------
         -- Mode 0 - A:B matrix diode is conducting
         ----------------------------------------
         A_Aug_Matrix(0,0) := resize(to_sfixed(1, n_left, n_right) + (h*rL)*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,1) := resize(-h*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,2) := resize(h*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,3) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,0) := resize(h*theta_est(1), d_left, d_right);
         A_Aug_Matrix(1,1) := to_sfixed(1, d_left, d_right);
         A_Aug_Matrix(1,2) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,3) := resize(-h*theta_est(1), d_left, d_right);          
                     
         elsif Mode = 2 then
         ----------------------------------------
         -- Mode 1 - A:B matrix Switch is conducting current building up
         ----------------------------------------
         A_Aug_Matrix(0,0) := resize(to_sfixed(1, n_left, n_right) + (h*rL)*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,1) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(0,2) := resize(h*theta_est(0), d_left, d_right);
         A_Aug_Matrix(0,3) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,0) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,1) := to_sfixed(1, d_left, d_right);
         A_Aug_Matrix(1,2) := to_sfixed(0, d_left, d_right);
         A_Aug_Matrix(1,3) := resize(-h*theta_est(1), d_left, d_right); 
                    
         else
         A_Aug_Matrix(0,0) := resize(to_sfixed(1, n_left, n_right) + (h*rL)*theta_est(0), d_left, d_right);
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
        
        -- LO*err
        LO_err(0) <= resize((l11 * err_val(0)) + (l12 * err_val(1)), d_left, d_right);
        LO_err(1) <= resize((l21 * err_val(0)) + (l22 * err_val(1)), d_left, d_right);   
        
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
            C_Matrix(k3) := resize(Sum - LO_err(0) + h_g_h_err(0), n_left, n_right);
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
                          
                  C_Matrix(k3) := resize(Sum - LO_err(1) + h_g_h_err(1), n_left, n_right);                 
                  State := S8;
                  Count0 <= "000";
                  k0 <= 0;
               
       ------------------------------------
       --    State S8 (output the data)
       ------------------------------------
       when S8 =>
        -- Don't do this as it may cause trouble depending upon the initial conditions. Stop this baakchodi here
        -- if C_Matrix(0) < zer0 or C_Matrix(1) < zer0 then
        
        -- z_val(0) <= zer0;
        -- z_val(1) <= zer0;
        -- pc_z(0) <= zer0;
        -- pc_z(1) <= zer0;
        
        -- else                           
        
        z_val <= C_Matrix;
        pc_z <=  C_Matrix;
        
        -- end if;
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
       
       -- mode 2 means less terms, mode 1 means more term
        if mode = 1 then
        State := S11;
        else
        State := S12;
        end if;
        B <= resize(rL*z_val(0), B'high, B'low);
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
        H_est(0,0) <= resize((A_Aug_Matrix(0,0) - l11) * H_mem(0,0),7, -24);
        H_est(0,1) <= resize((A_Aug_Matrix(0,0) - l11) * H_mem(0,1),7, -24);
        H_est(1,0) <= resize((A_Aug_Matrix(1,0) - l21) * H_mem(0,0),7, -24);
        H_est(1,1) <= resize((A_Aug_Matrix(1,0) - l21) * H_mem(0,1),7, -24);
        State := S15;
       
        when S15 =>
        H_est(0,0) <= resize(H_est(0,0) + (A_Aug_Matrix(0,1) - l12) * H_mem(1,0) + w(0,0),7, -24);
        H_est(0,1) <= resize(H_est(0,1) + (A_Aug_Matrix(0,1) - l12) * H_mem(1,1),7, -24);
        H_est(1,0) <= resize(H_est(1,0) + (A_Aug_Matrix(1,1) - l22) * H_mem(1,0),7, -24);
        H_est(1,1) <= resize(H_est(1,1) + (A_Aug_Matrix(1,1) - l22) * H_mem(1,1) + w(1,1),7, -24);
        State := S16;
                 

       when S16 =>
       H_mem(0,0) <= H_est(0,0);
       H_mem(0,1) <= H_est(0,1);
       H_mem(1,0) <= H_est(1,0);
       H_mem(1,1) <= H_est(1,1);
       State := S17;
        
        -----------------------------------------
        -- Gradient descent calculation
        -----------------------------------------
       when S17 =>
        h_err(0) <= resize((H_est(0,0)*err_val(0)) + (H_est(1,0)*err_val(1)), n_left, n_right);
        h_err(1) <= resize((H_est(0,1)*err_val(0)) + (H_est(1,1)*err_val(1)), n_left, n_right);
        State := S18;
       
       when S18 =>
        
        g_h_err(0) <= resize(G(0,0)*h_err(0), n_left, n_right);
        g_h_err(1) <= resize(G(1,1)*h_err(1), n_left, n_right);
        State := S19;
        
       when S19 =>
        
        h_g_h_err(0) <= resize((H_est(0,0) * g_h_err(0)) + (H_est(0,1) * g_h_err(1)), n_left, n_right);
        h_g_h_err(1) <= resize((H_est(1,0) * g_h_err(0)) + (H_est(1,1) * g_h_err(1)), n_left, n_right);
        State := S20;
        
        when S20 =>
        
        theta_est(0) <= resize(theta_est(0) + g_h_err(0), n_left, n_right);
        theta_est(1) <= resize(theta_est(1) + g_h_err(1), n_left, n_right);
        State := S21;
                 
       When S21 =>
        Done <= '1';
        pc_theta <= theta_est; 
        State := S0;
       
     end case;
   end if;
 end process;
end Behavioral;
