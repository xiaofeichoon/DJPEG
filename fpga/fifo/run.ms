#!/bin/csh

if(-d ./work) rm -rf work

vlib work
vlog \
fifo.v \
testbench.v

echo "vsim -t 1ps -lib work test" > modelsim.fdo
echo "run 100 ms" >> modelsim.fdo
echo "quit" >> modelsim.fdo

vsim -c -do modelsim.fdo

rm -rf ./work
rm transcript
rm modelsim.fdo
