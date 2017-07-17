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
         plt_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
        );
end plant_x;

architecture Behavioral of plant_x is

---- Components ----
---- Signals ----     
 -- Matrix and sigh cal L*h*e
    signal    A       : sfixed(d_left downto d_right);
    
    
    signal    P_sigh1       : sfixed(n_left downto n_right);
    signal    P_sigh2       : sfixed(n_left downto n_right);
    signal    P_load        : sfixed(n_left downto n_right);
    signal    B       : sfixed(n_left downto n_right);
    signal    C       : sfixed(n_left downto n_right);
    signal    D       : sfixed(n_left downto n_right);
    
    signal    P       : sfixed(n_left downto n_right);
    signal    Sum        : sfixed(n_left downto n_right); 

 -- Error correction
    signal le : vect3 := (zer0, zer0, zer0);
    signal err : vect2 := (zer0, zer0);

 -- z estimate
    signal z_est : vect3 := (il0, il0, vc0);
    signal y_est: vect2 := (yil0 ,vc0);
    signal norm: sfixed(n_left downto n_right) := zer0;
 
  -- Sigh cal
    signal sigh1_out, sigh2_out, sigh3_out : vecth3;
    signal sigh1_noh, sigh2_noh : vect3;
    signal sigh3_noh: vect4;
    
begin
                
mult: process(Clk, load, plt_y)

   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17,
   S18, S19, S20);
   variable     State         : STATE_VALUE := S0;
    
   -- LE cal
   variable A_Aug_Matrix         : mat32 := ((zer0, zer0),
                                             (zer0, zer0),
                                             (zer0, zer0));
   variable err_Matrix           : vect2 := (err(0), err(1));
   
   variable C_Matrix             : vect3;
   
   -- Sigh cal
   variable State_inp_Matrix     : vect3 := (il0, il0, vc0);
  
   
   begin
              
   if (Clk'event and Clk = '1') then
   
   -- output 
      plt_z <= y_est;
      FD_residual <= norm;
 
    -- L matrix
    A_Aug_Matrix(0,0) := to_sfixed(-0.000001558800000000,d_left,d_right);
    A_Aug_Matrix(0,1) := to_sfixed(-0.000099688000000000,d_left,d_right);
    A_Aug_Matrix(1,0) := to_sfixed(-0.000001558800000000,d_left,d_right);
    A_Aug_Matrix(1,1) := to_sfixed(-0.000099688000000000,d_left,d_right);
    A_Aug_Matrix(2,0) := to_sfixed( 0.000175197200000000 ,d_left,d_right);
    A_Aug_Matrix(2,1) := to_sfixed( 0.000007515600000000,d_left,d_right);
           
---- Step 2:  Multiplication -----
        case State is
         --  State S0 (wait for start signal)
               when S0 =>
                   
                   done <= '0';
                   if( start = '1' ) then   
                        State := S1;
                       -- Error cal
                       err(0) <= resize(plt_y(0) - y_est(0), n_left, n_right);
                       err(1) <= resize(plt_y(1) - y_est(1), n_left, n_right); 
                   else
                       State := S0;
                   end if;
                   
        -- Sigh Calculation
               when S1 =>
               -- Error intialization
                err_Matrix(0) := err(0);
                err_Matrix(1) := err(1);  
              
               -- Sigh calculation
                A <= rL;
                B <= State_inp_Matrix(0);
                C <= State_inp_Matrix(1);
                D <= load;
               
                
                State := S2;
               
               when S2 =>
               
               -- Sigh calculation
                A <= esr;
                B <= State_inp_Matrix(0);
                C <= State_inp_Matrix(1);
                D <= load;
                
                P_sigh1 <= resize(A * B, n_left, n_right);
                P_sigh2 <= resize(A * C, n_left, n_right);
                
               -- Sigh3 for Capacitor
               sigh3_noh(0) <= resize(B - D, n_left, n_right); -- Mode 1
               sigh3_noh(1) <= resize(to_sfixed(-1, n_left, n_right) * D, n_left, n_right); -- Mode 2
               sigh3_noh(2) <= resize(C - D, n_left, n_right); -- Mode 3
               sigh3_noh(3) <= resize(B + C, n_left, n_right); -- Mode 4

                State := S3;
                
               when S3 =>
               
               -- Norm calculation
               C <= err(0);
               D <= err(0);
                                                      
               -- Sigh calculation
               P_sigh1 <= resize(A * B, n_left, n_right);
               P_sigh2 <= resize(A * C, n_left, n_right);
               P_load  <= resize(A * D, n_left, n_right);
               
               -- sigh1 for L1
               sigh1_noh(1) <= resize(v_in - P_sigh1, n_left, n_right); --Mode 2,3
               
               -- sigh2 for L2
               sigh2_noh(0) <= resize(v_in - P_sigh2, n_left, n_right); -- Mode 1,2 
               
               -- sigh3 for capacitor
               sigh3_noh(3) <= resize(sigh3_noh(3) - D, n_left, n_right); -- Mode 4
               
               State := S4;
               
               when S4 =>
               -- Norm calculation
               C <= err(1);
               D <= err(1); 
               P <= resize(C * D, n_left, n_right);
                               
               -- Sigh calculation
               B <= State_inp_Matrix(2);
               -- sigh1 for L1
               sigh1_noh(0) <= resize(sigh1_noh(1) - P_sigh1 + P_load, n_left, n_right);  -- Mode 1
               sigh1_noh(2) <= resize(sigh1_noh(1) - P_sigh1 - P_sigh2 + P_load, n_left, n_right);  -- Mode 4
               
               -- sigh2 for L2
               sigh2_noh(1) <= resize(sigh2_noh(0) - P_sigh2 + P_load, n_left, n_right); -- Mode 3
               sigh2_noh(2) <= resize(sigh2_noh(0) - P_sigh2 - P_sigh1 + P_load, n_left, n_right); -- Mode 4
               
               State := S5;
               
               when S5 =>
               -- Norm calculation
               Sum <= P;
               P <= resize(C * D, n_left, n_right);
                              
               -- sigh1 for L1
               sigh1_noh(0) <= resize(sigh1_noh(0) - B, n_left, n_right); -- Mode 1
               sigh1_noh(2) <= resize(sigh1_noh(2) - B, n_left, n_right); -- Mode 4
               
               -- sigh2 for L2
               sigh2_noh(1) <= resize(sigh2_noh(1) - B, n_left, n_right); -- Mode 3
               sigh2_noh(2) <= resize(sigh2_noh(2) - B, n_left, n_right); -- Mode 4
               
               State := S6;
               
               when S6 =>
               -- Norm calculation
               FD_residual <= resize(Sum + P, n_left, n_right);
                               
                -- Sigh calculation                           
               sigh1_out(1) <= zer0h;
               sigh1_out(2) <= zer0h;  
               
               sigh2_out(0) <= zer0h;
               sigh2_out(2) <= zer0h;  
                              
               sigh3_out(0) <= zer0h;
               sigh3_out(1) <= zer0h;  
                                                
               if Mode = 1 then
               sigh1_out(0) <= resize(sigh1_noh(0) * h, d_left, d_right);
               sigh2_out(1) <= resize(sigh2_noh(0) * h, d_left, d_right);
               sigh3_out(2) <= resize(sigh3_noh(0) * h, d_left, d_right);
               
               elsif Mode = 2 then
               sigh1_out(0) <= resize(sigh1_noh(1) * h, d_left, d_right);
               sigh2_out(1) <= resize(sigh2_noh(0) * h, d_left, d_right);
               sigh3_out(2) <= resize(sigh3_noh(1) * h, d_left, d_right);
                                         
               elsif Mode = 3 then
               sigh1_out(0) <= resize(sigh1_noh(1) * h, d_left, d_right);
               sigh2_out(1)<=  resize(sigh2_noh(1) * h, d_left, d_right);
               sigh3_out(2) <= resize(sigh3_noh(2) * h, d_left, d_right);
                  
               elsif Mode = 4 then
               sigh1_out(0) <= resize(sigh2_noh(2) * h, d_left, d_right);
               sigh2_out(1) <= resize(sigh2_noh(2) * h, d_left, d_right);
               sigh3_out(2) <= resize(sigh3_noh(3) * h, d_left, d_right);
               
               else null;
               end if;
               State := S7;
               
               when S7 =>
                z_est(0) <= resize(Ltheta_star * sigh1_out(0), n_left, n_right);
                z_est(1) <= resize(Ltheta_star * sigh2_out(1), n_left, n_right);
                z_est(2) <= resize(Ctheta_star * sigh3_out(2), n_left, n_right);
               State :=  S8;
                
                when S8 =>
                z_est(0) <= resize(z_est(0) + State_inp_Matrix(0), n_left, n_right);
                z_est(1) <= resize(z_est(1) + State_inp_Matrix(1), n_left, n_right);
                z_est(2) <= resize(z_est(2) + State_inp_Matrix(2), n_left, n_right);
                State := S9;
                
                -- L*E calculation
                when S9 =>

                    A <= A_Aug_Matrix(0,0);  
                    B <= err_Matrix(0);
                    State := S10;

                when S10 =>
                    A <= A_Aug_Matrix(0,1);  
                    B <= err_Matrix(1);
                    P <= resize(A * B, P'high, P'low);
                    State := S11;

                when S11 =>

                    A <= A_Aug_Matrix(1,0);  
                    B <= err_Matrix(0);
                    P <= resize(A * B, P'high, P'low);
                    Sum <= P;
                    State := S12;

                when S12 =>
                    A <= A_Aug_Matrix(1,1);  
                    B <= err_Matrix(1);
                    P <= resize(A * B, P'high, P'low);
                    Sum <= resize(Sum + P, Sum'high, Sum'low);
                    State := S13;
                   
                when S13 =>
                     A <= A_Aug_Matrix(2,0);  
                     B <= err_Matrix(0);
                     P <= resize(A * B, P'high, P'low);
                     Sum <= P;
                    
                     C_Matrix(0) := Sum; 
                     State := S14;  
                                    
                when S14 =>
                    A <= A_Aug_Matrix(2,1);  
                    B <= err_Matrix(1);
                    P <= resize(A * B, P'high, P'low);
                    Sum <= resize(Sum + P, Sum'high, Sum'low);
                    State := S15;        

               when S15 =>
                    P <= resize(A * B, P'high, P'low);          
                    Sum <= P;
               
                    C_Matrix(1) := Sum; 
                    State := S16;

               when S16 =>
                    Sum <= resize(Sum + P, Sum'high, Sum'low);
                    State := S17;
        

               when S17 =>
                    C_Matrix(2) := Sum;                 
                    State := S18;

               when S18 =>
                    le(0) <= C_Matrix(0);
                    le(1) <= C_Matrix(1);
                    le(2) <= C_Matrix(2);
                    State := S19;
                    
               when S19 =>
                z_est(0) <= resize(z_est(0) + le(0), n_left, n_right);
                z_est(1) <= resize(z_est(1) + le(1), n_left, n_right);
                z_est(2) <= resize(z_est(2) + le(2), n_left, n_right);
                State := S20;
                
               when S20 =>
                State_inp_Matrix(0) := z_est(0);
                State_inp_Matrix(1) := z_est(1);
                State_inp_Matrix(2) := z_est(2);
                
                y_est(0) <= resize(z_est(0) + z_est(1), n_left, n_right);
                y_est(1) <= z_est(2);
                
                done <= '1';
                State := S0;
                
                end case;
        end if; -- clk
    end process;            
end Behavioral;
