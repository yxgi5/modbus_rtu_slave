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
vlog -vlog01compat -work work {./modbus_crc_tb.v}

#simulate
#vsim -novopt modbus_crc_tb
vsim -voptargs="+acc" modbus_crc_tb

add wave -radix unsigned *
add wave -radix hexadecimal /modbus_crc_tb/modbus_crc_inst0/*
#add wave -radix unsigned /modbus_crc_tb/modbus_crc_inst0/*
view structure
view signals

run 2400us

