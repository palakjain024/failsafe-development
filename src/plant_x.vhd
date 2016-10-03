-- With C = 100e-06 and L = 5 mH
library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.input_pkg.all;

entity plant_x is
     port (   Clk : in STD_LOGIC;
              Start : in STD_LOGIC;
              Mode : in INTEGER range 0 to 2;
              load: in sfixed(n_left downto n_right);
              Done : out STD_LOGIC := '0';
              plt_x : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
           );
end plant_x;

architecture Behavioral of plant_x is
    
    signal	Count0	: UNSIGNED (2 downto 0):="000";
	signal	A       : sfixed(d_left downto d_right);
	signal	B       : sfixed(n_left downto n_right);
	signal	P       : sfixed(A'left+B'left+1 downto A'right+B'right);
	signal	Sum	    : sfixed(P'left+3 downto P'right);  -- +3 because of 3 sums would be done for one element [A:B]*[state input] = State(element)
    signal 	j0, k0, k2, k3 : INTEGER := 0;
    
begin

mult: process(Clk)
  
   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8);
   variable     State         : STATE_VALUE := S0;

   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat24;
   variable State_inp_Matrix     : vect4:= (il0, vc0, v_in, load);
   variable C_Matrix             : vect2;

   begin
           
   if (Clk'event and Clk = '1') then
   State_inp_Matrix(2) := v_in;
   State_inp_Matrix(3) := load;
   case Mode is
           
            when 0 =>
             -- For State Matrix calculation
                      ----------------------------------------
                      -- Mode 0 - A:B matrix top switch is conducting
                      ----------------------------------------
                      A_Aug_Matrix(0,0) := resize(to_sfixed(1, n_left, n_right) + (h*r)*ltheta, d_left, d_right);
                      A_Aug_Matrix(0,1) := resize(-h*ltheta, d_left, d_right);
                      A_Aug_Matrix(0,2) := resize(h*ltheta, d_left, d_right);
                      A_Aug_Matrix(0,3) := to_sfixed(0, d_left, d_right);
                      A_Aug_Matrix(1,0) := resize(h*ctheta, d_left, d_right);
                      A_Aug_Matrix(1,1) := to_sfixed(1, d_left, d_right);
                      A_Aug_Matrix(1,2) := to_sfixed(0, d_left, d_right);
                      A_Aug_Matrix(1,3) := resize(-h*ctheta, d_left, d_right);          
                
            when 1 =>
                    ----------------------------------------
                    -- Mode 1 - A:B matrix  bottom Switch is conducting current building up
                    ----------------------------------------
                     A_Aug_Matrix(0,0) := resize(to_sfixed(1, n_left, n_right) + (h*r)*ltheta, d_left, d_right);
                     A_Aug_Matrix(0,1) := resize(-h*ltheta, d_left, d_right);
                     A_Aug_Matrix(0,2) := to_sfixed(0, d_left, d_right);
                     A_Aug_Matrix(0,3) := to_sfixed(0, d_left, d_right);
                     A_Aug_Matrix(1,0) := resize(h*ctheta, d_left, d_right);
                     A_Aug_Matrix(1,1) := to_sfixed(1, d_left, d_right);
                     A_Aug_Matrix(1,2) := to_sfixed(0, d_left, d_right);
                     A_Aug_Matrix(1,3) := resize(-h*ctheta, d_left, d_right);
                                     
            when others =>
                ----------------------------------------
                -- Mode 1 - A:B matrix  bottom Switch is conducting current building up
                ----------------------------------------
                 A_Aug_Matrix(0,0) := resize(to_sfixed(1, n_left, n_right) + (h*r)*ltheta, d_left, d_right);
                 A_Aug_Matrix(0,1) := resize(-h*ltheta, d_left, d_right);
                 A_Aug_Matrix(0,2) := to_sfixed(0, d_left, d_right);
                 A_Aug_Matrix(0,3) := to_sfixed(0, d_left, d_right);
                 A_Aug_Matrix(1,0) := resize(h*ctheta, d_left, d_right);
                 A_Aug_Matrix(1,1) := to_sfixed(1, d_left, d_right);
                 A_Aug_Matrix(1,2) := to_sfixed(0, d_left, d_right);
                 A_Aug_Matrix(1,3) := resize(-h*ctheta, d_left, d_right);             
                       
    end case;
                 
              
       case State is
       ------------------------------------------
       --    State S0 (wait for start signal)
       ------------------------------------------
       when S0 =>
           j0 <= 0; k0 <= 0; k2 <= 0; k3 <= 0;
           Done <= '0';
           Count0 <= "000";
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
        Done <= '1';
        State_inp_Matrix(0) := C_Matrix(0);
        State_inp_Matrix(1) := C_Matrix(1);
        plt_x <=  C_Matrix;
        State := S0;
       end case;
   end if;
  end process;

end Behavioral;
