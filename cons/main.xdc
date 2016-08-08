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