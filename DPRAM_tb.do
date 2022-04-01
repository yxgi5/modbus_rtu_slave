transcript on
#compile
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

#vcom -2008 -work work {./DPRAM.vhd}
vlog -vlog01compat -work work {./DPRAM.v}
vlog -vlog01compat -work work {./DPRAM_tb.v}

#simulate
vsim -novopt DPRAM_tb

#probe signals
add wave -radix unsigned *
add wave -radix unsigned /DPRAM_tb/UUT/*
add wave -radix unsigned /DPRAM_tb/UUT/RAM

view structure
view signals

#300 ns

run 500ns
