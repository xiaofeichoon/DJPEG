`timescale 1ns/10ps

module cmd_reg
  (
   rst,         // Reset from Interface

   pci_clk,   // Clock from Interface
   cmd_we,      // Command Register Write Enable
   cmd_do,      // Command Register Write Data
   cmd_busy,
   
   sys_clk,     // System Clock
   cmd_clr,     // Command Register Read
   cmd_di,      // Command Register Data
   cmd_int_req  // Command Register Interrupt
   );

   input         rst;
   input         pci_clk;
   input 	 cmd_we;
   input [31:0]  cmd_do;
   output        cmd_busy;
   
   input         sys_clk;
   input         cmd_clr;
   output [31:0] cmd_di;
   output        cmd_int_req;

   reg           int_state,busy_state;
   wire          busy_clr;
        
   reg [31:0]    cmd_di;
   
   parameter     IDLE  = 1'b0;
   parameter     VALID = 1'b1;
   
   // Clock exchange for Interrupt signal
   req_trans _req_trans1(
                         .rst(rst),
                         .in_clk(pci_clk),
                         .din(cmd_we),
                         
                         .out_clk(sys_clk),
                         .dout(cmd_int_req)
                         );

   // Clock exchange for clear signal
   req_trans _req_trans2(
                         .rst(rst),
                         .in_clk(sys_clk),
                         .din(cmd_clr),
                         
                         .out_clk(pci_clk),
                         .dout(busy_clr)
                         );

   // Command Register busy state signal
   always @(posedge pci_clk or negedge rst) begin
      if(!rst) busy_state <= IDLE;
      else begin
         case (busy_state)
           IDLE:  if(cmd_we   == 1'b1) busy_state <= VALID;
           VALID: if(busy_clr == 1'b1) busy_state <= IDLE;
         endcase // case(busy_state)
      end
   end
   assign cmd_busy = (busy_state == VALID);
   
   always @(posedge pci_clk or negedge rst) begin
      if(!rst) cmd_di <= 32'h00000000;
      else if(busy_state == IDLE & cmd_we == 1'b1) cmd_di <= cmd_do;
   end
endmodule // cmd_reg
