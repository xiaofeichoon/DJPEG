`timescale 1ns/10ps

module pci_cfg_decode
  (
   bar0_enable,
   bar1_enable,
   bar2_enable,
   bar3_enable,
   bar4_enable,
   bar5_enable,
   ebar_enable,
   
   adr,
   cfg_drdy,
   cmd_cfgrd,
   cmd_cfgwr,
   bar_size,
   ebar_size,
   oe_rom,
   rom_adr,
   oe_bar,
   oe_ebar,
   oe_cmdr,
   oe_intr,
   we_bar,
   we_ebar,
   we_statr,
   we_cmdr,
   we_intr
   );

   parameter   romadr_remap  = 4'b1110;
   
   input       bar0_enable;
   input       bar1_enable;
   input       bar2_enable;
   input       bar3_enable;
   input       bar4_enable;
   input       bar5_enable;
   input       ebar_enable;
   
   input [7:2]  adr;
   input        cfg_drdy;
   input        cmd_cfgrd,cmd_cfgwr;
   input [5:0]  bar_size;
   input        ebar_size;
   output       oe_rom;
   output [3:0] rom_adr;
   output [5:0] oe_bar;
   output       oe_ebar,oe_cmdr,oe_intr;
   output [5:0] we_bar;
   output       we_ebar,we_statr,we_cmdr,we_intr;

   wire [5:0]   oe_bari;
   wire         oe_ebari;
   wire         oe_cmdri;
   wire         oe_intri;
   wire         oe_bregs;
   
   function [3:0] rom_adri;
      input [7:2] adr;
      if(adr[7] == 1'b1 & adr[6] == 1'b1) rom_adri = romadr_remap;
      else rom_adri = adr[5:2];
   endfunction // rom_adri
   assign         rom_adr = rom_adri(adr);
   
   assign oe_bari[0] = bar0_enable == 1'b1 & adr[5:2] == 4'b0100 & 
                       cmd_cfgrd == 1'b1 & bar_size[0] == 1'b0 & 
                       cfg_drdy == 1'b1;
   assign oe_bari[1] = bar1_enable == 1'b1 & adr[5:2] == 4'b0101 & 
                       cmd_cfgrd == 1'b1 & bar_size[1] == 1'b0 & 
                       cfg_drdy == 1'b1;
   assign oe_bari[2] = bar2_enable == 1'b1 & adr[5:2] == 4'b0110 & 
                       cmd_cfgrd == 1'b1 & bar_size[2] == 1'b0 & 
                       cfg_drdy == 1'b1;
   assign oe_bari[3] = bar3_enable == 1'b1 & adr[5:2] == 4'b0111 & 
                       cmd_cfgrd == 1'b1 & bar_size[3] == 1'b0 & 
                       cfg_drdy == 1'b1;
   assign oe_bari[4] = bar4_enable == 1'b1 & adr[5:2] == 4'b1000 & 
                       cmd_cfgrd == 1'b1 & bar_size[4] == 1'b0 & 
                       cfg_drdy == 1'b1;
   assign oe_bari[5] = bar5_enable == 1'b1 & adr[5:2] == 4'b1001 & 
                       cmd_cfgrd == 1'b1 & bar_size[5] == 1'b0 & 
                       cfg_drdy == 1'b1;

   assign oe_ebari = ebar_enable == 1'b1 & adr[5:2] == 4'b1100 & 
                     cmd_cfgrd == 1'b1 & ebar_size == 1'b0 & cfg_drdy == 1'b1;

   assign oe_cmdri = adr[5:2] == 4'b0001 & cmd_cfgrd == 1'b1 & 
                     cfg_drdy == 1'b1;
   assign oe_intri = adr[5:2] == 4'b1111 & cmd_cfgrd == 1'b1 & 
                     cfg_drdy == 1'b1;
 
   assign oe_bar   = oe_bari;
   assign oe_ebar  = oe_ebari;
   assign oe_cmdr  = oe_cmdri;
   assign oe_intr  = oe_intri;
   
   assign oe_bregs = oe_bari[0] | oe_bari[1] | oe_bari[2] | oe_bari[3] |
                     oe_bari[4] | oe_bari[5] | oe_ebari;
   assign oe_rom = cmd_cfgrd & cfg_drdy & !(oe_bregs | oe_cmdri | oe_intri);
   
   
   assign we_bar[0] = bar0_enable == 1'b1 & adr[5:2] == 4'b0100 & 
                      cmd_cfgwr == 1'b1 & cfg_drdy == 1'b1;
   assign we_bar[1] = bar1_enable == 1'b1 & adr[5:2] == 4'b0101 & 
                      cmd_cfgwr == 1'b1 & cfg_drdy == 1'b1;
   assign we_bar[2] = bar2_enable == 1'b1 & adr[5:2] == 4'b0110 & 
                      cmd_cfgwr == 1'b1 & cfg_drdy == 1'b1;
   assign we_bar[3] = bar3_enable == 1'b1 & adr[5:2] == 4'b0111 & 
                      cmd_cfgwr == 1'b1 & cfg_drdy == 1'b1;
   assign we_bar[4] = bar4_enable == 1'b1 & adr[5:2] == 4'b1000 & 
                      cmd_cfgwr == 1'b1 & cfg_drdy == 1'b1;
   assign we_bar[5] = bar4_enable == 1'b1 & adr[5:2] == 4'b1001 & 
                      cmd_cfgwr == 1'b1 & cfg_drdy == 1'b1;
   
   assign we_ebar = ebar_enable == 1'b1 & adr[5:2] == 4'b1100 & 
                    cmd_cfgwr == 1'b1 & cfg_drdy == 1'b1;
   assign we_statr = adr[5:2] == 4'b0001 & cmd_cfgwr == 1'b1 & 
                     cfg_drdy == 1'b1;
   assign we_cmdr = adr[5:2] == 4'b0001 & cmd_cfgwr == 1'b1 &
                    cfg_drdy == 1'b1;
   assign we_intr = adr[5:2] == 4'b1111 & cmd_cfgwr == 1'b1 & 
                    cfg_drdy == 1'b1;
 

endmodule // pci_cfg_decode
