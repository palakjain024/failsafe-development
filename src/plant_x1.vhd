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

-- ILA core
COMPONENT ila_0

PORT (
	clk : IN STD_LOGIC;



	probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	probe4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END COMPONENT  ;

      -- ila core signals
      signal probe_il, probe_fd, probe_vc, probe_y1p, probe_y2p : STD_LOGIC_VECTOR(31 downto 0);
      -- Matrix cal 
      signal	Count0	: UNSIGNED (4 downto 0):="00000";
	  signal	A       : sfixed(d_left downto d_right);
	  signal	An      : sfixed(n_left downto n_right);
	  signal	B       : sfixed(n_left downto n_right);
	  signal	P       : sfixed(n_left downto n_right);
	  signal	Sum	    : sfixed(n_left downto n_right);
      signal 	j0, k0, k1, k2 : INTEGER := 0;
      
      -- For z calculation
      signal residual: sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
      signal norm: sfixed(n_left downto n_right) := to_sfixed(0, n_left, n_right);
      signal z_val, err_val : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
begin
mult: process(Clk, load, plt_y)

   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14);
   variable     State         : STATE_VALUE := S0;

   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat37 := ((zer0, zer0, zer0, zer0, zer0, zer0, zer0),
                                            (zer0, zer0, zer0, zer0, zer0, zer0, zer0),
                                            (zer0, zer0, zer0, zer0, zer0, zer0, zer0));
   variable State_inp_Matrix     : vect7:= (il0, il0,  vc0, v_in, load, plt_y(0), plt_y(1));
   variable C_Matrix             : vect3;
   variable C10, C11, D11             : sfixed(n_left downto n_right);
   
   begin
              
   if (Clk'event and Clk = '1') then
   
   -- ILA
   probe_il <= result_type(z_val(0));
   probe_fd <= result_type(residual); 
   probe_vc  <= result_type(z_val(1));
   probe_y1p <= result_type(plt_y(0)) ; 
   probe_y2p <= result_type(plt_y(1));
   FD_residual <= residual;
   
        -- L matrix
        A_Aug_Matrix(0,5) := to_sfixed( -0.000001558800000000,d_left,d_right);
        A_Aug_Matrix(0,6) := to_sfixed( -0.000099688000000000,d_left,d_right);
        A_Aug_Matrix(1,5) := to_sfixed( -0.000001558800000000,d_left,d_right);
        A_Aug_Matrix(1,6) := to_sfixed( -0.000099688000000000,d_left,d_right);
        A_Aug_Matrix(2,5) := to_sfixed(  0.000175197200000000,d_left,d_right);
        A_Aug_Matrix(2,6) := to_sfixed(  0.000007515600000000,d_left,d_right);
                   
                     
      if Mode = 1 then
                 
                 -- A matrix
                 A_Aug_Matrix(0,0) := to_sfixed( 0.999993346944000,d_left,d_right);
                 A_Aug_Matrix(0,1) := to_sfixed( 0.000001558800000,d_left,d_right);
                 A_Aug_Matrix(0,2) := to_sfixed(-0.000000312000000,d_left,d_right);
                 A_Aug_Matrix(1,0) := to_sfixed( 0.000005346944000,d_left,d_right);
                 A_Aug_Matrix(1,1) := to_sfixed( 0.999993358800000,d_left,d_right);
                 A_Aug_Matrix(1,2) := to_sfixed( 0.000099688000000,d_left,d_right);
                 A_Aug_Matrix(2,0) := to_sfixed(-0.000000044196309,d_left,d_right);
                 A_Aug_Matrix(2,1) := to_sfixed(-0.000175197200000,d_left,d_right);
                 A_Aug_Matrix(2,2) := to_sfixed( 0.999992484400000,d_left,d_right);
                 
                 -- B matrix
                 A_Aug_Matrix(0,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(0,4) := to_sfixed(0.000000011856000000,d_left,d_right);
                 A_Aug_Matrix(1,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(1,4) := to_sfixed(-0.000003788144000000,d_left,d_right);
                 A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right); 
                 A_Aug_Matrix(2,4) := to_sfixed(-0.000175153003691,d_left,d_right);
                 
            
                 
       elsif Mode = 2 then
                 
                 -- A matrix
                 A_Aug_Matrix(0,0) := to_sfixed( 0.999993358800000,d_left,d_right);
                 A_Aug_Matrix(0,1) := to_sfixed( 0.000001558800000,d_left,d_right);
                 A_Aug_Matrix(0,2) := to_sfixed( 0.000099688000000,d_left,d_right);
                 A_Aug_Matrix(1,0) := to_sfixed( 0.000001558800000,d_left,d_right);
                 A_Aug_Matrix(1,1) := to_sfixed( 0.999993358800000,d_left,d_right);
                 A_Aug_Matrix(1,2) := to_sfixed( 0.000099688000000,d_left,d_right);
                 A_Aug_Matrix(2,0) := to_sfixed(-0.000175197200000,d_left,d_right);
                 A_Aug_Matrix(2,1) := to_sfixed(-0.000175197200000,d_left,d_right);
                 A_Aug_Matrix(2,2) := to_sfixed( 0.999992484400000,d_left,d_right);
                 
                 -- B matrix
                 A_Aug_Matrix(0,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(0,4) := to_sfixed(-0.00000378814400,d_left,d_right);
                 A_Aug_Matrix(1,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(1,4) := to_sfixed(-0.00000378814400,d_left,d_right);
                 A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right); 
                 A_Aug_Matrix(2,4) := to_sfixed(-0.000175153003691,d_left,d_right);  
                                
      elsif Mode = 3 then
                 -- A matrix
                 A_Aug_Matrix(0,0) := to_sfixed( 0.999993358800000,d_left,d_right);
                 A_Aug_Matrix(0,1) := to_sfixed( 0.000005346944000,d_left,d_right);
                 A_Aug_Matrix(0,2) := to_sfixed( 0.000099688000000,d_left,d_right);
                 A_Aug_Matrix(1,0) := to_sfixed( 0.000001558800000,d_left,d_right);
                 A_Aug_Matrix(1,1) := to_sfixed( 0.999993346944000,d_left,d_right);
                 A_Aug_Matrix(1,2) := to_sfixed(-0.000000312000000,d_left,d_right);
                 A_Aug_Matrix(2,0) := to_sfixed(-0.000175197200000,d_left,d_right);
                 A_Aug_Matrix(2,1) := to_sfixed(-0.000000044196309,d_left,d_right);
                 A_Aug_Matrix(2,2) := to_sfixed( 0.999992484400000,d_left,d_right);
                 
                 -- B matrix
                 A_Aug_Matrix(0,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(0,4) := to_sfixed(-0.00000378814400,d_left,d_right);
                 A_Aug_Matrix(1,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(1,4) := to_sfixed(0.000000011856000,d_left,d_right);
                 A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right); 
                 A_Aug_Matrix(2,4) := to_sfixed(-0.000175153003691,d_left,d_right);
         
      elsif Mode = 4 then
                 -- A matrix
                 A_Aug_Matrix(0,0) := to_sfixed( 0.999993346944000,d_left,d_right);
                 A_Aug_Matrix(0,1) := to_sfixed( 0.000001546944000,d_left,d_right);
                 A_Aug_Matrix(0,2) := to_sfixed(-0.000000312000000,d_left,d_right);
                 A_Aug_Matrix(1,0) := to_sfixed( 0.000001546944000,d_left,d_right);
                 A_Aug_Matrix(1,1) := to_sfixed( 0.999993346944000,d_left,d_right);
                 A_Aug_Matrix(1,2) := to_sfixed(-0.000000312000000,d_left,d_right);
                 A_Aug_Matrix(2,0) := to_sfixed(-0.000000044196300,d_left,d_right);
                 A_Aug_Matrix(2,1) := to_sfixed(-0.000000044196309,d_left,d_right);
                 A_Aug_Matrix(2,2) := to_sfixed( 0.999992484400000,d_left,d_right);
                 
                 -- B matrix
                 A_Aug_Matrix(0,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(0,4) := to_sfixed(0.000000011856000,d_left,d_right);
                 A_Aug_Matrix(1,3) := to_sfixed(0.000100000000000,d_left,d_right); 
                 A_Aug_Matrix(1,4) := to_sfixed(0.000000011856000,d_left,d_right);
                 A_Aug_Matrix(2,3) := to_sfixed(0,d_left,d_right); 
                 A_Aug_Matrix(2,4) := to_sfixed(-0.000175153003691,d_left,d_right); 
     else null;
                 
     end if;
     
---- Step 2:  Multiplication -----
   case State is
          ------------------------------------------
          --    State S0 (wait for start signal)
          ------------------------------------------
          when S0 =>
              j0 <= 0; k0 <= 0; k1 <= 0; k2 <= 0;
              done <= '0';
              Count0 <= "00000";
              
              --FD_residual <= residual_eval;
              if( start = '1' ) then
                  -- Initialization  
                  State_inp_Matrix(3) := v_in;
                  State_inp_Matrix(4) := load;
                  State_inp_Matrix(5) := plt_y(0);
                  State_inp_Matrix(6) := plt_y(1);
                  
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
   
              if (k1 = 6) then
                  k1 <= 0;
                  else
                  k1 <= k1 + 1;
              end if;
              
           
              ----------------------------------
              -- check if all initiations done
              ----------------------------------
              if (Count0 = 20) then
                  State := S5;
              else
                  State := S4;                
                  Count0 <= Count0 + 1;
                 if (k0 = 6) then
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
                     Count0 <= "00000";
                     k0 <= 0;
                  
          ------------------------------------
          --    State S8 (output the data)
          ------------------------------------
          when S8 =>
           State_inp_Matrix(0) := C_Matrix(0);
           State_inp_Matrix(1) := C_Matrix(1);
           State_inp_Matrix(2) := C_Matrix(2);
           C10 := resize(esr * C_Matrix(0), n_left, n_right);
           C11 := resize(esr * C_Matrix(1), n_left, n_right);
           D11 := resize(esr * State_inp_Matrix(4), n_left, n_right);
           
           State := S9;
           
          when S9 =>
                  z_val(0) <= resize(C_Matrix(0) + C_Matrix(1), n_left, n_right);
              if Mode = 1 then
                  z_val(1) <= resize(C10 + C_Matrix(2) - D11, n_left, n_right);
              elsif Mode = 2 then
                  z_val(1) <= resize(C_Matrix(2) - D11, n_left, n_right);
              elsif Mode = 3 then
                  z_val(1) <= resize(C11 + C_Matrix(2) - D11, n_left, n_right);
              elsif Mode = 4 then
                  z_val(1) <= resize(C10 + C11 + C_Matrix(2) - D11, n_left, n_right);
              else null;
              end if;
           State := S10;
                      
          when S10 =>
          plt_z <= z_val;
          err_val(0) <= resize(plt_y(0) - z_val(0), n_left, n_right); 
          err_val(1) <= resize(plt_y(1) - z_val(1), n_left, n_right);
          State := S11;
          
          when S11 =>
          An <= err_val(0);
          B <= err_val(0);
          State := S12;
          
          when S12 =>     
          An <= err_val(1);
          B <= err_val(1);
          P <= resize(An * B, P'high, P'low);
          State := S13;
          
          when S13 =>
          Sum <= P;
          P <= resize(An * B, P'high, P'low);
          State :=  S14;
          
          when S14 =>
          norm <= resize(Sum + P, n_left, n_right);
          residual <= resize(norm * to_sfixed(0.0025,n_left, n_right), n_left, n_right);
          done <= '1';
          State := S0;
         end case;
     end if;         
end process;  
    
    
    -- Debug core
                          
                    ila_inst_0: ila_0
                    PORT MAP (
                        clk => clk,
                    
                    
                    
                        probe0 => probe_fd, 
                        probe1 => probe_il, 
                        probe2 => probe_vc,  
                        probe3 => probe_y1p, 
                        probe4 => probe_y2p
                        
                    );                  
end Behavioral;
