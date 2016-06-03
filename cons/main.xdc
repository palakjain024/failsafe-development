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


# Timing constraints
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]
set_output_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports {pwm_n_out_t[0]}]
set_output_delay -clock [get_clocks clk] -max -add_delay -2.000 [get_ports {pwm_n_out_t[0]}]
set_output_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports {pwm_out_t[0]}]
set_output_delay -clock [get_clocks clk] -max -add_delay -2.000 [get_ports {pwm_out_t[0]}]






set_input_delay -clock [get_clocks clk] -min -add_delay 0.000 [get_ports pwm_f]
set_input_delay -clock [get_clocks clk] -max -add_delay -4.000 [get_ports pwm_f]
