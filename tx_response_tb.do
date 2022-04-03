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
vlog -vlog01compat -work work {./tx_response_tb.v}

#simulate
#vsim -novopt tx_response_tb
vsim -voptargs="+acc" tx_response_tb

add wave -radix unsigned *
add wave -radix hexadecimal /tx_response_tb/DPRAM_inst0/RAM
add wave -radix hexadecimal /tx_response_tb/tx_response_inst0/*
view structure
view signals

run 10ms


