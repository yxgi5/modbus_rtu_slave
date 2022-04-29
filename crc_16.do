transcript on
#compile
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work


vlog -vlog01compat -work work {./crc_16_tb.v}
vlog -vlog01compat -work work {./crc_16.v}

#simulate
#vsim -novopt crc_16_tb
vsim -voptargs="+acc" crc_16_tb

add wave -radix hexadecimal /crc_16_tb/*
view structure
view signals

run -all


