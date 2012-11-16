`timescale 1ns/10ps

module pci_io
  (
   pci_rst,
   pci_clk,       // clock
   pci_adi,       // address/data bus
   pci_ado,       // address/data bus
   pci_ado_ot,
   pci_cbei,      // command/byte enable
   pci_pari,      // parity
   pci_paro,      // parity
   pci_paro_ot,   // parity
   pci_frame_ni,  // transaction frame
   pci_irdy_ni,   // initiator ready
   pci_trdy_no,   // target ready
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
   
   adi,           // address/data bus in
   ado,           // address/data bus out
   cfg_ado,       // address/data bus out
   cbeid,         // command/byte enable registered in
   pari,
   idselid,
   frameni,
   framenid,
   irdyni,
   irdynid,
   trdynid,
   new_devselno,
   new_trdyno,
   new_stopno,
   ot_devsel,
   ot_trdy,
   ot_stop,
   ot_ad,
   ce_adodir,
   ce_adordy,
   intano,
   new_perrno,   // parity error out
   new_otperr, // parity error buffer control
   new_serrno    // system error out
   );

   input          pci_rst,pci_clk;
   input [31:0]   pci_adi;
   output [31:0]  pci_ado;
   output         pci_ado_ot;
   input [3:0]    pci_cbei;
   input          pci_pari;
   output         pci_paro;
   output         pci_paro_ot;
   input          pci_frame_ni;
   input          pci_irdy_ni;
   output         pci_trdy_no;
   output         pci_trdy_ot;
   output         pci_devsel_no;
   output         pci_devsel_ot;
   output         pci_stop_no;
   output         pci_stop_ot;
   input          pci_idseli;
   output         pci_perr_no;
   output         pci_perr_ot,pci_serr_ot;
   output         pci_inta_ot;
   
   output [31:0]  adi;
   input [31:0]   ado,cfg_ado;
   output [3:0]   cbeid;
   output         pari,idselid,frameni,framenid,irdyni,irdynid,trdynid;
   input          new_devselno,new_trdyno,new_stopno;
   input          ot_devsel,ot_trdy,ot_ad,ot_stop;
   input          ce_adodir,ce_adordy;
   input          intano;
   input          new_perrno,new_otperr,new_serrno;
   
   reg            pci_ado_ot,pci_paro_ot;
   
   wire [3:0]    cbei;
   
   reg           idselid,framenid,irdynid,trdynid;
   reg           ot_inta;
   reg [3:0]     cbeid;
   reg [31:0]    adi;

   reg           pci_trdy_no,pci_devsel_no,pci_stop_no;
   
   reg [31:0]    pci_ado;
   reg           pci_paro;
   reg           pci_perr_no,pci_perr_ot;
   reg           pci_serr_ot;

   assign        frameni = pci_frame_ni;
   assign        irdyni = pci_irdy_ni;

   assign        pci_trdy_ot = ot_trdy;
   assign        pci_stop_ot = ot_stop;
   assign        pci_devsel_ot = ot_devsel;
   
   // idsel
   always @(posedge pci_clk or negedge pci_rst) begin
      if(!pci_rst) begin
         idselid       <= 1'b0;
         framenid      <= 1'b1;
         irdynid       <= 1'b1;
         trdynid       <= 1'b1;
         pci_trdy_no   <= 1'b1;
         pci_stop_no   <= 1'b1;
         pci_devsel_no <= 1'b1;
      end else begin
         idselid       <= pci_idseli;
         framenid      <= pci_frame_ni;
         irdynid       <= pci_irdy_ni;
         trdynid       <= pci_trdy_no;
         pci_trdy_no   <= new_trdyno;
         pci_stop_no   <= new_stopno;
         pci_devsel_no <= new_devselno;
      end // else: !if(!pci_rst)
   end // always @ (posedge pci_clk or negedge pci_rst)

   always @(posedge pci_clk or negedge pci_rst) begin
      if(!pci_rst) ot_inta <= 1'b1;
      else ot_inta <= intano;
   end
   assign pci_inta_ot = ot_inta;

   assign cbei = pci_cbei;
   
   always @(posedge pci_clk or negedge pci_rst) begin
      if(!pci_rst) cbeid <= 4'b0000;
      else         cbeid <= cbei;
   end

   wire ce_adob;
   assign ce_adob = ce_adodir | (ce_adordy & ~pci_irdy_ni);

   always @(posedge pci_clk or negedge pci_rst) begin
      if(!pci_rst) adi <= 32'h00000000;
      else         adi <= pci_adi;
   end

   always @(posedge pci_clk or negedge pci_rst) begin
      if(!pci_rst) pci_ado <= 32'h00000000;
      else 
        if(ce_adob == 1'b1) pci_ado <= ado | cfg_ado;
   end
   
   always @(posedge pci_clk or negedge pci_rst) begin
      if(!pci_rst) pci_ado_ot <= 1'b1;
      else         pci_ado_ot <= ot_ad;
   end

   always @(posedge pci_clk or negedge pci_rst) begin
      if(!pci_rst) pci_paro_ot <= 1'b1;
      else         pci_paro_ot <= ot_ad;
   end

   wire parout;
   pci_gen_par _pci_gen_par(
                            .rst(!pci_rst),
                            .clk(pci_clk),
                            .ce_ado(ce_adob),
                            .ado(ado),
                            .cbei(cbei),
                            .new_paro(parout)
                            );
   
   always @(posedge pci_clk or negedge pci_rst) begin
      if(!pci_rst) pci_paro <= 1'b0;
      else         pci_paro <= parout;
   end

   assign pari = pci_pari;

   always @(posedge pci_clk or negedge pci_rst) begin
      if(!pci_rst) begin
         pci_perr_no <= 1'b0;
         pci_perr_ot <= 1'b1;
         pci_serr_ot <= 1'b1;
      end else begin
         pci_perr_no <= new_perrno;
         pci_perr_ot <= new_otperr;
         pci_serr_ot <= new_serrno;
         
      end
   end // always @ (posedge pci_clk or negedge pci_rst)

endmodule // pci_io
