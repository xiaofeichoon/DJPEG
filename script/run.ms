#!/bin/bash

if [ $# == 0 ]
then
  echo Usage: run.ms IMAGENAME
  exit
fi

../c_model/convbtoh ../image/$1.jpg test.mem

if [ -d ./work ]
then
  rm -rf work
fi

vlib work
vlog \
-cover \
jpeg_test \
../src/jpeg_regdata.v \
../src/jpeg_ziguzagu.v \
../src/jpeg_dqt.v \
../src/jpeg_dht.v \
../src/jpeg_hm_decode.v \
../src/jpeg_huffman.v \
../src/jpeg_idctb.v \
../src/jpeg_idct_calc.v \
../src/jpeg_idct.v \
../src/jpeg_ycbcr_mem.v \
../src/jpeg_ycbcr2rgb.v \
../src/jpeg_ycbcr.v \
../src/jpeg_decode_fsm.v \
../src/jpeg_decode.v \
jpeg_test.v

#echo "vsim -coverage -t 1ps -lib work jpeg_test" > modelsim.fdo
echo "vsim -t 1ps -lib work jpeg_test" > modelsim.fdo
#echo "view wave" >> modelsim.fdo
#echo "do wave.do" >> modelsim.fdo
#echo "vcd file vcd/jpeg_test.vcd" >> modelsim.fdo
#echo "vcd add -r *" >> modelsim.fdo
echo "run 50 ms" >> modelsim.fdo
#echo "run -all" >> modelsim.fdo
#echo "coverage report -file report.txt -byfile -select {s b c}" >> modelsim.fdo
#echo "coverage save cov_"$argv[1]".cov" >> modelsim.fdo
echo "quit" >> modelsim.fdo

vsim -c -do modelsim.fdo
#vsim -do modelsim.fdo

#echo "coverage report -file report.txt -byfile -select {s b c}" > modelsim.fdo
#echo "coverage save cov_"$argv[1]".cov" >> modelsim.fdo
#echo "quit" >> modelsim.fdo
#vsim -c -do modelsim.fdo

../c_model/convsim sim.dat sim.bmp
mv sim.bmp out_$1.bmp
mv sim.cov cov_$1.cov

vcover merge all.cov cov_*.cov
vcover report -output report.txt all.cov
#vcover report -details -file report_detial.txt all.cov
vcover report -zero -output report_zero.txt all.cov

rm -rf ./work
rm transcript
rm modelsim.fdo
rm vsim.wlf

