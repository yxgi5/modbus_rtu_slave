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
vlog -vlog01compat -work work {./ct_15t_gen.v}
vlog -vlog01compat -work work {./ct_15t_gen_tb.v}

#simulate
#vsim -novopt ct_15t_gen_tb
vsim -voptargs="+acc" ct_15t_gen_tb

add wave -radix unsigned *
#add wave -radix hexadecimal /ct_15t_gen_tb/ct_15t_gen_inst0/*
add wave -radix unsigned /ct_15t_gen_tb/ct_15t_gen_inst0/*
view structure
view signals


run 1500us
