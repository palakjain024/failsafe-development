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
     port (   Clk : in STD_LOGIC;
              Start : in STD_LOGIC;
              Mode : in INTEGER range 0 to 2;
              load : in sfixed(n_left downto n_right);
              plt_x : in vect2;
              done : out STD_LOGIC := '0';
              FD_residual : out sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
              plt_z : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
           );
end plant_x;

architecture Behavioral of plant_x is

     -- Debug core
    COMPONENT ila_0
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT  ; 
   
   -- ILA core
      signal probe0, probe1: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
   
   -- Matrix cal 
      signal	Count0	: UNSIGNED (3 downto 0):="0000";
	  signal	A       : sfixed(d_left downto d_right);
	  signal	An      : sfixed(n_left downto n_right);
	  signal	B       : sfixed(n_left downto n_right);
	  signal	P       : sfixed(n_left downto n_right);
	  signal	Sum	    : sfixed(n_left downto n_right);
      signal 	j0, k0, k1, k2 : INTEGER := 0;

   -- For Norm calculation
      signal  z_val, err_val  : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
      signal  norm           : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
      signal  residual_funct : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
      signal  residual_eval  : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);

begin

mult: process(Clk, load, plt_x)

  
   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15);
   variable     State         : STATE_VALUE := S0;

   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat26;
   variable State_inp_Matrix     : vect6:= (il0, vc0, v_in, load, plt_x(0), plt_x(1));
   variable C_Matrix             : vect2;

   begin
           
   if (Clk'event and Clk = '1') then
   
     
   -- For ILA core
     probe0 <= result_type(err_val(0));
     probe1 <= result_type(err_val(1));
     
    State_inp_Matrix(2) := v_in;
    State_inp_Matrix(3) := load;
    State_inp_Matrix(4) := plt_x(0);
    State_inp_Matrix(5) := plt_x(1);
    
   case Mode is
           
           when 0 =>
           ----------------------------------------
           -- Mode 0 - A:B matrix diode is conducting
           ----------------------------------------
           A_Aug_Matrix := ( 
                          (to_sfixed(0.999458300000000,A'high,A'low),
                           to_sfixed(-0.000036950000000,A'high,A'low), 
                           to_sfixed( 0.000100000000000,A'high,A'low), 
                           to_sfixed( 0,A'high,A'low),
                           to_sfixed( 0.000533500000000,A'high,A'low),
                           to_sfixed(-0.000063050000000,A'high,A'low)),
                          (to_sfixed(0.000101488600000,A'high,A'low), 
                           to_sfixed(0.999561650000000,A'high,A'low),
                           to_sfixed(0,A'high,A'low),
                           to_sfixed(-0.000175438600000,A'high,A'low),
                           to_sfixed( 0.000073950000000,A'high,A'low),
                           to_sfixed( 0.000438350000000,A'high,A'low))
                          );
       
                   
              when 1 =>
              ----------------------------------------
              -- Mode 1 - A:B matrix Switch is conducting current building up
              ----------------------------------------
               A_Aug_Matrix := ( 
                             (to_sfixed( 0.999458300000000,A'high,A'low),
                              to_sfixed( 0.000063050000000,A'high,A'low), 
                              to_sfixed( 0.000100000000000,A'high,A'low), 
                              to_sfixed( 0,A'high,A'low),
                              to_sfixed( 0.000533500000000,A'high,A'low),
                              to_sfixed(-0.000063050000000,A'high,A'low)),
                             (to_sfixed(-0.000073950000000,A'high,A'low), 
                              to_sfixed( 0.999561650000000,A'high,A'low),
                              to_sfixed( 0,A'high,A'low),
                              to_sfixed(-0.000175438600000,A'high,A'low),
                              to_sfixed( 0.000073950000000,A'high,A'low),
                              to_sfixed( 0.000438350000000,A'high,A'low))
                             );
                      
               when others =>
                A_Aug_Matrix := ( 
                                (to_sfixed(0.999458300000000,A'high,A'low),
                                 to_sfixed(-0.000036950000000,A'high,A'low), 
                                 to_sfixed( 0.000100000000000,A'high,A'low), 
                                 to_sfixed( 0,A'high,A'low),
                                 to_sfixed( 0.000533500000000,A'high,A'low),
                                 to_sfixed(-0.000063050000000,A'high,A'low)),
                                (to_sfixed(0.000101488600000,A'high,A'low), 
                                 to_sfixed(0.999561650000000,A'high,A'low),
                                 to_sfixed(0,A'high,A'low),
                                 to_sfixed(-0.000175438600000,A'high,A'low),
                                 to_sfixed( 0.000073950000000,A'high,A'low),
                                 to_sfixed( 0.000438350000000,A'high,A'low))
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
                              
                              FD_residual <= residual_eval;
                              if( start = '1' ) then
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
                           State_inp_Matrix(0) := C_Matrix(0);
                           State_inp_Matrix(1) := C_Matrix(1);
                           plt_z <=  C_Matrix;
                           z_val <= C_Matrix;
                           State := S9;
                           
                         when S9 =>
                           err_val(0) <= resize(State_inp_Matrix(4) - C_Matrix(0), n_left, n_right);
                           err_val(1) <= resize(State_inp_Matrix(5) - C_Matrix(1), n_left, n_right);
                           State := S10;
                           
                         when S10 =>
                           An <= err_val(0);
                           B <= err_val(0);
                           State := S11;
                            
                         when S11 =>
                            An <= err_val(1);
                            B <= err_val(1);
                            P <= resize(An * B, n_left, n_right);
                            State := S12;
                            
                         when S12 =>
                            P <= resize(An * B, n_left, n_right);
                            Sum <= P;
                            State := S13;
                            
                         when S13 =>
                            norm <= resize(Sum + P, n_left, n_right);
                            State := S14;
                            
                         when S14 =>
                            An <= resize(to_sfixed(0.999995,d_left,d_right) * residual_funct, n_left, n_right);
                            A <= resize(h*norm, d_left, d_right);
                            State := S15;
                            
                         when S15 =>
                            residual_funct <= resize(An + A, n_left, n_right);
                            residual_eval <= resize(norm + residual_funct, n_left, n_right);                             
                            State := S0;   
                            done <= '1';
    
                end case;
           end if;
      end process;

      -- Debug core
            
      ila_inst_0: ila_0
      PORT MAP (
          clk => clk,
          probe0 => probe0, 
          probe1 => probe1 
      );
end Behavioral;
