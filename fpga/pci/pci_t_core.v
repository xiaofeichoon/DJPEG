`timescale 1ns/10ps

module pci_t_core
  (
   // pci-bus interface signals
   pci_rst,    // reset
   pci_clk,      // clock
   pci_adi,      // address/data bus
   pci_ado,     // address/data bus
   pci_ado_ot,
   pci_cbei,     // command/byte enable
   pci_pari,     // parity
   pci_paro,     // parity
   pci_paro_ot,  // parity
   pci_frame_ni, // transaction frame
   pci_irdy_ni,  // initiator ready
   pci_trdy_no,  // target ready
   pci_trdy_ot,
   pci_devsel_no, // device select
   pci_devsel_ot,
   pci_stop_no,   // stop transaction
   pci_stop_ot,
   pci_idseli,    // device select
   pci_perr_no,   // parity error
   pci_perr_ot,   // parity error
   pci_serr_ot,   // system error
   pci_inta_ot,   // interrupt pin
   
   // application interface signals
   app_adr,      // address bus
   app_adi,      // data in  (pci -> app)
   app_ado,      // data out (app -> pci)
   app_int_n,    // applicatoin interrupt signal
   t_barhit,     // bar hit signal
   t_ebarhit,    // expansion rom bar hit signal
   t_cmd,
   t_be_n,       // byte enable
   t_rd,         // target operation is read
   t_wr,         // target operation is write
   t_we,         // target write enable
   t_nextd,      // target next data
   t_drdy,       // target application ready to read/write data
   t_term,       // target termination request(retry/disconnect)
   t_abort       // target abort request
   );

   input         pci_rst;
   input 	 pci_clk;
   input [31:0]  pci_adi;
   output [31:0] pci_ado;
   output        pci_ado_ot;
   input [3:0] 	 pci_cbei;
   input 	 pci_pari;
   output 	 pci_paro;
   output        pci_paro_ot;
   input 	 pci_frame_ni;
   input 	 pci_irdy_ni;
   output 	 pci_trdy_no;
   output 	 pci_trdy_ot;
   output 	 pci_devsel_no;
   output 	 pci_devsel_ot;
   output 	 pci_stop_no;
   output 	 pci_stop_ot;
   input 	 pci_idseli;
   output 	 pci_perr_no;
   output 	 pci_perr_ot,pci_serr_ot;
   output 	 pci_inta_ot;
   
   output [31:0] app_adr;
   output [31:0] app_adi;
   input [31:0]  app_ado;
   input         app_int_n;
   output [5:0]  t_barhit;
   output        t_ebarhit;
   output [3:0]  t_be_n;
   output [3:0]  t_cmd;
   output        t_rd;
   output        t_wr;
   output        t_we;
   output        t_nextd;
   input 	 t_drdy;
   input 	 t_term;
   input 	 t_abort;
   
   // internal signals
   wire [31:0]   adi,adr,cfg_ado;
   wire [3:0]    cbeid;
   wire          frameni,framenid;
   wire          irdyni,irdynid;
   wire          trdynid;
   wire          idselid;
   wire          pari;
   wire          new_devselno,new_trdyno;
   wire          ot_devsel,ot_trdy,ot_stop,ot_ad;
   wire          ce_adodir,ce_adordy;
   wire          new_perrno,new_serrno,new_otperr,new_stopno;
   wire          cfg_drdy,card_hit,cfg_sent;
   wire          acc_end,acc_wr,acc_rd,acc_cfg,acc_io,acc_mem;
   wire          first_cyc;
   wire          inc_adr;
   wire 	 cmd_cfgrd,cmd_cfgwr;
   wire          cfg_ioen,cfg_memen;
   wire          perr_en,serr_en;
//   wire          set_mdperr;
   wire          target_act,sig_serr,det_perr;

   wire [3:0]    t_be_n,pci_cbei;
   wire [31:0]   pci_adi,pci_ado;

   // wire spec_cyc,stepping_en;
   
   assign        app_adi = adi;
   assign        app_adr = adr;

   assign        t_be_n = cbeid;

   pci_io io_module
     (
      .pci_rst(pci_rst),
      .pci_clk(pci_clk),
      .pci_adi(pci_adi),
      .pci_ado(pci_ado),
      .pci_ado_ot(pci_ado_ot),
      .pci_cbei(pci_cbei),
      .pci_pari(pci_pari),
      .pci_paro(pci_paro),
      .pci_paro_ot(pci_paro_ot),
      .pci_frame_ni(pci_frame_ni),
      .pci_irdy_ni(pci_irdy_ni),
      .pci_trdy_no(pci_trdy_no),
      .pci_trdy_ot(pci_trdy_ot),
      .pci_devsel_no(pci_devsel_no),
      .pci_devsel_ot(pci_devsel_ot),
      .pci_stop_no(pci_stop_no),
      .pci_stop_ot(pci_stop_ot),
      .pci_idseli(pci_idseli),
      .pci_perr_no(pci_perr_no),
      .pci_perr_ot(pci_perr_ot),
      .pci_serr_ot(pci_serr_ot),
      .pci_inta_ot(pci_inta_ot),
      
      .adi(adi),
      .ado(app_ado),
      .cfg_ado(cfg_ado),
      .cbeid(cbeid),
      .pari(pari),
      .idselid(idselid),
      .frameni(frameni),
      .framenid(framenid),
      .irdyni(irdyni),
      .irdynid(irdynid),
      .trdynid(trdynid),
      .new_devselno(new_devselno),
      .new_trdyno(new_trdyno),
      .new_stopno(new_stopno),
      .ot_devsel(ot_devsel),
      .ot_trdy(ot_trdy),
      .ot_stop(ot_stop),
      .ot_ad(ot_ad),
      .ce_adodir(ce_adodir),
      .ce_adordy(ce_adordy),
      .intano(app_int_n),
      .new_perrno(new_perrno),
      .new_otperr(new_otperr),
      .new_serrno(new_serrno)
      );
   
   pci_target_fsm target_fsm_module
     (
      .rst(pci_rst),
      .clk(pci_clk),
      .frameni(frameni),
      .framenid(framenid),
      .irdyni(irdyni),
      .irdynid(irdynid),
      .trdynid(trdynid),
      .card_hit(card_hit),
      .t_drdy(t_drdy),
      .cfg_drdy(cfg_drdy),
      .t_term(t_term),
      .t_abort(t_abort),
      .acc_wr(acc_wr),
      .acc_rd(acc_rd),
      .new_devselno(new_devselno),
      .new_trdyno(new_trdyno),
      .new_stopno(new_stopno),
      .ce_adodir(ce_adodir),
      .ce_adordy(ce_adordy),
      .ot_ad(ot_ad),
      .ot_trdy(ot_trdy),
      .ot_stop(ot_stop),
      .ot_devsel(ot_devsel),
      .acc_end(acc_end),
      .cfg_sent(cfg_sent),
      .inc_adr(inc_adr),
      .t_nextd(t_nextd),
      .t_we(t_we),
      .t_wr(t_wr),
      .t_rd(t_rd)
      );
   
   pci_cmdadr command_address
     (
      .rst(pci_rst),
      .clk(pci_clk),
      .adi(adi),
      .cbeid(cbeid),
      .idselid(idselid),
      .framenid(framenid),
      .inc_adr(inc_adr),
      .first_cyc(first_cyc),
      .adr(adr),
      .t_cmd(t_cmd),
      .acc_end(acc_end),
      .acc_cfg(acc_cfg),
      .acc_io(acc_io),
      .acc_mem(acc_mem),
      .acc_rd(acc_rd),
      .acc_wr(acc_wr),
      .cfg_ioen(cfg_ioen),
      .cfg_memen(cfg_memen),
      .cmd_cfgrd(cmd_cfgrd),
      .cmd_cfgwr(cmd_cfgwr)
      );
   
   pci_cfg_space config_space
     (
      .rst(pci_rst),
      .clk(pci_clk),
      
      .adi(adi),
      .cfg_ado(cfg_ado),
      
      .adr(adr[7:2]),
      .cbeid(cbeid),
      .cmd_cfgrd(cmd_cfgrd),
      .cmd_cfgwr(cmd_cfgwr),
      .acc_end(acc_end),
      .acc_cfg(acc_cfg),
      .acc_io(acc_io),
      .acc_mem(acc_mem),
      .cfg_sent(cfg_sent),
      .first_cyc(first_cyc),
      
//      .set_mdperr(set_mdperr),
//      .sig_tabort(t_abort),
//      .rcv_tabort(rcv_tabort),
//      .rcv_mabort(rcv_mabort),
      .sig_serr(sig_serr),
      .det_perr(det_perr),
      
      .cfg_drdy(cfg_drdy),
      .card_hit(card_hit),
      .target_act(target_act),
      .t_barhit(t_barhit),
      .t_ebarhit(t_ebarhit),
      .t_abort(t_abort),
      
      .cfg_ioen(cfg_ioen),
      .cfg_memen(cfg_memen),
//      .spec_cyc(spec_cyc),
      .perr_en(perr_en),
//      .stepping_en(stepping_en),
      .serr_en(serr_en)
      );
   
   pci_check_par check_parity
     (
      .rst(pci_rst),
      .clk(pci_clk),
      .adi(adi),
      .cbeid(cbeid),
      .first_cyc(first_cyc),
      .irdynid(irdynid),
      .acc_wr(acc_wr),
      .pari(pari),
      .perr_en(perr_en),
      .serr_en(serr_en),
      .target_act(target_act),
      .new_perrno(new_perrno),
      .new_otperr(new_otperr),
      .new_serrno(new_serrno),
      .sig_serr(sig_serr),
      .det_perr(det_perr)
      );

endmodule // pci_t_core
