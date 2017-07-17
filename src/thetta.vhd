library IEEE;
library IEEE_PROPOSED;
library work;

use IEEE_PROPOSED.FIXED_PKG.ALL;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.input_pkg.all;

entity thetta is
port (    Clk   : in STD_LOGIC;
          Start : in STD_LOGIC;
          Mode  : in INTEGER range 1 to 4;
          err   : in vect2;
          sigh  : in vecth3;
          done  : out STD_LOGIC := '0';
          lambda_out : out vect3 := (zer0, zer0, zer0);
          thetadot_out : out sfixed(n_left downto n_right):= zer0;
          lambda_thetadot_out : out vect3 := (zer0, zer0, zer0)
      );
end thetta;

architecture Behavioral of thetta is
     -- Component definitions
 
    component lamdda
   port (    Clk   : in STD_LOGIC;
              Start : in STD_LOGIC;
              Mode  : in INTEGER range 1 to 4;
              sigh  : in vecth3;
              done  : out STD_LOGIC := '0';
              lambda_out : out vect3 := (to_sfixed(0,n_left,n_right),to_sfixed(0,n_left,n_right), to_sfixed(0,n_left,n_right))
          );
    end component lamdda;
      -- Matrix cal 
      signal	A       : sfixed(d_left downto d_right);
	  signal	B       : sfixed(n_left downto n_right);
	  signal	P       : sfixed(n_left downto n_right);
	  signal	Sum	    : sfixed(n_left downto n_right);
      -- Lambda cal
      signal lambda_done : STD_LOGIC := '1';
      signal lambda: vect3 := (zer0, zer0, zer0);
      -- theta cal
      signal cy, lcy: vect3;
      signal theta_dot : sfixed(n_left downto n_right) := zer0;      
      
begin

lamddatb_inst: lamdda port map (
clk => clk,
start => start,
Mode  => Mode,
sigh => sigh,
done  => lambda_done,
lambda_out => lambda);


mult: process(Clk, err)

   -- General Variables for multiplication and addition
   type STATE_VALUE is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16);
   variable     State         : STATE_VALUE := S0;

   -- Matrix values depends on type of mode
   variable A_Aug_Matrix         : mat32 := ((zer0, zer0),
                                            (zer0, zer0),
                                            (zer0, zer0));
   variable State_inp_Matrix     : vect2 := (err(0), err(1));
   variable C_Matrix             : vect3;
  
   
   begin
              
   if (Clk'event and Clk = '1') then
   
      lambda_out <= lambda;
      -- T*h*C matrix
       A_Aug_Matrix(0,0) := to_sfixed( 0.00000500000000,d_left,d_right);
       A_Aug_Matrix(0,1) := to_sfixed( 0.00000500000000,d_left,d_right);
       A_Aug_Matrix(1,0) := to_sfixed( 0,d_left,d_right);
       A_Aug_Matrix(2,1) := to_sfixed( 0.000005,d_left,d_right);
   
      if Mode = 1 then
      -- T*h*C matrix
      A_Aug_Matrix(1,1) := to_sfixed( 0.00000019000000000000,d_left,d_right);
      A_Aug_Matrix(2,0) := to_sfixed( 0,d_left,d_right);
     
                 
      elsif Mode = 2 then
      -- T*h*C matrix
      A_Aug_Matrix(1,1) := to_sfixed( 0,d_left,d_right);
      A_Aug_Matrix(2,0) := to_sfixed( 0,d_left,d_right); 
                                
      elsif Mode = 3 then
      -- T*h*C matrix
      A_Aug_Matrix(1,1) := to_sfixed( 0,d_left,d_right);
      A_Aug_Matrix(2,0) := to_sfixed( 0.00000019000000000000,d_left,d_right);
         
      elsif Mode = 4 then
      -- T*h*C matrix
      A_Aug_Matrix(1,1) := to_sfixed( 0.00000019000000000000,d_left,d_right);
      A_Aug_Matrix(2,0) := to_sfixed( 0.00000019000000000000,d_left,d_right);
     else null;
     end if;
---- Step 2:  Multiplication -----
        case State is
  
               
        --  State S0 (wait for start signal)
               when S0 =>
                   
                   done <= '0';
                   if( start = '1' ) then                
                       State := S1;
                       State_inp_Matrix(0) := err(0);
                       State_inp_Matrix(1) := err(1);
                   else
                       State := S0;
                   end if;
        -- T*h*C*e calculation
               when S1 =>
                    A <= A_Aug_Matrix(0,0);  
                    B <= State_inp_Matrix(0);
                    State := S2;

               when S2 =>
                    A <= A_Aug_Matrix(0,1);  
                    B <= State_inp_Matrix(1);
                    P <= resize(A * B, P'high, P'low);
                    State := S3;

               when S3 =>
                    A <= A_Aug_Matrix(1,0);  
                    B <= State_inp_Matrix(0);
                    P <= resize(A * B, P'high, P'low);
                    Sum <= P;
                    State := S4;

               when S4 =>
                    A <= A_Aug_Matrix(1,1);  
                    B <= State_inp_Matrix(1);
                    P <= resize(A * B, P'high, P'low);
                    Sum <= resize(Sum + P, Sum'high, Sum'low);
                    State := S5;
                   
               when S5 =>
                     A <= A_Aug_Matrix(2,0);  
                     B <= State_inp_Matrix(0);
                     P <= resize(A * B, P'high, P'low);
                     Sum <= P;
                    
                     C_Matrix(0) := Sum; 
                     State := S6;  
                                    
               when S6 =>
                    A <= A_Aug_Matrix(2,1);  
                    B <= State_inp_Matrix(1);
                    P <= resize(A * B, P'high, P'low);
                    Sum <= resize(Sum + P, Sum'high, Sum'low);
                    State := S7;        

               when S7 =>
                    P <= resize(A * B, P'high, P'low);          
                    Sum <= P;
               
                    C_Matrix(1) := Sum; 
                    State := S8;

               when S8 =>
                    Sum <= resize(Sum + P, Sum'high, Sum'low);
                    State := S9;
        

               when S9 =>
                    C_Matrix(2) := Sum;                 
                    State := S10;

               when S10 =>
                    cy(0) <= C_Matrix(0);
                    cy(1) <= C_Matrix(1);
                    cy(2) <= C_Matrix(2);
                    State := S11;
                
               when S11 =>
                   lcy(0) <= resize(cy(0) * lambda(0), n_left, n_right);
                   State := S12;
               
               when S12 =>
                   lcy(1) <= resize(cy(1) * lambda(1), n_left, n_right);
                   Sum <= lcy(0);
                   State := S13;
               
               when S13 =>
                   lcy(2) <= resize(cy(2) * lambda(2), n_left, n_right);
                   Sum <= resize(Sum + lcy(1), n_left, n_right);
                   State := S14;
                                
               when S14 =>
                   Sum <= resize(Sum + lcy(2), n_left, n_right);
                   State := S15;                           
               
               when S15 =>
                   theta_dot <= Sum;
                   State := S16; 
                              
               when S16 =>
                   lambda_thetadot_out(0) <= resize(lambda(0) * theta_dot, n_left, n_right);
                   lambda_thetadot_out(1) <= resize(lambda(1) * theta_dot, n_left, n_right);
                   lambda_thetadot_out(2) <= resize(lambda(2) * theta_dot, n_left, n_right);
                   thetadot_out <= theta_dot;
                   done <= '1';
                   State := S0;
      
                 end case; 
             end if;
         end process;     
     
end Behavioral;
