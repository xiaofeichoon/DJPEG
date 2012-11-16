`timescale 1ns/10ps

module pci_cfg_space
  (
   rst,
   clk,

   adi,
   cfg_ado,

   adr,
   cbeid,
   cmd_cfgrd,
   cmd_cfgwr,
   acc_end,
   acc_cfg,
   acc_io,
   acc_mem,
   cfg_sent,
   first_cyc,

//   set_mdperr,
//   sig_tabort,
//   rcv_tabort,
//   rcv_mabort,
   sig_serr,
   det_perr,

   cfg_drdy,
   card_hit,
   target_act,
   t_barhit,
   t_ebarhit,
   t_abort,

   cfg_ioen,
   cfg_memen,
//   spec_cyc,
   perr_en,
//   stepping_en,
   serr_en
   );

   input         rst,clk;
   input [31:0]  adi;
   output [31:0] cfg_ado;
   input [7:2] 	 adr;
   input [3:0]   cbeid;
   input         cmd_cfgrd,cmd_cfgwr;
   input         acc_end,acc_cfg,acc_io,acc_mem;
   input         cfg_sent;
   input         first_cyc;
// input         set_mdperr;
// input         sig_tabort,rcv_tabort,rcv_mabort,sig_serr,det_perr;
   input         sig_serr,det_perr;
   output        cfg_drdy,card_hit,target_act;
   output [5:0]  t_barhit;
   output        t_ebarhit;
   input         t_abort;
   output        cfg_ioen,cfg_memen,perr_en,serr_en;
// output stepping_en;
// output        spec_cyc;

   wire [5:0]    bar_hit,bar_size,oe_bar;
   wire [3:0]    rom_adr;
   wire          oe_rom;

   wire          ebar_size,oe_ebar,oe_cmdr,oe_intr;
   wire [5:0]    we_bar;
   wire          we_ebar,we_cmdr,we_statr,we_intr;
   wire          ebar_hit;
   wire          det_perr;

   // Config Line
   wire           bar0_enable;
   wire           bar1_enable;
   wire           bar2_enable;
   wire           bar3_enable;
   wire           bar4_enable;
   wire           bar5_enable;
   wire           ebar_enable;

   pci_cfg_decode cfg_decode
     (
      .bar0_enable(bar0_enable),
      .bar1_enable(bar1_enable),
      .bar2_enable(bar2_enable),
      .bar3_enable(bar3_enable),
      .bar4_enable(bar4_enable),
      .bar5_enable(bar5_enable),
      .ebar_enable(ebar_enable),
      
      .adr(adr[7:2]),
      .cfg_drdy(cfg_drdy),
      .cmd_cfgrd(cmd_cfgrd),
      .cmd_cfgwr(cmd_cfgwr),
      .bar_size(bar_size),
      .ebar_size(ebar_size),
      .oe_rom(oe_rom),
      .rom_adr(rom_adr),
      .oe_bar(oe_bar),
      .oe_ebar(oe_ebar),
      .oe_cmdr(oe_cmdr),
      .oe_intr(oe_intr),
      .we_bar(we_bar),
      .we_ebar(we_ebar),
      .we_statr(we_statr),
      .we_cmdr(we_cmdr),
      .we_intr(we_intr)
      );
   
   pci_cfg_target cfg_target
     (
      .rst(rst),
      .clk(clk),
      .first_cyc(first_cyc),
      .acc_cfg(acc_cfg),
      .acc_end(acc_end),
      .bar_hit(bar_hit),
      .ebar_hit(ebar_hit),
      .target_act(target_act),
      .card_hit(card_hit),
      .t_barhit(t_barhit),
      .t_ebarhit(t_ebarhit)
      );

   pci_cfg_fsm cfg_fsm
     (
      .rst(rst),
      .clk(clk),
      .acc_cfg(acc_cfg),
      .cfg_sent(cfg_sent),
      .cfg_drdy(cfg_drdy)
      );

   pci_cfg_reg cfg_reg
     (
      // Config
      .bar0_enable(bar0_enable),
      .bar1_enable(bar1_enable),
      .bar2_enable(bar2_enable),
      .bar3_enable(bar3_enable),
      .bar4_enable(bar4_enable),
      .bar5_enable(bar5_enable),
      .ebar_enable(ebar_enable),
   
      .rst(rst),
      .clk(clk),
      .adi(adi),
      .cbeid(cbeid),
      .rom_adr(rom_adr),
      .oe_rom(oe_rom),
      .oe_bar(oe_bar),
      .oe_ebar(oe_ebar),
      .oe_cmdr(oe_cmdr),
      .oe_intr(oe_intr),
      .we_bar(we_bar),
      .we_ebar(we_ebar),
      .we_statr(we_statr),
      .we_cmdr(we_cmdr),
      .we_intr(we_intr),
      .t_abort(t_abort),
//      .set_mdperr(set_mdperr),
      .sig_serr(sig_serr),
      .det_perr(det_perr),
      .first_cyc(first_cyc),
      .acc_io(acc_io),
      .acc_mem(acc_mem),
      
      .bar_hit(bar_hit),
      .ebar_hit(ebar_hit),
      .bar_size(bar_size),
      .ebar_size(ebar_size),
      
      .cfg_ado(cfg_ado),
      
      .cfg_ioen(cfg_ioen),
      .cfg_memen(cfg_memen),
      
      .perr_en(perr_en),
      .serr_en(serr_en)
      );

endmodule // pci_cfg_space
