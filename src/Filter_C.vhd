library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.input_pkg.all;

entity Filter_C is
 port (      Clk : in STD_LOGIC;
             Start : in STD_LOGIC;
             flag : in STD_LOGIC;
             Mode : in INTEGER range 0 to 2;
             load : in sfixed(n_left downto n_right);
             plt_x : in vect2;
             done : out STD_LOGIC := '0';
             C_residual : out sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
             C_zval : out vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right))
          );
end Filter_C;

architecture Behavioral of Filter_C is

--   -- Debug core
--    COMPONENT ila_0
     
--     PORT (
--         clk : IN STD_LOGIC;
     
     
     
--         probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
--         probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
--         probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
--         probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
--         probe4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
--         probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
--         probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--         probe7 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
--     );
--     END COMPONENT  ;
     
--   -- ila core signals
--    signal probe0_pil, probe1_zil, probe2_pvc, probe3_zvc, probe4_eil, probe5_evc : STD_LOGIC_VECTOR(31 downto 0);
--    signal probe7_resd : STD_LOGIC_VECTOR(31 downto 0); 
--    signal probe6 : STD_LOGIC_VECTOR(0 downto 0) := "0"; 
        
   -- Matrix cal
    signal	Count0	  : UNSIGNED (3 downto 0):="0000";
    signal    A       : sfixed(d_left downto d_right);
    signal	  An      : sfixed(n_left downto n_right);
    signal    B       : sfixed(n_left downto n_right);
    signal    P       : sfixed(n_left downto n_right);
    signal    Sum     : sfixed(n_left downto n_right);
    signal    j0, k0, k1, k2 : INTEGER := 0;
    
    -- Residual cal
    signal zval : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
    signal errval : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
    signal norm : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    signal residual_funct : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    signal residual_eval : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    
    -- theta cal
    signal Mode_top : INTEGER range 0 to 2 := 0;
    signal sigh : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    signal Psigh : vect2 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
    signal ePsigh : sfixed(n_left downto n_right) := to_sfixed(0,n_left,n_right);
    
begin

mult: process(Clk, load, plt_x)
  
   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17);
   variable     State         : STATE_VALUE := S0;

   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat26;
   variable State_inp_Matrix     : vect6:= (il0, vc0, v_in, load, plt_x(0), plt_x(1));
   variable C_Matrix             : vect2;

   begin
           
   if (Clk'event and Clk = '1') then
      
   
  -- Debug core
    probe0_pil <= result_type(plt_x(0));
    probe1_zil <= result_type(zval(0)); 
    probe2_pvc <= result_type(plt_x(1));  
    probe3_zvc <= result_type(zval(1)); 
    probe4_eil <= result_type(errval(0));
    probe5_evc <= result_type(errval(1));
    probe7_resd <= result_type(residual_eval);  
    
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
                     if( start = '1' ) then
                         State := S1;
                         
                          -- Initialization  
                          State_inp_Matrix(2) := v_in;
                          State_inp_Matrix(3) := load;
                          State_inp_Matrix(4) := plt_x(0);
                          State_inp_Matrix(5) := plt_x(1);
                          
                          -- Matrix calculation
                             -- Discretize LO gain
                             A_Aug_Matrix(0,4) := to_sfixed(0.000279450000000,d_left,d_right);
                             A_Aug_Matrix(0,5) := to_sfixed(0.000495300000000,d_left,d_right);
                             A_Aug_Matrix(1,4) := to_sfixed(0.000083750000000,d_left,d_right);
                             A_Aug_Matrix(1,5) := to_sfixed(0.002336950000000,d_left,d_right);
                             
                      
                                 if Mode = 0 then
                                 Mode_top <= Mode;
                                 -------------------------------------------------
                                 -- Mode 0 - A:B matrix diode is conducting s1 = 1
                                 --------------------------------------------------
                                 A_Aug_Matrix(0,0) := to_sfixed( 0.999712350000000,d_left,d_right);
                                 A_Aug_Matrix(0,1) := to_sfixed(-0.000595300000000 ,d_left,d_right); 
                                 A_Aug_Matrix(0,2) := to_sfixed( 0.000100000000000 ,d_left,d_right); 
                                 A_Aug_Matrix(0,3) := to_sfixed(0,d_left,d_right);
                                 A_Aug_Matrix(1,1) := to_sfixed( 0.99766305000000,d_left,d_right);
                                 A_Aug_Matrix(1,2) := to_sfixed(0,d_left,d_right);
                                 
                                 if ( ePsigh > to_sfixed(0, n_left, n_right) or ePsigh = to_sfixed(0, n_left, n_right) ) then
                                 A_Aug_Matrix(1,0) := to_sfixed( 0.000793450000000,d_left,d_right);
                                 A_Aug_Matrix(1,3) := to_sfixed(-0.000877200000000 ,d_left,d_right);
                                 else
                                 A_Aug_Matrix(1,0) := to_sfixed( 0.000062250000000,d_left,d_right);
                                 A_Aug_Matrix(1,3) := to_sfixed(-0.000146000000000,d_left,d_right);              
                                 end if; 
                                                             
                                 elsif Mode = 1 then
                                 Mode_top <= Mode;
                                ---------------------------------------------------------------
                                -- Mode 1 - A:B matrix Switch is conducting current building up
                                ---------------------------------------------------------------
                                 A_Aug_Matrix(0,0) := to_sfixed(0.999712350000000,d_left,d_right);
                                 A_Aug_Matrix(0,1) := to_sfixed(-0.000495300000000 ,d_left,d_right); 
                                 A_Aug_Matrix(0,2) := to_sfixed( 0.000100000000000 ,d_left,d_right); 
                                 A_Aug_Matrix(0,3) := to_sfixed( 0,d_left,d_right);
                                 A_Aug_Matrix(1,1) := to_sfixed( 0.99766305000000,d_left,d_right);
                                 A_Aug_Matrix(1,2) := to_sfixed(0,d_left,d_right);
                                 A_Aug_Matrix(1,0) := to_sfixed( -0.000083750000000,d_left,d_right);
                                 
                                 if ( ePsigh > to_sfixed(0, n_left, n_right) or ePsigh = to_sfixed(0, n_left, n_right) ) then
                                 A_Aug_Matrix(1,3) := to_sfixed(-0.000877200000000 ,d_left,d_right);
                                 else
                                 A_Aug_Matrix(1,3) := to_sfixed(-0.000146000000000,d_left,d_right);
                                 end if; 
                                                   
                                                       
                                 else
                                 A_Aug_Matrix(0,0) := to_sfixed( 0.999850339050000,d_left,d_right);
                                 A_Aug_Matrix(0,1) := to_sfixed(-0.000100000000000 ,d_left,d_right); 
                                 A_Aug_Matrix(0,2) := to_sfixed( 0.000100000000000 ,d_left,d_right); 
                                 A_Aug_Matrix(0,3) := to_sfixed(0,d_left,d_right);
                              
                                 A_Aug_Matrix(1,0) := to_sfixed(0.000175438600000,d_left,d_right);
                                 A_Aug_Matrix(1,1) := to_sfixed(1,d_left,d_right);
                                 A_Aug_Matrix(1,2) := to_sfixed(0,d_left,d_right);
                                 A_Aug_Matrix(1,3) := to_sfixed(-0.000175438600000,d_left,d_right);
                                   
                                                  
                               end if;
                 
                  else
                     State := S0;
                  end if;
             
             else
             C_residual <= to_sfixed(0, n_left, n_right);
             C_zval <=    (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right));
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
          zval <= C_Matrix;
          State := S9;
          
         when S9 =>
         -- Error cal
          errval(0) <= resize(plt_x(0) - zval(0), n_left, n_right);
          errval(1) <= resize(plt_x(1) - zval(1), n_left, n_right);
         -- Sigh cal
         if Mode_top = 0 then
          sigh <= resize(zval(0) - State_inp_Matrix(3), n_left, n_right); 
         elsif Mode_top = 1 then
          sigh <= resize(to_sfixed(-1,n_left,n_right) * State_inp_Matrix(3), n_left, n_right);
         else null;
         end if;
          State := S10;
           
         when S10 =>
         C_zval <=  zval;
        -- PSigh cal
         Psigh(0) <= resize(to_sfixed(-1.5322, n_left, n_right) * sigh, n_left, n_right);
         Psigh(1) <= resize(to_sfixed( 1.8170, n_left, n_right) * sigh, n_left, n_right);
         State := S11;
         
         when S11 =>
         -- ePsigh cal
         P <= resize(errval(0) * Psigh(0), n_left, n_right);
         State := S12;
         
         when S12 =>
         Sum <= P;
         P <= resize(errval(1) * Psigh(1), n_left, n_right); 
         -- Norm cal
         An <= errval(0);
         B <= errval(0);         
         State := S13;
         
         when S13 =>
         -- ePsigh cal
         ePsigh <=  resize(Sum + P, n_left, n_right);
         -- Residual Cal
         An <= errval(1);
         B <= errval(1);
         P <= resize(An * B, n_left, n_right);
         State := S14;
         
         when S14 =>
         Sum <= P;
         P <= resize(An * B, n_left, n_right);
         State := S15;
         
         when S15 =>
         norm <= resize(Sum + P, n_left, n_right);
         P <=  resize(epsilon * residual_funct, n_left, n_right);
         State := S16;
         
         when S16 =>
         residual_eval  <= resize(norm + residual_funct, n_left, n_right);
         Sum <= P;
         P <=  resize(h * norm, n_left, n_right);
         State := S17;
         
         when S17 =>
         residual_funct <= resize(Sum + P, n_left, n_right);
         C_residual <= residual_eval;
         done <= '1';        
         State := S0;
         end case;
     end if;
  end process;

--      -- Debug core
            
--      ila_inst_0: ila_0
--      PORT MAP (
--          clk => clk,
      
      
      
--          probe0 => probe0_pil, 
--          probe1 => probe1_zil, 
--          probe2 => probe2_pvc,  
--          probe3 => probe3_zvc, 
--          probe4 => probe4_eil, 
--          probe5 => probe5_evc,
--          probe6 => probe6,
--          probe7 => probe7_resd
--      );  
end Behavioral;
