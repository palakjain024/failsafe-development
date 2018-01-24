-- PWM Module
library IEEE;
library IEEE_PROPOSED;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use IEEE_PROPOSED.FIXED_PKG.ALL;
library work;
use work.input_pkg.all;


ENTITY pwm_activehigh IS
  PORT(
      clk       : IN  STD_LOGIC;                                    --system clock
      reset_n   : IN  STD_LOGIC;                                    --asynchronous reset
      ena       : IN  STD_LOGIC;                                    --latches in new duty cycle
      duty      : IN  sfixed(n_left downto n_right);                       --duty cycle (range given by bit resolution)
      pwm_out   : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '0');          --pwm outputs
      pwm_n_out : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0) := (others => '0'));         --pwm inverse outputs
END pwm_activehigh;

ARCHITECTURE logic OF pwm_activehigh IS

  -- PWM Generator
  CONSTANT  period     :  INTEGER := sys_clk/pwm_freq;                      --number of clocks in one pwm period
  TYPE counters IS ARRAY (0 TO phases-1) OF INTEGER RANGE 0 TO period - 1;  --data type for array of period counters
  SIGNAL  count        :  counters := (OTHERS => 0);                        --array of period counters
  SIGNAL   half_duty_new  :  INTEGER RANGE 0 TO period/2 := 0;              --number of clocks in 1/2 duty cycle
  TYPE half_duties IS ARRAY (0 TO phases-1) OF INTEGER RANGE 0 TO period/2; --data type for array of half duty values
  SIGNAL  half_duty    :  half_duties := (OTHERS => 0);                     --array of half duty values (for each phase)

BEGIN

  PROCESS(clk, reset_n)
  BEGIN
    IF(reset_n = '0') THEN                                                   --asynchronous reset
      count <= (OTHERS => 0);                                                --clear counter
      pwm_out <= (OTHERS => '0');                                            --clear pwm outputs
      pwm_n_out <= (OTHERS => '0');                                          --clear pwm inverse outputs
    ELSIF(clk'EVENT AND clk = '1') THEN                                      --rising system clock edge
      IF(ena = '1') THEN                                                     --latch in new duty cycle
        half_duty_new <= to_integer(duty*to_sfixed(period, 31, 0))/2;                                      --determine clocks in 1/2 duty cycle
      END IF;
      FOR i IN 0 to phases-1 LOOP                                            --create a counter for each phase
        IF(count(0) = period - 1 - i*period/phases) THEN                       --end of period reached
          count(i) <= 0;                                                         --reset counter
          half_duty(i) <= half_duty_new;                                         --set most recent duty cycle value
        ELSE                                                                   --end of period not reached
          count(i) <= count(i) + 1;                                              --increment counter
        END IF;
      END LOOP;
      FOR i IN 0 to phases-1 LOOP                                            --control outputs for each phase
        IF(count(i) = half_duty(i)) THEN                                       --phase's falling edge reached
          pwm_out(i) <= '0';                                                     --deassert the pwm output
          pwm_n_out(i) <= '1';                                                   --assert the pwm inverse output
        ELSIF(count(i) = period - half_duty(i)) THEN                           --phase's rising edge reached
          pwm_out(i) <= '1';                                                     --assert the pwm output
          pwm_n_out(i) <= '0';                                                   --deassert the pwm inverse output
        END IF;
      END LOOP;
    END IF;
  END PROCESS;
END logic;