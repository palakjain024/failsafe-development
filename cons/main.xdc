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

set_property PACKAGE_PIN T6 [get_ports {FI_flag[0]} ]
set_property IOSTANDARD LVCMOS33 [ get_ports {FI_flag[0]} ]

set_property PACKAGE_PIN T4 [get_ports {FI_flag[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FI_flag[1]}]

set_property PACKAGE_PIN U4 [ get_ports {FI_flag[2]} ]
set_property IOSTANDARD LVCMOS33 [ get_ports {FI_flag[2]} ]

set_property PACKAGE_PIN G22 [get_ports reset_fd]
set_property IOSTANDARD LVCMOS33 [get_ports reset_fd]

# Digilent PMOD DA21 DAC to PMOD JA1 to JA4 (For theta L and C)
set_property PACKAGE_PIN Y11 [get_ports DA_nSYNC_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_nSYNC_1]

set_property PACKAGE_PIN AA11 [get_ports DA_DATA1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA1]

set_property PACKAGE_PIN Y10 [get_ports DA_DATA2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA2]

set_property PACKAGE_PIN AA9 [get_ports DA_CLK_OUT_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_CLK_OUT_1]

# Digilent PMOD DA21 DAC to PMOD JA7 to JA10 (For theta SW and norm)
set_property PACKAGE_PIN AB11 [get_ports DA_nSYNC_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_nSYNC_2]

set_property PACKAGE_PIN AB10 [get_ports DA_DATA3]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA3]

set_property PACKAGE_PIN AB9 [get_ports DA_DATA4]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA4]

set_property PACKAGE_PIN AA8 [get_ports DA_CLK_OUT_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_CLK_OUT_2]

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



