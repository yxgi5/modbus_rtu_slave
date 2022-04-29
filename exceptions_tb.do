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
vlog -vlog01compat -work work {./exceptions_tb.v}

#simulate
#vsim -novopt exceptions_tb
vsim -voptargs="+acc" exceptions_tb

add wave -radix unsigned *
add wave -radix hexadecimal /exceptions_tb/exceptions_inst0/*
#add wave -radix unsigned /exceptions_tb/exceptions_inst0/*
view structure
view signals

run 2400us

