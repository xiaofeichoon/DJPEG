`timescale 1ns/10ps

module pci_cfg_fsm
  (
   rst,
   clk,
   acc_cfg,
   cfg_sent,
   cfg_drdy
   );

   input rst,clk;
   input acc_cfg,cfg_sent;
   output cfg_drdy;

   parameter idle =2'b00;
   parameter decode= 2'b01;
   parameter data= 2'b10;
   parameter finish=2'b11;

   reg [1:0] configstate;
   

   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         configstate <= idle;
      end else begin
         case (configstate)
           idle: if(acc_cfg == 1'b1) configstate <= decode;
           decode: configstate <= data;
           data: configstate <= finish;
           finish: if(cfg_sent == 1'b1) configstate <= idle;
           //default:;
         endcase // case(configstate)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   
   assign cfg_drdy = configstate == finish;

endmodule // pci_cfg_fsm
