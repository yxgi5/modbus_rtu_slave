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
vlog -vlog01compat -work work {./frame_rx_tb.v}

#simulate
#vsim -novopt frame_rx_tb
vsim -voptargs="+acc" frame_rx_tb

add wave -radix unsigned *
add wave -position insertpoint sim:/frame_rx_tb/FRAME
add wave -radix hexadecimal /frame_rx_tb/frame_rx_inst0/*
#add wave -radix unsigned /frame_rx_tb/frame_rx_inst0/*
view structure
view signals

run 2300us
