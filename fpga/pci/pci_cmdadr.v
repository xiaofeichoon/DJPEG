`timescale 1ns/10ps

module pci_cmdadr
  (
   rst,
   clk,
   adi,
   cbeid,
   idselid,
   framenid,
   inc_adr,   // incement address counter
   first_cyc, // first cycle after frame# falling edge
   adr,       // captuerd address
   t_cmd,     // binary encoded command
   acc_end,   // 
   acc_cfg,   // configuration space access
   acc_io,    // i/o space access
   acc_mem,   // memory space access
   acc_rd,    // read access
   acc_wr,    // write access
   cfg_ioen,  // i/o space decoding enable
   cfg_memen, // memory space decoding enable
   cmd_cfgrd, // configuration read
   cmd_cfgwr  // configuration write
   );
   input rst,clk;
   input [31:0] adi;
   input [3:0]  cbeid;
   input        idselid;
   input        framenid;
   input        inc_adr;
   output       first_cyc;
   output [31:0] adr;
   output [3:0]  t_cmd;
   input         acc_end;
   output        acc_cfg,acc_io,acc_mem,acc_rd,acc_wr;
   input         cfg_ioen,cfg_memen;
   output        cmd_cfgrd,cmd_cfgwr;

   // Command Parameter
   parameter     IACK_CODE  = 4'b0000;
   parameter     SCYC_CODE  = 4'b0001;
   parameter     IORD_CODE  = 4'b0010;
   parameter     IOWR_CODE  = 4'b0011;
   parameter     RES4_CODE  = 4'b0100;
   parameter     RES5_CODE  = 4'b0101;
   parameter     MRD_CODE   = 4'b0110;
   parameter     MWR_CODE   = 4'b0111;
   parameter     RES8_CODE  = 4'b1000;
   parameter     RES9_CODE  = 4'b1001;
   parameter     CFGRD_CODE = 4'b1010;
   parameter     CFGWR_CODE = 4'b1011;
   parameter     MRM_CODE   = 4'b1100;
   parameter     DUAL_CODE  = 4'b1101;
   parameter     MRL_CODE   = 4'b1110;
   parameter     MWI_CODE   = 4'b1111;

   reg           oldframe;
   reg [31:0]    adri;
   wire [31:0]   adr;
   reg [3:0]     t_cmd;
   reg           cmd_cfgrd,cmd_cfgwr;
   
   reg           acc_rd,acc_wr;
   wire          first_cyc;
   
   // 
   always @(posedge clk or negedge rst) begin
      if(!rst) oldframe <= 1'b1;
      else     oldframe <= framenid;
   end

   // beginning pci access cycle detection
   assign first_cyc = oldframe & ~(framenid);
   // cfg space access decode
   assign acc_cfg = adi[1:0] == 2'b00 & cbeid[3:1] == 3'b101 & 
                    idselid == 1'b1 & first_cyc == 1'b1;
   // i/o space access
   assign acc_io = cfg_ioen == 1'b1 & cbeid[3:1] == 3'b001;
   // memory space access
   assign acc_mem = cfg_memen == 1'b1 & (cbeid[3:1] == 3'b011 |
                                         cbeid[3:1] == 3'b111 |
                                         cbeid[3:0] == 4'b1100);

   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         acc_rd <= 1'b0;
         acc_wr <= 1'b0;
      end else begin
         if(acc_end == 1'b1) begin
            acc_rd <= 1'b0;
            acc_wr <= 1'b0;
         end else if (first_cyc == 1'b1) begin
            acc_rd <= ~(cbeid[0]);
            acc_wr <= cbeid[0];
         end
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)

   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         cmd_cfgrd <= 1'b0;
         cmd_cfgwr <= 1'b0;
         t_cmd <= 4'b1000;
      end else begin
         if(acc_end == 1'b1) begin
            t_cmd <= 4'b1000;
            cmd_cfgrd <= 1'b0;
            cmd_cfgwr <= 1'b0;
         end else if(first_cyc == 1'b1) begin
            t_cmd <= cbeid;
            if(cbeid == CFGRD_CODE) cmd_cfgrd <= 1'b1;
            else cmd_cfgrd <= 1'b0;
            if(cbeid == CFGWR_CODE) cmd_cfgwr <= 1'b1;
            else cmd_cfgwr <= 1'b0;
         end
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         adri <= 32'h00000000;
      end else begin
         if(first_cyc == 1'b1) adri[31:2] <= adi[31:2];
         else adri <= adr;
      end
   end

   assign adr = (inc_adr == 1'b1)?adri + 32'h00000004 : adri;
   
endmodule // pci_cmdadr
