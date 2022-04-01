transcript on
#compile
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

#vcom -2008 -work work {./*.vhd}
vlog -vlog01compat -work work {./uart_byte_tx.v}
#vlog -vlog01compat -work work {./modbus_crc.v}
vlog -vlog01compat -work work {./DPRAM.v}
vlog -vlog01compat -work work {./response.v}
vlog -vlog01compat -work work {./response_tb.v}

#simulate
#vsim -novopt response_tb
vsim -voptargs="+acc" response_tb

add wave -radix unsigned *
add wave -radix hexadecimal /response_tb/response_inst0/*
add wave -radix hexadecimal /response_tb/response_inst0/uart_byte_tx_inst0/*
add wave -radix hexadecimal /response_tb/DPRAM_inst0/RAM
#add wave -radix unsigned /response_tb/response_inst0/*
view structure
view signals

run 2400us


