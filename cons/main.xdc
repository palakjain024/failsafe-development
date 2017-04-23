# Mapping system clock
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]


# Mapping PWM module to PMOD JC1_p (AB7) and JC1_n (AB6) PWM (reset on switch SW0)
set_property PACKAGE_PIN AB7 [get_ports {pwm_out_t[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_out_t[0]}]

set_property PACKAGE_PIN AB6 [get_ports {pwm_n_out_t[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_n_out_t[0]}]

set_property PACKAGE_PIN F22 [get_ports pwm_f]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_f]

# Mapping of Flags JC3_p(R6), JC3_n(T6), JC4_p(T4), JC4_n(U4)
set_property PACKAGE_PIN R6 [get_ports FD_flag]
set_property IOSTANDARD LVCMOS33 [get_ports FD_flag]

set_property PACKAGE_PIN G22 [get_ports reset_fd]
set_property IOSTANDARD LVCMOS33 [get_ports reset_fd]

# Digilent PMOD DA21 DAC to PMOD JA1 to JA4 (For theta and err)
set_property PACKAGE_PIN Y11 [get_ports DA_nSYNC]
set_property IOSTANDARD LVCMOS33 [get_ports DA_nSYNC]

set_property PACKAGE_PIN AA11 [get_ports DA_DATA1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA1]

set_property PACKAGE_PIN Y10 [get_ports DA_DATA2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA2]

set_property PACKAGE_PIN AA9 [get_ports DA_CLK_OUT]
set_property IOSTANDARD LVCMOS33 [get_ports DA_CLK_OUT]

# Digilent PMODAD1 ADC 1 to PMOD JB1 to JB4 (For Load )
set_property PACKAGE_PIN W12 [get_ports AD_CS_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_CS_1]

set_property PACKAGE_PIN W11 [get_ports AD_D0_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D0_1]

set_property PACKAGE_PIN V10 [get_ports AD_D1_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D1_1]

set_property PACKAGE_PIN W8 [get_ports AD_SCK_1]
set_property IOSTANDARD LVCMOS33 [get_ports AD_SCK_1]

# Digilent PMODAD1 ADC 2 to PMOD JB7 to JB10 (For iL and Vcap )
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
set_output_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports {pwm_n_out_t[0]}]
set_output_delay -clock [get_clocks clk] -max -add_delay -2.000 [get_ports {pwm_n_out_t[0]}]
set_output_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports {pwm_out_t[0]}]
set_output_delay -clock [get_clocks clk] -max -add_delay -2.000 [get_ports {pwm_out_t[0]}]






set_input_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports pwm_f]
set_input_delay -clock [get_clocks clk] -max -add_delay -4.000 [get_ports pwm_f]


create_generated_clock -name dac_inst/CLK -source [get_ports clk] -divide_by 4 [get_pins {dac_inst/clk_counter_reg[1]/Q}]
create_clock -period 40.000 -name VIRTUAL_dac_inst/CLK -waveform {0.000 20.000}
set_output_delay -clock [get_clocks VIRTUAL_dac_inst/CLK] -min -add_delay 0.000 [get_ports DA_DATA1]
set_output_delay -clock [get_clocks VIRTUAL_dac_inst/CLK] -max -add_delay 9.000 [get_ports DA_DATA1]
set_output_delay -clock [get_clocks VIRTUAL_dac_inst/CLK] -min -add_delay 0.000 [get_ports DA_DATA2]
set_output_delay -clock [get_clocks VIRTUAL_dac_inst/CLK] -max -add_delay 9.000 [get_ports DA_DATA2]
set_output_delay -clock [get_clocks VIRTUAL_dac_inst/CLK] -min -add_delay -1.000 [get_ports DA_nSYNC]
set_output_delay -clock [get_clocks VIRTUAL_dac_inst/CLK] -max -add_delay 4.000 [get_ports DA_nSYNC]







create_generated_clock -name adc_1_inst/clk_div -source [get_ports clk] -divide_by 8 [get_pins {adc_1_inst/clk_counter_reg[2]/Q}]
create_generated_clock -name adc_2_inst/clk_div -source [get_ports clk] -divide_by 8 [get_pins {adc_2_inst/clk_counter_reg[2]/Q}]
create_clock -period 80.000 -name VIRTUAL_adc_1_inst/clk_div -waveform {0.000 40.000}
set_output_delay -clock [get_clocks VIRTUAL_adc_1_inst/clk_div] -min -add_delay -3.000 [get_ports AD_CS_1]
set_output_delay -clock [get_clocks VIRTUAL_adc_1_inst/clk_div] -max -add_delay 12.000 [get_ports AD_CS_1]
set_output_delay -clock [get_clocks VIRTUAL_adc_1_inst/clk_div] -min -add_delay -3.000 [get_ports AD_CS_2]
set_output_delay -clock [get_clocks VIRTUAL_adc_1_inst/clk_div] -max -add_delay 12.000 [get_ports AD_CS_2]


set_input_delay -clock [get_clocks VIRTUAL_adc_1_inst/clk_div] -min -add_delay 7.000 [get_ports AD_D0_2]
set_input_delay -clock [get_clocks VIRTUAL_adc_1_inst/clk_div] -max -add_delay 45.000 [get_ports AD_D0_2]
set_input_delay -clock [get_clocks VIRTUAL_adc_1_inst/clk_div] -min -add_delay 7.000 [get_ports AD_D1_2]
set_input_delay -clock [get_clocks VIRTUAL_adc_1_inst/clk_div] -max -add_delay 45.000 [get_ports AD_D1_2]
