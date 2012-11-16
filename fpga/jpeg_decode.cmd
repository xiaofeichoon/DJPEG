#!/bin/bash

if [ -d xilinx ]
then
rm -rf xilinx
fi
mkdir xilinx

cp jpeg_decode.xst ./xilinx
cp jpeg_decode.prj ./xilinx

cd ./xilinx
mkdir ./xst
mkdir ./xst/projnav.tmp
echo "work" > jpeg_decode.lso

xst -intstyle ise -ifn jpeg_decode.xst -ofn jpeg_decode.syr
ngdbuild -intstyle ise -dd _ngo -nt timestamp -i -p xc6slx16-ftg256-3 jpeg_decode.ngc jpeg_decode.ngd
map -intstyle ise -p xc6slx16-ftg256-3 -w -ol std -t 1 -register_duplication off -global_opt off -mt off -ir off -pr off -lc off -power off -o jpeg_decode_map.ncd jpeg_decode.ngd jpeg_decode.pcf
par -w -intstyle ise -ol std -t 1 jpeg_decode_map.ncd jpeg_decode.ncd jpeg_decode.pcf
trce -intstyle ise -e 3 -s 3 -xml jpeg_decode jpeg_decode.ncd -o jpeg_decode.twr jpeg_decode.pcf
netgen -sim -ofmt verilog -w jpeg_decode.ncd

cp ./jpeg_decode.v ../../testbench/
cp ./jpeg_decode.sdf ../../testbench/

cd ..
