transcript on
#compile
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

#vcom -2008 -work work {./uart_byte_tx.vhd}
vlog -vlog01compat -work work {./uart_byte_tx.v}
vlog -vlog01compat -work work {./uart_byte_tx_tb.v}


#simulate
#vsim -novopt uart_byte_tx_tb
vsim -voptargs="+acc" uart_byte_tx_tb

add wave -radix unsigned *
add wave -radix hexadecimal /uart_byte_tx_tb/uart_byte_tx_inst0/*
#add wave -radix unsigned /uart_byte_tx_tb/uart_byte_tx_inst0/*
view structure
view signals


run 25ms
