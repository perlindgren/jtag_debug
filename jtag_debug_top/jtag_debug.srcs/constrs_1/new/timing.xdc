create_clock -period 20.000 -name DRCK -waveform {0.000 10.000} [get_pins BSCANE2_inst/DRCK]
create_clock -period 20.000 -name TCK -waveform {0.000 10.000} [get_pins BSCANE2_inst/TCK]
create_clock -period 1.000 -name virtual_clock
set_input_delay -clock [get_clocks virtual_clock] -min -add_delay 1.000 [get_ports {sw[1]}]
set_input_delay -clock [get_clocks virtual_clock] -max -add_delay 1000.000 [get_ports {sw[1]}]
set_output_delay -clock [get_clocks virtual_clock] -min -add_delay 1.000 [get_ports {led_b[0]}]
set_output_delay -clock [get_clocks virtual_clock] -max -add_delay 1000.000 [get_ports {led_b[0]}]
set_output_delay -clock [get_clocks virtual_clock] -min -add_delay 1.000 [get_ports {led_b[1]}]
set_output_delay -clock [get_clocks virtual_clock] -max -add_delay 1000.000 [get_ports {led_b[1]}]
set_output_delay -clock [get_clocks virtual_clock] -min -add_delay 1.000 [get_ports {led_b[2]}]
set_output_delay -clock [get_clocks virtual_clock] -max -add_delay 1000.000 [get_ports {led_b[2]}]
set_output_delay -clock [get_clocks virtual_clock] -min -add_delay 1.000 [get_ports {led_b[3]}]
set_output_delay -clock [get_clocks virtual_clock] -max -add_delay 1000.000 [get_ports {led_b[3]}]

set_output_delay -clock [get_clocks TCK] -min -add_delay 1000.000 [get_ports {led[2]}]
set_output_delay -clock [get_clocks TCK] -max -add_delay 1000.000 [get_ports {led[2]}]
set_output_delay -clock [get_clocks TCK] -min -add_delay 1000.000 [get_ports {led[3]}]
set_output_delay -clock [get_clocks TCK] -max -add_delay 1000.000 [get_ports {led[3]}]

