create_clock -period 10.0 [get_ports sysclk]

# Mapping system clock
set_property PACKAGE_PIN Y9 [get_ports sysclk]
set_property IOSTANDARD LVCMOS33 [get_ports sysclk]

#----- For fault management -----

# SW F22 s not working at create zedboard
# Also decrease the jtag speed when use ila core

## For reseting PWM
set_property PACKAGE_PIN G22 [get_ports pwm_reset]
set_property IOSTANDARD LVCMOS33 [get_ports pwm_reset]

## For enabling the state estimator and Fault detection and identification
set_property PACKAGE_PIN H22 [get_ports enable_fdi]
set_property IOSTANDARD LVCMOS33 [get_ports enable_fdi]

# For reseting faults
set_property PACKAGE_PIN F21 [get_ports reset_fd]
set_property IOSTANDARD LVCMOS33 [get_ports reset_fd]

## ------------ Sensor Fault injection --------------------------##
### Mapping of fault injection Switch H19: Vc
set_property PACKAGE_PIN H19 [get_ports f1_h19]
set_property IOSTANDARD LVCMOS33 [get_ports f1_h19]

### Mapping of fault injection Switch H18 : Iload
set_property PACKAGE_PIN H18 [get_ports f2_h18]
set_property IOSTANDARD LVCMOS33 [get_ports f2_h18]

### Mapping of fault injection Switch H17: Vpv
set_property PACKAGE_PIN H17 [get_ports f3_h17]
set_property IOSTANDARD LVCMOS33 [get_ports f3_h17]

## MApping of fault type f1, f2, f3 see main_loop for details
## Mapping of f1 on LD0
set_property PACKAGE_PIN T22 [get_ports LD_f1]
set_property IOSTANDARD LVCMOS33 [get_ports LD_f1]

## Mapping of f2 on LD1
set_property PACKAGE_PIN T21 [get_ports LD_f2]
set_property IOSTANDARD LVCMOS33 [get_ports LD_f2]

## Mapping of f3 on LD2
set_property PACKAGE_PIN U22 [get_ports LD_f3]
set_property IOSTANDARD LVCMOS33 [get_ports LD_f3]
## ---------------------------------------------##

#### Mapping of FD and FI flag ####
#JA7 AB11
set_property PACKAGE_PIN AB11 [get_ports FD_flag]
set_property IOSTANDARD LVCMOS33 [get_ports FD_flag]

#JA8 (AB10), JA9(AB9), JA10(AA8) for fault identification

#-----------------------------------#

# ----- For Controller ------

#Mapping PWM module phase a to PMOD JC1_p (AB7) and JC3_p (R6)
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

#--------------------------------


# ----- For Inputs through ADCs ------

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

 #Digilent PMOD AD1_3 ADC to PMOD JB7 to JB10 (For adc_5 and adc_6)
set_property PACKAGE_PIN V12 [get_ports AD_CS_3]
set_property IOSTANDARD LVCMOS33 [get_ports AD_CS_3]

set_property PACKAGE_PIN W10 [get_ports AD_D0_3]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D0_3]

set_property PACKAGE_PIN V9 [get_ports AD_D1_3]
set_property IOSTANDARD LVCMOS33 [get_ports AD_D1_3]

set_property PACKAGE_PIN V8 [get_ports AD_SCK_3]
set_property IOSTANDARD LVCMOS33 [get_ports AD_SCK_3]

#--------------------------------

# ----- For Outputs through DACs ------

# Digilent PMOD DA1_1 DAC to PMOD JD1_P to JD2_N (For dac_1 and dac_2)
set_property PACKAGE_PIN V7 [get_ports DA_nSYNC_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_nSYNC_1]

set_property PACKAGE_PIN W7 [get_ports DA_DATA1_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA1_1]

set_property PACKAGE_PIN V5 [get_ports DA_DATA2_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA2_1]

set_property PACKAGE_PIN V4 [get_ports DA_CLK_OUT_1]
set_property IOSTANDARD LVCMOS33 [get_ports DA_CLK_OUT_1]

# Digilent PMOD DA1_2 DAC to PMOD JD3_P to JD4_N (For dac_3 and dac_4)
set_property PACKAGE_PIN W6 [get_ports DA_nSYNC_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_nSYNC_2]

set_property PACKAGE_PIN W5 [get_ports DA_DATA1_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA1_2]

set_property PACKAGE_PIN U6 [get_ports DA_DATA2_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_DATA2_2]

set_property PACKAGE_PIN U5 [get_ports DA_CLK_OUT_2]
set_property IOSTANDARD LVCMOS33 [get_ports DA_CLK_OUT_2]

#---------------------------------