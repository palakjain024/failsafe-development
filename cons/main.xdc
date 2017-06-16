# Mapping system clock
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# For injecting switch faults (PWM for phase a change: switch SW0)
set_property PACKAGE_PIN F22 [get_ports pwm_f]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_f]

# Mapping PWM module phase a to PMOD JC1_p (AB7) and JC3_p (R6) 
set_property PACKAGE_PIN AB7 [get_ports {pwm_out_t[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_out_t[0]}]

set_property PACKAGE_PIN R6 [get_ports {pwm_n_out_t[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_n_out_t[0]}]

# Mapping PWM module phase b to PMOD JC1_n (AB6) and JC3_n (T6) 
set_property PACKAGE_PIN AB6 [get_ports {pwm_out_t[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_out_t[1]}]

set_property PACKAGE_PIN T6 [get_ports {pwm_n_out_t[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_n_out_t[1]}]

# Mapping PWM module phase c to PMOD JC2_p (Y4) and JC4_p (T4) 
set_property PACKAGE_PIN Y4 [get_ports {pwm_out_t[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_out_t[2]}]

set_property PACKAGE_PIN T4 [get_ports {pwm_n_out_t[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_n_out_t[2]}]

# Mapping of FD Flag JC2_n(AA4)
set_property PACKAGE_PIN AA4 [get_ports FD_flag]
set_property IOSTANDARD LVCMOS33 [get_ports FD_flag]

# Mapping of FD flag reset on switch G22 (SW1)
set_property PACKAGE_PIN G22 [get_ports reset_fd]
set_property IOSTANDARD LVCMOS33 [get_ports reset_fd]

# Digilent PMOD DA21 DAC 1 to PMOD JA1 to JA4 
set_property PACKAGE_PIN Y11 [get_ports DA_nSYNC_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_nSYNC_1]

set_property PACKAGE_PIN AA11 [get_ports DA_DATA1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA1]

set_property PACKAGE_PIN Y10 [get_ports DA_DATA2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA2]

set_property PACKAGE_PIN AA9 [get_ports DA_CLK_OUT_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_CLK_OUT_1]

# Digilent PMOD DA21 DAC 2 to PMOD JA7 to JA10 
set_property PACKAGE_PIN AB11 [get_ports DA_nSYNC_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_nSYNC_2]

set_property PACKAGE_PIN AB10 [get_ports DA_DATA3]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA3]

set_property PACKAGE_PIN AB9 [get_ports DA_DATA4]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA4]

set_property PACKAGE_PIN AA8 [get_ports DA_CLK_OUT_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_CLK_OUT_2]

# Digilent PMODAD1 ADC 1 to PMOD JB1 to JB4 
set_property PACKAGE_PIN W12 [get_ports AD_CS_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_CS_1]

set_property PACKAGE_PIN W11 [get_ports AD_D0_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D0_1]

set_property PACKAGE_PIN V10 [get_ports AD_D1_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D1_1]

set_property PACKAGE_PIN W8 [get_ports AD_SCK_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_SCK_1]

# Digilent PMODAD1 ADC 2 to PMOD JB7 to JB10 
set_property PACKAGE_PIN V12 [get_ports AD_CS_2]
set_property IOSTANDARD LVCMOS33 [get_ports AD_CS_2]

set_property PACKAGE_PIN W10 [get_ports AD_D0_2]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D0_2]

set_property PACKAGE_PIN V9 [get_ports AD_D1_2]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D1_2]

set_property PACKAGE_PIN V8 [get_ports AD_SCK_2]
set_property IOSTANDARD LVCMOS33 [get_ports AD_SCK_2]
# Timing constraints
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

