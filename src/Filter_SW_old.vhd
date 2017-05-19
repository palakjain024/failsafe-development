-- With C = 2.85e-3 and L = 5 mH
-- FI filter for SW

library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.input_pkg.all;

entity Filter_SW is
 port (      Clk : in STD_LOGIC;
             Start : in STD_LOGIC;
             flag : in STD_LOGIC;
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
	signal	A_SW       : sfixed(d_left downto d_right);
	signal	An_SW      : sfixed(n_left downto n_right);
	signal	B_SW       : sfixed(n_left downto n_right);
	signal	P_SW       : sfixed(n_left downto n_right);
	signal	Sum_SW	   : sfixed(n_left downto n_right);
    signal 	j0, k0, k1, k2 : INTEGER := 0;
   
    -- For theta calculation
    signal  wforthetaSW : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    signal ePhSW : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
        
    -- For Norm calculation
    signal  SW_err_val  : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
    signal  SW_norm_out : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    signal  SW_residual_funct_out : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    signal  SW_residual_out :  sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);

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
                                  
                    
                   -- Matrix Calculation
                   if Mode = 0 then
                        -- Theta SWL and Theta SWC calculation
                         if wforthetaSW > to_sfixed(0, n_left, n_right) or wforthetaSW = to_sfixed(0, n_left, n_right) then
                         A_Aug_Matrix(0,1) :=  to_sfixed( -0.000209626800000,d_left,d_right);
                         A_Aug_Matrix(1,0) :=  to_sfixed(0.000158838700000,d_left,d_right);
                         else
                         A_Aug_Matrix(0,1) :=  to_sfixed( -0.000009626800000,d_left,d_right);
                         A_Aug_Matrix(1,0) :=  to_sfixed( -0.000192038500000,d_left,d_right);
                         end if;
                      
                         
                        ----------------------------------------
                        -- Mode 0 - A_SW:B_SW matrix diode is conducting s1 = 1
                        ----------------------------------------
                        A_Aug_Matrix(0,0) :=  to_sfixed( 0.999850339050000, d_left, d_right);
                        --A_Aug_Matrix(0,1) :=  resize(L_theta - to_sfixed(0.000009626800000,d_left,d_right), d_left, d_right);
                        A_Aug_Matrix(0,2) :=  to_sfixed(0.000100000000000, d_left, d_right); 
                        A_Aug_Matrix(0,3) :=  to_sfixed( 0,d_left,d_right);
                        A_Aug_Matrix(0,4) :=  to_sfixed(0.000141460950000,d_left,d_right);
                        A_Aug_Matrix(0,5) :=  to_sfixed(0.000009626800000,d_left,d_right);
                        -- A_Aug_Matrix(1,0) :=  resize(C_theta - to_sfixed(0.000192038500000,d_left,d_right), d_left, d_right);
                        A_Aug_Matrix(1,1) :=  to_sfixed( 0.999696958850000,d_left,d_right);
                        A_Aug_Matrix(1,2) :=  to_sfixed(0,d_left,d_right);
                        A_Aug_Matrix(1,3) :=  to_sfixed(-0.000175438600000,d_left,d_right);
                        A_Aug_Matrix(1,4) :=  to_sfixed(0.000192038500000,d_left,d_right);
                        A_Aug_Matrix(1,5) :=  to_sfixed(0.000303041150000,d_left,d_right);
             
                        elsif Mode = 1 then
                           -- Theta SWL and Theta SWC calculation
                          if wforthetaSW > to_sfixed(0, n_left, n_right) or wforthetaSW = to_sfixed(0, n_left, n_right) then
                          A_Aug_Matrix(0,1) :=  to_sfixed(-0.00010962680000,d_left,d_right);
                          A_Aug_Matrix(1,0) :=  to_sfixed(-0.000016599900000,d_left,d_right);
                          else
                          A_Aug_Matrix(0,1) :=  to_sfixed(0.000090373200000,d_left,d_right);
                          A_Aug_Matrix(1,0) :=  to_sfixed( -0.000367477100000,d_left,d_right);
                          end if;
                         
                
                       ----------------------------------------
                       -- Mode 1 - A_SW:B_SW matrix Switch is conducting current building up
                       ----------------------------------------
                                
                       A_Aug_Matrix(0,0) :=  to_sfixed( 0.999850339050000, d_left, d_right);
                       --A_Aug_Matrix(0,1) :=  resize(L_theta - to_sfixed(0.000009626800000,d_left,d_right), d_left, d_right);
                       A_Aug_Matrix(0,2) :=  to_sfixed(0.000100000000000, d_left, d_right); 
                       A_Aug_Matrix(0,3) :=  to_sfixed( 0,d_left,d_right);
                       A_Aug_Matrix(0,4) :=  to_sfixed(0.000141460950000,d_left,d_right);
                       A_Aug_Matrix(0,5) :=  to_sfixed(0.000009626800000,d_left,d_right);
                       --A_Aug_Matrix(1,0) :=  resize(C_theta - to_sfixed(0.000192038500000,d_left,d_right), d_left, d_right);
                       A_Aug_Matrix(1,1) :=  to_sfixed(0.999696958850000,d_left,d_right);
                       A_Aug_Matrix(1,2) :=  to_sfixed(0,d_left,d_right);
                       A_Aug_Matrix(1,3) :=  to_sfixed(-0.000175438600000,d_left,d_right);
                       A_Aug_Matrix(1,4) :=  to_sfixed(0.000192038500000,d_left,d_right);
                       A_Aug_Matrix(1,5) :=  to_sfixed(0.000303041150000,d_left,d_right);
                                                      
                        else
                        
                        A_Aug_Matrix(0,0) :=  to_sfixed(0.999747358950000, d_left, d_right);
                        A_Aug_Matrix(0,1) :=  resize(L_theta - to_sfixed(0.000000014550000,d_left,d_right), d_left, d_right);
                        A_Aug_Matrix(0,2) :=  to_sfixed(0.000100000000000, d_left, d_right); 
                        A_Aug_Matrix(0,3) :=  to_sfixed( 0,d_left,d_right);
                        A_Aug_Matrix(0,4) :=  to_sfixed(0.000244441050000,d_left,d_right);
                        A_Aug_Matrix(0,5) :=  to_sfixed(-0.000005020650000,d_left,d_right);
                        A_Aug_Matrix(1,0) :=  resize(C_theta - to_sfixed(-0.000000025150000,d_left,d_right), d_left, d_right);
                        A_Aug_Matrix(1,1) :=  to_sfixed(0.999633618150000,d_left,d_right);
                        A_Aug_Matrix(1,2) :=  to_sfixed(0,d_left,d_right);
                        A_Aug_Matrix(1,3) :=  to_sfixed(-0.000175438600000,d_left,d_right);
                        A_Aug_Matrix(1,4) :=  to_sfixed(0.000113903800000,d_left,d_right);
                        A_Aug_Matrix(1,5) :=  to_sfixed(0.000366381850000,d_left,d_right);
                       
                       end if;
                       
                         else
                            State := S0;
                         end if;
         
        else
        SW_norm <= to_sfixed(0, n_left, n_right);
        SW_residual <= to_sfixed(0, n_left, n_right);
        State := S0;
        end if;



                    
                          -------------------------------------------
                          --    State S1 (filling up of pipeline)
                          -------------------------------------------
                          when S1 =>
                              A_SW <= A_Aug_Matrix(j0, k0);  
                              B_SW <= State_inp_Matrix(k0);
                              k0 <= k0 +1;
                              Count0 <= Count0 + 1;
                              State := S2;
                              
                          ---------------------------------------
                          --    State S2 (more of filling up)
                          ---------------------------------------
                          when S2 =>
                              A_SW <= A_Aug_Matrix(j0, k0);  
                              B_SW <= State_inp_Matrix(k0);
                   
                              P_SW <= resize(A_SW * B_SW, P_SW'high, P_SW'low);
                              k0 <= k0 +1;
                              Count0 <= Count0 + 1;
                              State := S3;
                              
                          -------------------------------------------
                          --    State S3 (even more of filling up)
                          -------------------------------------------
                          when S3 =>
                              A_SW <= A_Aug_Matrix(j0, k0);  
                              B_SW <= State_inp_Matrix(k0);
                   
                              P_SW <= resize(A_SW * B_SW, P_SW'high, P_SW'low);
                              Sum_SW <= resize(P_SW, Sum_SW'high, Sum_SW'low);
                              
                              k1 <= k1+1;
                              k0 <= k0+1;
                              Count0 <= Count0 + 1;
                              State := S4;
                   
                          -------------------------------------------------
                          --    State S4 (pipeline full, complete work)
                          -------------------------------------------------
                          when S4 =>
                              A_SW <= A_Aug_Matrix(j0, k0);  
                              B_SW <= State_inp_Matrix(k0);
                   
                              P_SW <= resize(A_SW * B_SW, P_SW'high, P_SW'low);
                   
                              if (k1 = 0) then
                                  Sum_SW <= resize(P_SW, Sum_SW'high, Sum_SW'low);
                                  C_Matrix(k2) := resize(Sum_SW, n_left, n_right);
                                  k2 <= k2 +1;
                              else
                                  Sum_SW <= resize(Sum_SW + P_SW, Sum_SW'high, Sum_SW'low);
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
                                  P_SW <= resize(A_SW * B_SW, P_SW'high, P_SW'low);          
                                  Sum_SW <= resize(Sum_SW + P_SW, Sum_SW'high, Sum_SW'low);
                                  State := S6;
                   
                          -------------------------------------
                          --    State S6 (more of flushing)
                          -------------------------------------
                          when S6 =>
                                   
                          Sum_SW <= resize(Sum_SW + P_SW, Sum_SW'high, Sum_SW'low);
                          State := S7;

                          -------------------------------------------
                          --    State S7 (completion of flushing)
                          -------------------------------------------
                          when S7 =>
                           C_Matrix(k2) := Sum_SW;                 
                           State := S8;
                           Count0 <= "0000";
                           k0 <= 0;
                        
                          ------------------------------------
                          --    State S8 (output the data)
                          ------------------------------------
                          when S8 =>
                           State_inp_Matrix(0) := C_Matrix(0);
                           State_inp_Matrix(1) := C_Matrix(1);
                           SW_zval <=  C_Matrix;
                           State := S9;
                           --  w calculation                              
                           ePhSW(0) <= resize(to_sfixed(-62.24, n_left, n_right) * C_Matrix(0), n_left, n_right);
                           ePhSW(1) <= resize(to_sfixed(443.1, n_left, n_right) * C_Matrix(0), n_left, n_right);
                           
                          when S9 =>
                          -- w calculation
                           ePhSW(0) <= resize(ePhSW(0) + (to_sfixed(-527.1, n_left, n_right) * State_inp_Matrix(1)), n_left, n_right);
                           ePhSW(1) <= resize(ePhSW(1) + (to_sfixed(35.48, n_left, n_right) * State_inp_Matrix(1)), n_left, n_right);
                          -- Error calcultion
                           SW_err_val(0) <= resize(plt_x(0) - C_Matrix(0), n_left, n_right);
                           SW_err_val(1) <= resize(plt_x(1) - C_Matrix(1), n_left, n_right);
                           State := S10;
                           
                          when S10 =>
                          -- For w calculation which decides on theta
                           An_SW <= ePhSW(0);  
                           B_SW <= SW_err_val(0);
                           State := S11;
                           
                           when S11 =>
                           An_SW <= ePhSW(1);  
                           B_SW <= SW_err_val(1);
                           P_SW <= resize(An_SW * B_SW, P_SW'high, P_SW'low);
                           State := S12;
                          
                           when S12 =>
                           Sum_SW <= P_SW;
                           P_SW <= resize(An_SW * B_SW, P_SW'high, P_SW'low);
                           -- Norm calculation
                           An_SW <= SW_err_val(0);
                           B_SW <= SW_err_val(0);
                           State := S13; 
                           
                           when S13 =>
                           wforthetaSW <= resize(Sum_SW + P_SW, n_left, n_right);
                           -- Norm calculation
                           An_SW <= SW_err_val(1);
                           B_SW <= SW_err_val(1);
                           P_SW <= resize(An_SW * B_SW, P_SW'high, P_SW'low);
                           State := S14;                             
                           
                           when S14 =>
                            -- Norm calculation
                            Sum_SW <= P_SW;
                            P_SW <= resize(An_SW * B_SW, P_SW'high, P_SW'low);
                            State := S15;
                           
                           when S15 =>
                           -- Norm calculation
                           SW_norm_out <= resize(Sum_SW + P_SW, n_left, n_right);
                           SW_norm <= resize(Sum_SW + P_SW, n_left, n_right);
                           State := S16;                                                 
                          
                          
                           when S16 =>
                           -- Residual calculation
                           An_SW <= resize(to_sfixed(0.9995,d_left,d_right) * SW_residual_funct_out, n_left, n_right);
                           A_SW <= resize(h * SW_norm_out, d_left, d_right);
                           SW_residual_out  <= resize(SW_norm_out + SW_residual_funct_out, n_left, n_right); 
                           State := S17;
                         
                           when S17 =>
                           SW_residual_out <= resize(to_sfixed(10, n_left, n_right) * SW_residual_out, n_left, n_right);
                           SW_residual <=  resize(to_sfixed(10, n_left, n_right) * SW_residual_out, n_left, n_right);
                           done <= '1';
                           SW_residual_funct_out <= resize(An_SW + A_SW, n_left, n_right);                           
                           State := S0;
                         
                          end case;
                      end if;
                 end process;
end Behavioral;
