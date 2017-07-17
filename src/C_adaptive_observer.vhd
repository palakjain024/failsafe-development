-- Adaptive Observer for C
library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.input_pkg.all;

entity C_adaptive_observer is
port (    Clk   : in STD_LOGIC;
          clk_ila : in STD_LOGIC;
          Start : in STD_LOGIC;
          Mode  : in INTEGER range 1 to 4;
          load  : in sfixed(n_left downto n_right);
          y_plant : in vect2;
          FD_flag : in STD_LOGIC;
          done  : out STD_LOGIC := '0';
          y_est_out     : out vect2 := (zer0, zer0);
          norm_out  : out sfixed(n_left downto n_right) := zer0);
end C_adaptive_observer;

architecture Behavioral of C_adaptive_observer is

---- Component def ----
 -- ILA core
    COMPONENT ila_0

    PORT (
        clk : IN STD_LOGIC;
    
    
        trig_in : IN STD_LOGIC;
        trig_in_ack : OUT STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe6 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe7 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT  ;

  -- theta estimation
   Component thetta is
    port (   Clk   : in STD_LOGIC;
             Start : in STD_LOGIC;
             Mode  : in INTEGER range 1 to 4;
             err   : in vect2;
             sigh  : in vecth3;
             done  : out STD_LOGIC := '0';
             lambda_out : out vect3 := (zer0, zer0, zer0);
             thetadot_out : out sfixed(n_left downto n_right):= zer0;
             lambda_thetadot_out : out vect3 := (zer0, zer0, zer0)
         );
    end component thetta;
    
---- Signals ----
  -- ila core signals
      signal trig_in_ack, trig_in : STD_LOGIC := '0';
      signal probe_err1, probe_err2, probe_norm, probe_theta1, probe_theta2 : STD_LOGIC_VECTOR(31 downto 0);
      signal probe_thetadot1, probe_y1p, probe_y2p : STD_LOGIC_VECTOR(31 downto 0);
  
 -- Matrix and sigh cal L*h*e
   signal	A       : sfixed(d_left downto d_right);
   
  
   signal	P_sigh1       : sfixed(n_left downto n_right);
   signal	P_sigh2       : sfixed(n_left downto n_right);
   signal   P_load        : sfixed(n_left downto n_right);
   signal	B       : sfixed(n_left downto n_right);
   signal	C       : sfixed(n_left downto n_right);
   signal	D       : sfixed(n_left downto n_right);
   
   signal	P       : sfixed(n_left downto n_right);
   signal	Sum	    : sfixed(n_left downto n_right); 
   
 -- Error correction
   signal le : vect3 := (zer0, zer0, zer0);
   signal err : vect2 := (zer0, zer0);
          
 -- z estimate
   signal z_est : vect3 := (il0, il0, vc0);
   signal y_est: vect2 := (yil0 ,vc0);
   signal norm: sfixed(n_left downto n_right) := zer0;   
   
 -- Theta cal
   signal theta_est : vect2 := (Ltheta_star, Ltheta_star);
   signal theta_dot : vect2 := (zer0, zer0);
   signal start_theta : STD_LOGIC := '0';
   signal done_theta1, done_theta2 : STD_LOGIC;
   
 -- Lambda theta cal
   signal lambda_theta_est1, lambda_theta_est2 : vect3 := (zer0, zer0, zer0);
   signal lambda1, lambda2 : vect3 := (zer0, zer0, zer0);
   
 -- Sigh cal
   signal sigh1_out, sigh2_out, sigh3_out : vecth3;
   signal sigh1_noh, sigh2_noh : vect3;
   signal sigh3_noh: vect4;

begin

---- Instances ----
-- Debug core
                          
ila_inst_1: ila_0
PORT MAP (
    clk => clk_ila,
    
    trig_in => trig_in,
    trig_in_ack => trig_in_ack,
    probe0 => probe_err1, 
    probe1 => probe_err2, 
    probe2 => probe_theta1,  
    probe3 => probe_theta2, 
    probe4 => probe_thetadot1,
    probe5 => probe_norm,
    probe6 => probe_y1p,
    probe7 => probe_y2p
    
); 

-- Theta
thetta1_inst: thetta port map (
    clk => clk,
    Start => Start_theta,
    Mode => Mode,
    err => err,
    sigh => sigh1_out,
    done => done_theta1,
    lambda_out => lambda1,
    thetadot_out => theta_dot(0),
    lambda_thetadot_out => lambda_theta_est1);

thetta2_inst: thetta port map (
        clk => clk,
        Start => Start_theta,
        Mode => Mode,
        err => err,
        sigh => sigh2_out,
        done => done_theta2,
        lambda_out => lambda2,
        thetadot_out => theta_dot(1),
        lambda_thetadot_out => lambda_theta_est2);   

---- Proceses ----   
mult: process(Clk, load, y_plant, err)

   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17,
   S18, S19, S20, S21, S22);
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
   
   -- ILA
      probe_err1 <= result_type(err(0));
      probe_err2 <= result_type(err(1)); 
      probe_norm  <= result_type(norm);
      probe_y1p <= result_type(y_plant(0)) ; 
      probe_y2p <= result_type(y_plant(1));
      probe_theta1 <= result_type(theta_est(0));
      probe_theta2 <= result_type(theta_est(1));
      probe_thetadot1 <= result_type(theta_dot(0));
      
    -- Output 
    y_est_out <= y_est;
    norm_out <= norm;
   
   -- L matrix: Gain Matrix
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
                 if FD_flag = '1' then  
                 
                   
                   if( start = '1' ) then   
                   trig_in <= '1'; 
                   err(0) <= resize(y_plant(0) - y_est(0), n_left, n_right);
                   err(1) <= resize(y_plant(1) - y_est(1), n_left, n_right);               
                       State := S1;
                   else
                       State := S0;
                   end if;
                   
                 else  
                 norm <= zer0;
                 y_est <= (yil0 ,vc0);
                                
                 end if;    
        -- Sigh Calculation
               when S1 =>
                -- Error intialization
                err_Matrix(0) := err(0);
                err_Matrix(1) := err(1);
                
                -- theta calculation
                theta_est(0) <= resize(theta_est(0) + theta_dot(0), n_left, n_right);
                theta_est(1) <= resize(theta_est(1) + theta_dot(1), n_left, n_right);
                
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
                norm <= resize(Sum + P, n_left, n_right);             
               
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
                Start_theta <= '1';
                z_est(0) <= resize(theta_est(0) * sigh1_out(0), n_left, n_right);
                z_est(1) <= resize(theta_est(1) * sigh2_out(1), n_left, n_right);
                z_est(2) <= resize(Ctheta_star  * sigh3_out(2), n_left, n_right);
               State :=  S8;
                
                when S8 =>
                z_est(0) <= resize(z_est(0) + State_inp_Matrix(0), n_left, n_right);
                z_est(1) <= resize(z_est(1) + State_inp_Matrix(1), n_left, n_right);
                z_est(2) <= resize(z_est(2) + State_inp_Matrix(2), n_left, n_right);
                State := S9;
                
                when S9 =>
                z_est(0) <= resize(z_est(0) + lambda_theta_est1(0), n_left, n_right);
                z_est(1) <= resize(z_est(1) + lambda_theta_est1(1), n_left, n_right);
                z_est(2) <= resize(z_est(2) + lambda_theta_est1(2), n_left, n_right);
                State := S10;
                
                when S10 =>
                z_est(0) <= resize(z_est(0) + lambda_theta_est2(0), n_left, n_right);
                z_est(1) <= resize(z_est(1) + lambda_theta_est2(1), n_left, n_right);
                z_est(2) <= resize(z_est(2) + lambda_theta_est2(2), n_left, n_right);
                
                Start_theta <= '0';
                
                State := S11;
           -- L*e calculation
               when S11 =>
                    A <= A_Aug_Matrix(0,0);  
                    B <= err_Matrix(0);
                    State := S12;

               when S12 =>
                    A <= A_Aug_Matrix(0,1);  
                    B <= err_Matrix(1);
                    P <= resize(A * B, P'high, P'low);
                    State := S13;

               when S13 =>
                    A <= A_Aug_Matrix(1,0);  
                    B <= err_Matrix(0);
                    P <= resize(A * B, P'high, P'low);
                    Sum <= P;
                    State := S14;

               when S14 =>
                    A <= A_Aug_Matrix(1,1);  
                    B <= err_Matrix(1);
                    P <= resize(A * B, P'high, P'low);
                    Sum <= resize(Sum + P, Sum'high, Sum'low);
                    State := S15;
                   
               when S15 =>
                     A <= A_Aug_Matrix(2,0);  
                     B <= err_Matrix(0);
                     P <= resize(A * B, P'high, P'low);
                     Sum <= P;
                    
                     C_Matrix(0) := Sum; 
                     State := S16;  
                                    
               when S16 =>
                    A <= A_Aug_Matrix(2,1);  
                    B <= err_Matrix(1);
                    P <= resize(A * B, P'high, P'low);
                    Sum <= resize(Sum + P, Sum'high, Sum'low);
                    State := S17;        

               when S17 =>
                    P <= resize(A * B, P'high, P'low);          
                    Sum <= P;
               
                    C_Matrix(1) := Sum; 
                    State := S18;

               when S18 =>
                    Sum <= resize(Sum + P, Sum'high, Sum'low);
                    State := S19;
        

               when S19 =>
                    C_Matrix(2) := Sum;                 
                    State := S20;

               when S20 =>
                    le(0) <= C_Matrix(0);
                    le(1) <= C_Matrix(1);
                    le(2) <= C_Matrix(2);
                    State := S21;
                    
               when S21 =>
                z_est(0) <= resize(z_est(0) + le(0), n_left, n_right);
                z_est(1) <= resize(z_est(1) + le(1), n_left, n_right);
                z_est(2) <= resize(z_est(2) + le(2), n_left, n_right);
                State := S22;
                
               when S22 =>
                State_inp_Matrix(0) := z_est(0);
                State_inp_Matrix(1) := z_est(1);
                State_inp_Matrix(2) := z_est(2);
                
                y_est(0) <= resize(z_est(0) + z_est(1), n_left, n_right);
                y_est(1) <= resize(z_est(2) - (esr*load), n_left, n_right);
                done <= '1';
                State := S0;
            end case;
        end if;
    end process;
           
end Behavioral;
