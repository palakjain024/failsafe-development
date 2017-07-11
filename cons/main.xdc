# Mapping system clock
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# For injecting switch faults (PWM for phase a change: switch SW0)
set_property PACKAGE_PIN F22 [get_ports pwm_f]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_f]

# For reseting faults
set_property PACKAGE_PIN G22 [get_ports reset_fd]
set_property IOSTANDARD LVCMOS33 [get_ports reset_fd]

#JC4_p (T4)
set_property PACKAGE_PIN T4 [get_ports FD_flag]
set_property IOSTANDARD LVCMOS33 [get_ports FD_flag]

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
#set_property PACKAGE_PIN Y4 [get_ports {pwm_out_t[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pwm_out_t[2]}]

#set_property PACKAGE_PIN T4 [get_ports {pwm_n_out_t[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pwm_n_out_t[2]}]

# Digilent PMOD AD1 _1 ADC to PMOD JA1 to JA4 (For adc_1 and adc_2)
set_property PACKAGE_PIN Y11 [get_ports AD_CS_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_CS_1]

set_property PACKAGE_PIN AA11 [get_ports AD_D0_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D0_1]

set_property PACKAGE_PIN Y10 [get_ports AD_D1_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D1_1]

set_property PACKAGE_PIN AA9 [get_ports AD_SCK_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_SCK_1]

# Digilent PMOD AD1_2 ADC to PMOD JB1 to JB4 (For adc_3 and adc_4)
set_property PACKAGE_PIN W12 [get_ports AD_CS_2]
set_property IOSTANDARD LVCMOS33 [get_ports AD_CS_2]

set_property PACKAGE_PIN W11 [get_ports AD_D0_2]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D0_2]

set_property PACKAGE_PIN V10 [get_ports AD_D1_2]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D1_2]

set_property PACKAGE_PIN W8 [get_ports AD_SCK_2]
set_property IOSTANDARD LVCMOS33 [get_ports AD_SCK_2]

# Digilent PMOD AD1_3 ADC to PMOD JB7 to JB10 (For adc_5 and adc_6)
set_property PACKAGE_PIN V12 [get_ports AD_CS_3]
set_property IOSTANDARD LVCMOS33 [get_ports AD_CS_3]

set_property PACKAGE_PIN W10 [get_ports AD_D0_3]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D0_3]

set_property PACKAGE_PIN V9 [get_ports AD_D1_3]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D1_3]

set_property PACKAGE_PIN V8 [get_ports AD_SCK_3]
set_property IOSTANDARD LVCMOS33 [get_ports AD_SCK_3]

# Digilent PMOD DA1_1 DAC to PMOD JD1_P to JD2_N (For adc_5 and adc_6)
set_property PACKAGE_PIN V7 [get_ports DA_nSYNC_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_nSYNC_1]

set_property PACKAGE_PIN W7 [get_ports DA_DATA1_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA1_1]

set_property PACKAGE_PIN V5 [get_ports DA_DATA2_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA2_1]

set_property PACKAGE_PIN V4 [get_ports DA_CLK_OUT_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_CLK_OUT_1]

# Digilent PMOD DA1_2 DAC to PMOD JD3_P to JD4_N (For adc_5 and adc_6)
set_property PACKAGE_PIN W6 [get_ports DA_nSYNC_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_nSYNC_2]

set_property PACKAGE_PIN W5 [get_ports DA_DATA1_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA1_2]

set_property PACKAGE_PIN U6 [get_ports DA_DATA2_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA2_2]

set_property PACKAGE_PIN U5 [get_ports DA_CLK_OUT_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_CLK_OUT_2]