-- With C = 100e-06 and L = 5 mH
-- Note here value of count0 depends on number of MULT operations to be performed
-- 
library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_1164.ALL;
use work.input_pkg.all;

entity plant_x is
 port (Clk   : in STD_LOGIC;
       Start : in STD_LOGIC;
       Mode  : in INTEGER range 1 to 8;
       u_inp : in vect4;
       plt_x : in vect3;
       Done  : out STD_LOGIC := '0';
       plt_z : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right))
       );
end plant_x;

architecture Behavioral of plant_x is
     -- Debug core
        COMPONENT ila_0
     PORT(   
     
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
            probe12 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
            probe13 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
            probe14 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            probe15 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
                        
        );
        END COMPONENT ila_0;
         
    -- ila core signals
     signal probe_pila, probe_zila, probe_va : STD_LOGIC_VECTOR(31 downto 0);
     signal probe_pilb, probe_zilb, probe_vb : STD_LOGIC_VECTOR(31 downto 0);
     signal probe_pilc, probe_zilc, probe_vc : STD_LOGIC_VECTOR(31 downto 0);
     signal probe_vin, probe_a, probe_b : STD_LOGIC_VECTOR(31 downto 0);
     signal probe_p, probe_sum : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
                 
    -- Matrix cal 
      signal	Count0	: UNSIGNED (5 downto 0):="000000";
	  signal	A       : sfixed(d_left downto d_right);
	  signal	An      : sfixed(n_left downto n_right);
	  signal	B       : sfixed(n_left downto n_right);
	  signal	P       : sfixed(n_left downto n_right);
	  signal	Sum	    : sfixed(n_left downto n_right);
      signal 	j0, k0, k1, k2 : INTEGER := 0;

   -- For Norm calculation
      signal  z_val, err_val  : vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right));
      signal  norm           : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
      
    
begin

mult: process(Clk, u_inp, plt_x)
  
   -- General Variables for multiplication and addition
  type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14);
  variable     State         : STATE_VALUE := S0;

  -- Matrix values depends on type of mode
  variable A_Aug_Matrix         : mat310;
  variable State_inp_Matrix     : vect10:= (il, il, il, u_inp(0), u_inp(1), u_inp(2), u_inp(3), plt_x(0), plt_x(1), plt_x(2));
  variable C_Matrix             : vect3;

   begin
           
   if (Clk'event and Clk = '1') then
   -- Debug core
    probe_pila <= result_type(plt_x(0));
    probe_zila <= result_type(z_val(0)); 
    probe_va <= result_type(u_inp(1)); 
    
    probe_pilb <= result_type(plt_x(1));
    probe_zilb <= result_type(z_val(1)); 
    probe_vb <= result_type(u_inp(2));
        
    probe_pilc <= result_type(plt_x(2));
    probe_zilc <= result_type(z_val(2)); 
    probe_vc <= result_type(u_inp(3)); 
    
    probe_vin <= result_type(u_inp(0));
    probe_a <= result_type(A); 
    probe_b <= result_type(B); 
    
    probe_p <= result_type(P);
    probe_sum <= result_type(Sum); 
  
   
   
   -- Inputs
   State_inp_Matrix(3) := u_inp(0);
   State_inp_Matrix(4) := u_inp(1);
   State_inp_Matrix(5) := u_inp(2);
   State_inp_Matrix(6) := u_inp(3);
   State_inp_Matrix(7) := plt_x(0);
   State_inp_Matrix(8) := plt_x(1);
   State_inp_Matrix(9) := plt_x(2);
   
   -- A matrix
   A_Aug_Matrix(0,0) := to_sfixed( 0.999980000000000,d_left,d_right);
   A_Aug_Matrix(0,1) := to_sfixed( 0.000010000000000 ,d_left,d_right);
   A_Aug_Matrix(0,2) := to_sfixed( 0.000010000000000 ,d_left,d_right);
   A_Aug_Matrix(1,0) := to_sfixed( 0.000010000000000 ,d_left,d_right);
   A_Aug_Matrix(1,1) := to_sfixed( 0.999980000000000,d_left,d_right);
   A_Aug_Matrix(1,2) := to_sfixed( 0.000010000000000 ,d_left,d_right);
   A_Aug_Matrix(2,0) := to_sfixed( 0.000010000000000 ,d_left,d_right);
   A_Aug_Matrix(2,1) := to_sfixed( 0.000010000000000 ,d_left,d_right);
   A_Aug_Matrix(2,2) := to_sfixed( 0.999980000000000,d_left,d_right);
    
   -- B matrix  
   A_Aug_Matrix(0,4) := to_sfixed( 0.000066666666667,d_left,d_right);
   A_Aug_Matrix(0,5) := to_sfixed(-0.000033333333333,d_left,d_right);
   A_Aug_Matrix(0,6) := to_sfixed(-0.000033333333333,d_left,d_right);
   A_Aug_Matrix(1,4) := to_sfixed(-0.000033333333333,d_left,d_right); 
   A_Aug_Matrix(1,5) := to_sfixed( 0.000066666666667,d_left,d_right);
   A_Aug_Matrix(1,6) := to_sfixed(-0.000033333333333,d_left,d_right);
   A_Aug_Matrix(2,4) := to_sfixed(-0.000033333333333,d_left,d_right);
   A_Aug_Matrix(2,5) := to_sfixed(-0.000033333333333,d_left,d_right);
   A_Aug_Matrix(2,6) := to_sfixed( 0.000066666666667,d_left,d_right);
   
   -- LO gain
   A_Aug_Matrix(0,7) := to_sfixed( 0,d_left,d_right);
   A_Aug_Matrix(0,8) := to_sfixed( 0,d_left,d_right);
   A_Aug_Matrix(0,9) := to_sfixed( 0,d_left,d_right);
   A_Aug_Matrix(1,7) := to_sfixed( 0,d_left,d_right);
   A_Aug_Matrix(1,8) := to_sfixed( 0,d_left,d_right);
   A_Aug_Matrix(1,9) := to_sfixed( 0,d_left,d_right);
   A_Aug_Matrix(2,7) := to_sfixed( 0,d_left,d_right);
   A_Aug_Matrix(2,8) := to_sfixed( 0,d_left,d_right);
   A_Aug_Matrix(2,9) := to_sfixed( 0,d_left,d_right);
   
   -- Mode selection
   if Mode = 1 then
      A_Aug_Matrix(0,3) := to_sfixed(0,d_left,d_right);
      A_Aug_Matrix(1,3) := to_sfixed(0,d_left,d_right);
      A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right);
              
   elsif Mode = 2 then
      A_Aug_Matrix(0,3) := to_sfixed( 0.000033333333333,d_left,d_right);
      A_Aug_Matrix(1,3) := to_sfixed( 0.000033333333333,d_left,d_right);
      A_Aug_Matrix(2,3) := to_sfixed(-0.000066666666667,d_left,d_right); 
             
   elsif Mode = 3 then
      A_Aug_Matrix(0,3) := to_sfixed( 0.000033333333333,d_left,d_right);
      A_Aug_Matrix(1,3) := to_sfixed(-0.000066666666667,d_left,d_right);
      A_Aug_Matrix(2,3) := to_sfixed( 0.000033333333333,d_left,d_right);
            
   elsif Mode = 4 then
      A_Aug_Matrix(0,3) := to_sfixed( 0.000066666666667,d_left,d_right); 
      A_Aug_Matrix(1,3) := to_sfixed(-0.000033333333333,d_left,d_right);
      A_Aug_Matrix(2,3) := to_sfixed(-0.000033333333333,d_left,d_right);        
   
   elsif Mode = 5 then
      A_Aug_Matrix(0,3) := to_sfixed(-0.000066666666667,d_left,d_right);
      A_Aug_Matrix(1,3) := to_sfixed( 0.000033333333333,d_left,d_right);
      A_Aug_Matrix(2,3) := to_sfixed( 0.000033333333333,d_left,d_right);       
    
   elsif Mode = 6 then
      A_Aug_Matrix(0,3) := to_sfixed(-0.000033333333333,d_left,d_right); 
      A_Aug_Matrix(1,3) := to_sfixed( 0.000066666666667,d_left,d_right);
      A_Aug_Matrix(2,3) := to_sfixed(-0.000033333333333,d_left,d_right); 
         
   elsif Mode = 7 then
      A_Aug_Matrix(0,3) := to_sfixed(-0.000033333333333,d_left,d_right);
      A_Aug_Matrix(1,3) := to_sfixed(-0.000033333333333,d_left,d_right);
      A_Aug_Matrix(2,3) := to_sfixed( 0.000066666666667,d_left,d_right);
            
   elsif Mode = 8 then
      A_Aug_Matrix(0,3) := to_sfixed(0,d_left,d_right);
      A_Aug_Matrix(1,3) := to_sfixed(0,d_left,d_right);
      A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right);
      
   else null;
   end if;
              
       case State is
       ------------------------------------------
       --    State S0 (wait for start signal)
       ------------------------------------------
       when S0 =>
           j0 <= 0; k0 <= 0; k1 <= 0; k2 <= 0;
           Done <= '0';
           Count0 <= "000000";
           
           if( Start = '1' ) then
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
        --    State S2 (more of filling up) [1st mult operation]
        ---------------------------------------
        when S2 =>
             A <= A_Aug_Matrix(j0, k0);  
             B <= State_inp_Matrix(k0);
      
             P <= resize(A * B, P'high, P'low);
             k0 <= k0 +1;
             Count0 <= Count0 + 1;
             State := S3;
      
       -------------------------------------------
       --    State S3 (even more of filling up) [2nd  mult op]
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
        --    State S4 (pipeline full, complete work) [total - 3] mult operation
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
      
          if (k1 = 9) then
              k1 <= 0;
          else
              k1 <= k1 + 1;
          end if;
                 
              
                 ----------------------------------
                 -- check if all initiations done
                 ----------------------------------
                 if (Count0 = 29) then  -- value = total mult operation - 1 (30 - 1, 3x10 and 10x1)
                     State := S5;
                 else
                     State := S4;                
                     Count0 <= Count0 + 1;
                    if (k0 = 9) then
                     j0 <= j0 +1;
                     k0 <= 0;
                     else 
                     k0 <= k0 +1;
                     end if;
                 end if;
      
             ------------------------------------------------
             --    State S5 (start flushing the pipeline) [Last mult operation]
             ------------------------------------------------
             when S5 =>
                     P <= resize(A * B, P'high, P'low);          
                     Sum <= resize(Sum + P, Sum'high, Sum'low);
                     State := S6;
                     
             -- Total time till here is 320 ns
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
                        Count0 <= "000000";
                        k0 <= 0;
                     
             ------------------------------------
             --    State S8 (output the data)
             ------------------------------------
             when S8 =>
              State_inp_Matrix(0) := C_Matrix(0);
              State_inp_Matrix(1) := C_Matrix(1);
              State_inp_Matrix(2) := C_Matrix(2);
              plt_z <=  C_Matrix;
              z_val <= C_Matrix;
              State := S9;
              
            when S9 =>
              err_val(0) <= resize(plt_x(0) - C_Matrix(0), n_left, n_right);
              err_val(1) <= resize(plt_x(1) - C_Matrix(1), n_left, n_right);
              err_val(2) <= resize(plt_x(2) - C_Matrix(2), n_left, n_right);
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
               An <= err_val(2);
               B <= err_val(2);
               P <= resize(An * B, n_left, n_right);
               Sum <= P;
               State := S13;
               
            when S13 =>
               P <= resize(An * B, n_left, n_right);
               Sum <= resize(Sum + P, n_left, n_right);
               State := S14;   
               
            when S14 =>
              norm <= resize(Sum + P, n_left, n_right);
              State := S0;   
              done <= '1';

   end case;
end if;
end process;

 -- Debug core           
ila_inst_0: ila_0
      PORT MAP (
          clk => Clk,
          probe0 => probe_zila, 
          probe1 => probe_zilb, 
          probe2 => probe_zilc, 
          probe3 => probe_vin, 
          probe4 => probe_va, 
          probe5 => probe_vb, 
          probe6 => probe_vc, 
          probe7 => probe_pila, 
          probe8 => probe_pilb, 
          probe9 => probe_pilc, 
          probe10 => probe_a, 
          probe11 => probe_b, 
          probe12 => probe_p, 
          probe13 => probe_sum, 
          probe14 => std_logic_vector(to_unsigned(Mode, 8)), 
          probe15(0) => start
                 
      );
end Behavioral;
