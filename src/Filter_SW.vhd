-- With C = 2.85e-3 and L = 5 mH
-- FI filter for L

library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.input_pkg.all;

entity Filter_SW is
 port (      Clk : in STD_LOGIC;
             Start : in STD_LOGIC;
             Mode : in INTEGER range 0 to 2;
             load : in sfixed(n_left downto n_right);
             plt_x : in vect2;
             done : out STD_LOGIC := '0';
             SW_norm : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
             SW_residual : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
             SW_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
          );
end Filter_SW;

architecture Behavioral of Filter_SW is

    signal	Count0	: UNSIGNED (3 downto 0):="0000";
	signal	A       : sfixed(d_left downto d_right);
	signal	An      : sfixed(n_left downto n_right);
	signal	B       : sfixed(n_left downto n_right);
	signal	P       : sfixed(n_left downto n_right);
	signal	Sum	    : sfixed(n_left downto n_right);
    signal 	j0, k0, k1, k2 : INTEGER := 0;
   
    -- For theta calculation
    signal  theta_SWLh : sfixed(d_left downto d_right):= to_sfixed(0.0001, d_left, d_right);
    signal  theta_SWCh : sfixed(d_left downto d_right):= to_sfixed(0.0001754386, d_left, d_right);
    signal  wforthetaSW : vect2:= (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
    
    -- For Norm calculation
    signal  err_val  : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
    signal  SW_norm_out : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    signal  SW_residual_funct_out : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    signal  SW_residual_out :  sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);

begin

mult: process(Clk, load)
  
   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17);
   variable     State         : STATE_VALUE := S0;

   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat26;
   variable State_inp_Matrix     : vect6:= (il0, vc0, v_in, load, plt_x(0), plt_x(1));
   variable C_Matrix             : vect2;
   
   -- For theta Calculation
   variable ePhSW : vect2;
 
   begin
           
   if (Clk'event and Clk = '1') then
    
    SW_norm <= SW_norm_out;
    SW_residual <= SW_residual_out;
    
    State_inp_Matrix(2) := v_in;
    State_inp_Matrix(3) := load;
    State_inp_Matrix(4) := plt_x(0);
    State_inp_Matrix(5) := plt_x(1);
    
    
   case Mode is
           
           when 0 =>
           ----------------------------------------
           -- Mode 0 - A:B matrix diode is conducting s1 = 1
           ----------------------------------------
           A_Aug_Matrix := ( 
                          (to_sfixed(0.999999789050000, A'high, A'low),
                           resize(theta_SWLh - to_sfixed(0.000000014550000,d_left,d_right), A'high, A'low), 
                           to_sfixed(0.000100000000000, A'high, A'low), 
                           to_sfixed( 0,A'high,A'low),
                           to_sfixed(-0.000007989050000,A'high,A'low),
                           to_sfixed( 0.000000014550000,A'high,A'low)),
                          (resize(theta_SWCh - to_sfixed(-0.000000025150000,d_left,d_right), A'high, A'low),
                           to_sfixed( 0.999999629900000,A'high,A'low),
                           to_sfixed(0,A'high,A'low),
                           to_sfixed(-0.000175438600000,A'high,A'low),
                           to_sfixed(-0.000000025150000,A'high,A'low),
                           to_sfixed( 0.000000370100000,A'high,A'low))
                          );

                           
              when 1 =>
              ----------------------------------------
              -- Mode 1 - A:B matrix Switch is conducting current building up
              ----------------------------------------
             A_Aug_Matrix := ( 
                            (to_sfixed(0.999999789050000, A'high, A'low),
                             resize(theta_SWLh - to_sfixed(0.000000014550000,d_left,d_right), A'high, A'low), 
                             to_sfixed(0.000100000000000, A'high, A'low), 
                             to_sfixed( 0,A'high,A'low),
                             to_sfixed(-0.000007989050000,A'high,A'low),
                             to_sfixed( 0.000000014550000,A'high,A'low)),
                            (resize(theta_SWCh - to_sfixed(-0.000000025150000,d_left,d_right), A'high, A'low),
                             to_sfixed( 0.999999629900000,A'high,A'low),
                             to_sfixed(0,A'high,A'low),
                             to_sfixed(-0.000175438600000,A'high,A'low),
                             to_sfixed(-0.000000025150000,A'high,A'low),
                             to_sfixed( 0.000000370100000,A'high,A'low))
                            );
                     
               when others =>
          A_Aug_Matrix := ( 
                         (to_sfixed(0.999999789050000, A'high, A'low),
                          resize(theta_SWLh - to_sfixed(0.000000014550000,d_left,d_right), A'high, A'low), 
                          to_sfixed(0.000100000000000, A'high, A'low), 
                          to_sfixed( 0,A'high,A'low),
                          to_sfixed(-0.000007989050000,A'high,A'low),
                          to_sfixed( 0.000000014550000,A'high,A'low)),
                         (resize(theta_SWCh - to_sfixed(-0.000000025150000,d_left,d_right), A'high, A'low),
                          to_sfixed( 0.999999629900000,A'high,A'low),
                          to_sfixed(0,A'high,A'low),
                          to_sfixed(-0.000175438600000,A'high,A'low),
                          to_sfixed(-0.000000025150000,A'high,A'low),
                          to_sfixed( 0.000000370100000,A'high,A'low))
                         );
             end case;
                 
              
      case State is
                          ------------------------------------------
                          --    State S0 (wait for start signal)
                          ------------------------------------------
                          when S0 =>
                              j0 <= 0; k0 <= 0; k1 <= 0; k2 <= 0;
                              done <= '0';
                              Count0 <= "0000";
                              if( start = '1' ) then
                                  State := S1;
                              else
                                  State := S0;
                              end if;
                    

ePhSW(0) := resize(to_sfixed(174.4447, n_left, n_right) * C_Matrix(1), n_left, n_right);
ePhSW(1) := resize(to_sfixed(99.4338, n_left, n_right) *  C_Matrix(0), n_left, n_right);

                    
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
                           done <= '1';
                           State_inp_Matrix(0) := C_Matrix(0);
                           State_inp_Matrix(1) := C_Matrix(1);
                           SW_zval <=  C_Matrix;
                           State := S9;
                           
                          when S9 =>
                          -- Error calcultion
                           err_val(0) <= resize(plt_x(0) - C_Matrix(0), n_left, n_right);
                           err_val(1) <= resize(plt_x(1) - C_Matrix(1), n_left, n_right);
                           State := S10;
                           
                          when S10 =>
                          -- For w calculation which decides on theta
                           An <= ePhSW(0);  
                           B <= err_val(0);
                           State := S11;
                           
                           when S11 =>
                           An <= ePhSW(1);  
                           B <= err_val(1);
                           wforthetaSW(0) <= resize(An * B, P'high, P'low);
                           State := S12;
                          
                           when S12 =>
                           wforthetaSW(1) <= resize(An * B, P'high, P'low);
                           -- Norm calculation
                           An <= err_val(0);
                           B <= err_val(0);
                           State := S13; 
                           
                           when S13 =>
                            -- Theta SWL calculation
                          if wforthetaSW(0) > to_sfixed(0, n_left, n_right) or wforthetaSW(0) = to_sfixed(0, n_left, n_right) then
                                if Mode = 0 then
                                 theta_SWLh <= to_sfixed(0,d_left,d_right);
                                else
                                 theta_SWLh <= L_theta;
                                 end if;
                          else
                                if Mode = 0 then
                                theta_SWLh <= resize(to_sfixed(-2, n_left, n_right)*L_theta,d_left,d_right);
                                else
                                theta_SWLh <= resize(to_sfixed(-1, n_left, n_right)*L_theta,d_left,d_right);
                                end if;
                         end if;
                           -- Norm calculation
                           An <= err_val(1);
                           B <= err_val(1);
                           P <= resize(An * B, P'high, P'low);
                           State := S14;                             
                           
                           when S14 =>
                           -- Theta SWC calculation
                            if wforthetaSW(1) > to_sfixed(0, n_left, n_right) or wforthetaSW(1) = to_sfixed(0, n_left, n_right) then
                                if Mode = 0 then
                                 theta_SWCh <= resize(to_sfixed(2, n_left, n_right)*C_theta,d_left,d_right);
                                else 
                                 theta_SWCh <= C_theta;
                                end if;
                            else
                               if Mode = 0 then
                                theta_SWCh <= to_sfixed(0, d_left, d_right);
                               else
                                theta_SWCh <= resize(to_sfixed(-1, n_left, n_right)*C_theta,d_left,d_right);
                               end if;
                            end if;
                            -- Norm calculation
                            Sum <= P;
                            P <= resize(An * B, P'high, P'low);
                            State := S15;
                           
                           when S15 =>
                           -- Norm calculation
                           SW_norm_out <= resize(Sum + P, Sum'high, Sum'low);
                           State := S16;                                                 
                          
                          
                           when S16 =>
                           An <= resize(to_sfixed(0.999995,d_left,d_right) * SW_residual_funct_out, n_left, n_right);
                           B <= resize(h * SW_norm_out, n_left, n_right);
                           SW_residual_out  <= resize(SW_norm_out + SW_residual_funct_out, n_left, n_right); 
                           State := S17;
                         
                           when S17 =>
                           SW_residual_out <= resize(to_sfixed(10, n_left, n_right) * SW_residual_out, n_left, n_right);
                           SW_residual_funct_out <= resize(An + B, n_left, n_right);                           
                           State := S0;
                         
                          end case;
                      end if;
                 end process;
end Behavioral;
