`timescale 1ns/10ps

module req_trans
  (
   rst,
   in_clk,
   din,

   out_clk,
   dout
   );

   input  rst,in_clk,out_clk,din;
   output dout;

   reg    req;
   reg    d1_r,d2_r;
          
   wire   req_clr;
   
   parameter IDLE = 1'b0;
   parameter HOLD = 1'b1;
   
   always @(posedge in_clk or negedge rst) begin
      if(!rst) req <= IDLE;
      else begin
         case (req)
           IDLE: if(din == 1'b1)     req <= HOLD;
           HOLD: if(req_clr == 1'b1) req <= IDLE;
         endcase // case(req)
      end
   end

   always @(posedge out_clk or negedge rst) begin
      if(!rst) begin
         d1_r <= 1'b0;
         d2_r <= 1'b0;
      end else begin
         if(req == HOLD) d1_r <= 1'b1;
         else            d1_r <= 1'b0;
         d2_r <= d1_r;
      end
   end
   assign req_clr = ((d1_r == 1'b1) & (d2_r == 1'b1));
   assign dout = ((d1_r == 1'b0) & (d2_r == 1'b1));
endmodule // req_trans
