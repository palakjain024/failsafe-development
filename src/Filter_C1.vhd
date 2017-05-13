-- With C = 2.85e-3 and L = 5 mH
-- FI filter for C
library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.input_pkg.all;

entity Filter_C is
 port (      Clk : in STD_LOGIC;
             Start : in STD_LOGIC;
             flag : in STD_LOGIC;
             Mode : in INTEGER range 0 to 2;
             load : in sfixed(n_left downto n_right);
             plt_x : in vect2;
             done : out STD_LOGIC := '0';
             C_norm : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
             C_residual : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
             C_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
          );
end Filter_C;

architecture Behavioral of Filter_C is

    signal	Count0	: UNSIGNED (3 downto 0):="0000";
	signal	A_C       : sfixed(d_left downto d_right);
	signal	An_C      : sfixed(n_left downto n_right);
	signal	B_C       : sfixed(n_left downto n_right);
	signal	P_C       : sfixed(n_left downto n_right);
	signal	Sum_C	    : sfixed(n_left downto n_right);
    signal 	j0, k0, k1, k2 : INTEGER := 0;
   
    -- For theta calculation
   signal  wforthetaC : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
   signal ePhC : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
    
    -- For Norm calculation
    signal  C_err_val  : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
    signal  C_norm_out : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    signal  C_residual_funct_out : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    signal  C_residual_out :  sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);

begin

mult: process(Clk, load, plt_x, flag)
  
   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17);
   variable     State         : STATE_VALUE := S0;

   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat26;
   variable State_inp_Matrix     : vect6:= (il0, vc0, v_in, load, plt_x(0), plt_x(1));
   variable C_Matrix             : vect2;
  
 
   begin
           
   if (Clk'event and Clk = '1') then

    
    State_inp_Matrix(2) := v_in;
    State_inp_Matrix(3) := load;
    State_inp_Matrix(4) := plt_x(0);
    State_inp_Matrix(5) := plt_x(1);
    
      case State is
                          ------------------------------------------
                          --    State S0 (wait for start signal)
                          ------------------------------------------
                          when S0 =>
                              j0 <= 0; k0 <= 0; k1 <= 0; k2 <= 0;
                              done <= '0';
                              Count0 <= "0000";
                      -- Fault detection
                      if flag = '1' then
                            
                            -- Start the FI filter
                              if( start = '1') then
                                  State := S1;
                            -- Matrix calculation
                             if Mode = 0 then
                             
                              -- Theta calculation
                                if wforthetaC > to_sfixed(0, n_left, n_right) or wforthetaC = to_sfixed(0, n_left, n_right) then
                                A_Aug_Matrix(1,0) := to_sfixed(0.000793450000000,d_left,d_right);
                                A_Aug_Matrix(1,3) := to_sfixed( -0.000877200000000,d_left,d_right);
                                else
                                A_Aug_Matrix(1,0) := to_sfixed(0.000062250000000,d_left,d_right);
                                A_Aug_Matrix(1,3) := to_sfixed(-0.000146000000000,d_left,d_right);
                                end if;
                                          ----------------------------------------
                                          -- Mode 0 - A_C:B_C matrix diode is conducting s1 = 1
                                          ----------------------------------------
                                          A_Aug_Matrix(0,0) := to_sfixed( 0.999712350000000, d_left, d_right);
                                          A_Aug_Matrix(0,1) := to_sfixed(-0.000595300000000, d_left, d_right);
                                          A_Aug_Matrix(0,2) := to_sfixed( 0.000100000000000, d_left, d_right);
                                          A_Aug_Matrix(0,3) := to_sfixed( 0, d_left, d_right);
                                          A_Aug_Matrix(0,4) := to_sfixed( 0.000279450000000, d_left, d_right);
                                          A_Aug_Matrix(0,5) := to_sfixed( 0.000495300000000, d_left, d_right);
                                          --A_Aug_Matrix(1,0) := to_sfixed(-0.000083750000000, d_left, d_right);
                                          A_Aug_Matrix(1,1) := to_sfixed( 0.997663050000000, d_left, d_right);
                                          A_Aug_Matrix(1,2) := to_sfixed( 0, d_left, d_right);
                                          --A_Aug_Matrix(1,3) := resize(to_sfixed(-1,n_left,n_right)*theta_Ch, d_left, d_right);
                                          A_Aug_Matrix(1,4) := to_sfixed( 0.000083750000000, d_left, d_right);
                                          A_Aug_Matrix(1,5) := to_sfixed( 0.002336950000000, d_left, d_right);
                                                       
                               
                                                          
                              elsif Mode = 1 then
                              
                               -- Theta calculation
                               if wforthetaC > to_sfixed(0, n_left, n_right) or wforthetaC = to_sfixed(0, n_left, n_right) then
                               A_Aug_Matrix(1,3) := to_sfixed(-0.000877200000000,d_left, d_right);
                               else
                               A_Aug_Matrix(1,3) := to_sfixed(-0.000146000000000,d_left, d_right);
                               end if;
                                             ----------------------------------------
                                             -- Mode 1 - A:B matrix Switch is conducting current building up
                                             ----------------------------------------
                                            A_Aug_Matrix(0,0) := to_sfixed( 0.999712350000000, d_left, d_right);
                                            A_Aug_Matrix(0,1) := to_sfixed(-0.000495300000000, d_left, d_right);
                                            A_Aug_Matrix(0,2) := to_sfixed( 0.000100000000000, d_left, d_right);
                                            A_Aug_Matrix(0,3) := to_sfixed( 0, d_left, d_right);
                                            A_Aug_Matrix(0,4) := to_sfixed( 0.000279450000000, d_left, d_right);
                                            A_Aug_Matrix(0,5) := to_sfixed( 0.000495300000000, d_left, d_right);
                                            A_Aug_Matrix(1,0) := to_sfixed(-0.000083750000000, d_left, d_right);
                                            A_Aug_Matrix(1,1) := to_sfixed( 0.997663050000000, d_left, d_right);
                                            A_Aug_Matrix(1,2) := to_sfixed(0, d_left, d_right);
                                            --A_Aug_Matrix(1,3) := resize(to_sfixed(-1,n_left,n_right)*theta_Ch, d_left, d_right);
                                            A_Aug_Matrix(1,4) := to_sfixed( 0.000083750000000, d_left, d_right);
                                            A_Aug_Matrix(1,5) := to_sfixed( 0.002336950000000, d_left, d_right);
                                                            
                                                    
                                else
                                          
                                          A_Aug_Matrix(0,0) := to_sfixed( 0.999712350000000, d_left, d_right);
                                          A_Aug_Matrix(0,1) := to_sfixed(-0.000595300000000, d_left, d_right);
                                          A_Aug_Matrix(0,2) := to_sfixed( 0.000100000000000, d_left, d_right);
                                          A_Aug_Matrix(0,3) := to_sfixed( 0, d_left, d_right);
                                          A_Aug_Matrix(0,4) := to_sfixed( 0.000279450000000, d_left, d_right);
                                          A_Aug_Matrix(0,5) := to_sfixed( 0.000495300000000, d_left, d_right);
                                          A_Aug_Matrix(1,0) := resize(C_theta + to_sfixed(-0.000083750000000,d_left,d_right), d_left, d_right);
                                          A_Aug_Matrix(1,1) := to_sfixed( 0.997663050000000, d_left, d_right);
                                          A_Aug_Matrix(1,2) := to_sfixed( 0, d_left, d_right);
                                          A_Aug_Matrix(1,3) := resize(to_sfixed(-1,n_left,n_right)*C_theta, d_left, d_right);
                                          A_Aug_Matrix(1,4) := to_sfixed( 0.000083750000000, d_left, d_right);
                                          A_Aug_Matrix(1,5) := to_sfixed( 0.002336950000000, d_left, d_right);
                                 end if;
                              else
                                  State := S0;
                              end if;
                              
                           
                      else
                      C_norm <= to_sfixed(0, n_left, n_right);
                      C_residual <= to_sfixed(0, n_left, n_right);
                      State := S0;
                      end if;
            

                    
                          -------------------------------------------
                          --    State S1 (filling up of pipeline)
                          -------------------------------------------
                          when S1 =>
                              A_C <= A_Aug_Matrix(j0, k0);  
                              B_C <= State_inp_Matrix(k0);
                              k0 <= k0 +1;
                              Count0 <= Count0 + 1;
                              State := S2;
                   
                          ---------------------------------------
                          --    State S2 (more of filling up)
                          ---------------------------------------
                          when S2 =>
                              A_C <= A_Aug_Matrix(j0, k0);  
                              B_C <= State_inp_Matrix(k0);
                   
                              P_C <= resize(A_C * B_C, P_C'high, P_C'low);
                              k0 <= k0 +1;
                              Count0 <= Count0 + 1;
                              State := S3;
                   
                          -------------------------------------------
                          --    State S3 (even more of filling up)
                          -------------------------------------------
                          when S3 =>
                              A_C <= A_Aug_Matrix(j0, k0);  
                              B_C <= State_inp_Matrix(k0);
                   
                              P_C <= resize(A_C * B_C, P_C'high, P_C'low);
                              Sum_C <= resize(P_C, Sum_C'high, Sum_C'low);
                              
                              k1 <= k1+1;
                              k0 <= k0+1;
                              Count0 <= Count0 + 1;
                              State := S4;
                   
                          -------------------------------------------------
                          --    State S4 (pipeline full, complete work)
                          -------------------------------------------------
                          when S4 =>
                              A_C <= A_Aug_Matrix(j0, k0);  
                              B_C <= State_inp_Matrix(k0);
                   
                              P_C <= resize(A_C * B_C, P_C'high, P_C'low);
                   
                              if (k1 = 0) then
                                  Sum_C <= resize(P_C, Sum_C'high, Sum_C'low);
                                  C_Matrix(k2) := resize(Sum_C, n_left, n_right);
                                  k2 <= k2 +1;
                              else
                                  Sum_C <= resize(Sum_C + P_C, Sum_C'high, Sum_C'low);
                              end if;
                   
                              if (k1 = 5) then
                                  k1 <= 0;
                                  else
                                  k1 <= k1 + 1;
                              end if;
                              
                           
                              ----------------------------------
                              -- check if all initiations done
                              ----------------------------------
                              if (Count0 = 11) then
                                  State := S5;
                              else
                                  State := S4;                
                                  Count0 <= Count0 + 1;
                                 if (k0 = 5) then
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
                                  P_C <= resize(A_C * B_C, P_C'high, P_C'low);          
                                  Sum_C <= resize(Sum_C + P_C, Sum_C'high, Sum_C'low);
                                  State := S6;
                   
                          -------------------------------------
                          --    State S6 (more of flushing)
                          -------------------------------------
                          when S6 =>
                                     
                                      Sum_C <= resize(Sum_C + P_C, Sum_C'high, Sum_C'low);
                                      State := S7;
                   
                          -------------------------------------------
                          --    State S7 (completion of flushing)
                          -------------------------------------------
                          when S7 =>
                                             
                                     C_Matrix(k2) := Sum_C;                 
                                     State := S8;
                                     Count0 <= "0000";
                                     k0 <= 0;
                                  
                          ------------------------------------
                          --    State S8 (output the data)
                          ------------------------------------
                          when S8 =>
                         
                           State_inp_Matrix(0) := C_Matrix(0);
                           State_inp_Matrix(1) := C_Matrix(1);
                           C_zval <=  C_Matrix;
                             -- w calculation
                           if mode = 0 then
                           ePhC(0) <= resize(C_Matrix(0) - State_inp_Matrix(3), n_left, n_right);
                           ePhC(1) <= resize(C_Matrix(0) - State_inp_Matrix(3), n_left, n_right);
                           else
                           ePhC(0) <= resize(to_sfixed(-1, n_left, n_right) * State_inp_Matrix(3), n_left, n_right);
                           ePhC(1) <= resize(to_sfixed(-1, n_left, n_right) * State_inp_Matrix(3), n_left, n_right);
                           end if;   
                           State := S9;
                           
                          when S9 =>
                           -- w calculation
                           ePhC(0) <= resize(to_sfixed(-1.5322, n_left, n_right) * ePhC(0), n_left, n_right);
                           ePhC(1) <= resize(to_sfixed( 1.8170, n_left, n_right) * ePhC(1), n_left, n_right);
                                                                                     
                          -- Error calcultion
                           C_err_val(0) <= resize(plt_x(0) - C_Matrix(0), n_left, n_right);
                           C_err_val(1) <= resize(plt_x(1) - C_Matrix(1), n_left, n_right);
                           State := S10;
                           
                          when S10 =>
                          -- For w calculation which decides on theta
                           An_C <= ePhC(0);  
                           B_C <= C_err_val(0);
                           State := S11;
                           
                           when S11 =>
                           An_C <= ePhC(1);  
                           B_C <= C_err_val(1);
                           P_C <= resize(An_C * B_C, P_C'high, P_C'low);
                           State := S12;
                          
                           when S12 =>
                           Sum_C <= P_C;
                           P_C <= resize(An_C * B_C, P_C'high, P_C'low);
                           -- Norm calculation
                           An_C <= C_err_val(0);
                           B_C <= C_err_val(0);
                           State := S13; 
                           
                           when S13 =>
                           wforthetaC <= resize(Sum_C + P_C, n_left, n_right);
                           -- Norm calculation
                           An_C <= C_err_val(1);
                           B_C <= C_err_val(1);
                           P_C <= resize(An_C * B_C, P_C'high, P_C'low);
                           State := S14;                             
                           
                           when S14 =>
                            -- Norm calculation
                            Sum_C <= P_C;
                            P_C <= resize(An_C * B_C, P_C'high, P_C'low);
                            State := S15;
                           
                           when S15 =>
                           -- Norm calculation
                           C_norm_out <= resize(Sum_C + P_C, n_left, n_right);
                           C_norm <= resize(Sum_C + P_C, n_left, n_right);
                           State := S16;                                                 
                          
                          
                           when S16 =>
                           An_C <= resize(epsilon * C_residual_funct_out, n_left, n_right);
                           A_C <= resize(h * C_norm_out, d_left, d_right);
                           C_residual_out  <= resize(C_norm_out + C_residual_funct_out, n_left, n_right); 
                           State := S17;
                         
                           when S17 =>
                           C_residual_out <= resize(to_sfixed(10, n_left, n_right) * C_residual_out, n_left, n_right);
                           C_residual <= resize(to_sfixed(10, n_left, n_right) * C_residual_out, n_left, n_right);
                           done <= '1';  
                           C_residual_funct_out <= resize(An_C + A_C, n_left, n_right);
                           State := S0;
                         
                    end case;
                end if;
     end process;
     
end Behavioral;
