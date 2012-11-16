#!/bin/csh

if($#argv == 0) then
  echo Usage: run.ms IMAGENAME
  exit
endif

../../c_model/convbtoh ../../image/$argv[1].jpg test.mem 

if(-d ./work) rm -rf work

vlib work
vlog \
../fifo/fifo.v \
../pci/pci_top.v \
../pci/cmd_reg.v \
../pci/int_reg.v \
../pci/req_trans.v \
../pci/pci_cfg_decode.v \
../pci/pci_cfg_fsm.v \
../pci/pci_cfg_reg.v \
../pci/pci_cfg_space.v \
../pci/pci_cfg_target.v \
../pci/pci_check_par.v \
../pci/pci_cmdadr.v \
../pci/pci_gen_par.v \
../pci/pci_io.v \
../pci/pci_t_core.v \
../pci/pci_target_fsm.v \
../pci/if_app.v \
../../src/jpeg_decode_fsm.v \
../../src/jpeg_dht.v \
../../src/jpeg_dqt.v \
../../src/jpeg_haffuman.v \
../../src/jpeg_hm_decode.v \
../../src/jpeg_idct.v \
../../src/jpeg_idctb.v \
../../src/jpeg_idctx.v \
../../src/jpeg_idcty.v \
../../src/jpeg_regdata.v \
../../src/jpeg_ycbcr.v \
../../src/jpeg_ycbcr2rgb.v \
../../src/jpeg_ycbcr_mem.v \
../../src/jpeg_ziguzagu.v \
../../src/jpeg_ziguzagu_reg.v \
../../src/jpeg_decode.v \
../djpeg_fpga.v \
djpeg_fpga_test.v
#TEST
#-cover \


#echo "vsim -coverage -t 1ps -lib work TEST" > modelsim.fdo
echo "vsim -t 1ps -lib work TEST" > modelsim.fdo
#echo "view wave" >> modelsim.fdo
#echo "do wave.do" >> modelsim.fdo
#echo "vcd file vcd/jpeg_test.vcd" >> modelsim.fdo
#echo "vcd add -r *" >> modelsim.fdo
echo "run 100 ms" >> modelsim.fdo
echo "quit" >> modelsim.fdo

vsim -c -do modelsim.fdo
#vsim -do modelsim.fdo

../../c_model/convsim sim.dat sim.bmp 

rm -rf ./work
rm transcript
rm modelsim.fdo
