transcript on
#compile
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

#vcom -2008 -work work {./*.vhd}
vlog -vlog01compat -work work {./uart_byte_tx.v}
vlog -vlog01compat -work work {./uart_byte_rx.v}
vlog -vlog01compat -work work {./ct_35t_gen.v}
vlog -vlog01compat -work work {./ct_15t_gen.v}
vlog -vlog01compat -work work {./frame_rx.v}
vlog -vlog01compat -work work {./modbus_crc.v}
vlog -vlog01compat -work work {./exceptions.v}
vlog -vlog01compat -work work {./DPRAM.v}
vlog -vlog01compat -work work {./func_handler.v}
vlog -vlog01compat -work work {./tx_handler.v}
vlog -vlog01compat -work work {./tx_response.v}
vlog -vlog01compat -work work {./modbus_rtu_slave_top.v}
vlog -vlog01compat -work work {./modbus_rtu_slave_top_tb.v}

#simulate
#vsim -novopt modbus_rtu_slave_top_tb
vsim -voptargs="+acc" modbus_rtu_slave_top_tb

add wave -radix unsigned *
add wave -radix hexadecimal /modbus_rtu_slave_top_tb/modbus_rtu_slave_top_inst0/*
add wave -radix hexadecimal /modbus_rtu_slave_top_tb/modbus_rtu_slave_top_inst0/uart_byte_rx_inst0/*
view structure
view signals

run 10ms


