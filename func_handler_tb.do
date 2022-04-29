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
vlog -vlog01compat -work work {./modbus_crc_16.v}
vlog -vlog01compat -work work {./crc_16.v}
vlog -vlog01compat -work work {./exceptions.v}
vlog -vlog01compat -work work {./DPRAM.v}
vlog -vlog01compat -work work {./func_handler.v}
vlog -vlog01compat -work work {./func_handler_tb.v}

#simulate
#vsim -novopt func_handler_tb
vsim -voptargs="+acc" func_handler_tb

add wave -radix unsigned *
add wave -radix hexadecimal /func_handler_tb/DPRAM_inst0/RAM
add wave -radix hexadecimal /func_handler_tb/func_handler_inst0/*
add wave -radix hexadecimal /func_handler_tb/exceptions_inst0/*
#add wave -radix unsigned /func_handler_tb/exceptions_inst0/*
view structure
view signals

run 6ms


