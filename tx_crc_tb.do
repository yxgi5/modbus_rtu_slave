transcript on
#compile
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

#vcom -2008 -work work {./*.vhd}
#vlog -vlog01compat -work work {./uart_byte_tx.v}
#vlog -vlog01compat -work work {./modbus_crc.v}
vlog -vlog01compat -work work {./DPRAM.v}
vlog -vlog01compat -work work {./tx_crc.v}
vlog -vlog01compat -work work {./tx_crc_tb.v}

#simulate
#vsim -novopt tx_crc_tb
vsim -voptargs="+acc" tx_crc_tb

add wave -radix unsigned *
add wave -radix hexadecimal /tx_crc_tb/tx_crc_inst0/*
add wave -radix hexadecimal /tx_crc_tb/DPRAM_inst0/RAM
view structure
view signals

run 2400us


