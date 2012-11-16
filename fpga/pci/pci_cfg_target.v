`timescale 1ns/10ps

module pci_cfg_target
  (
   rst,
   clk,
   first_cyc,
   acc_cfg,
   acc_end,
   bar_hit,
   ebar_hit,
   target_act,
   card_hit,
   t_barhit,
   t_ebarhit
   );

   input rst,clk;
   input first_cyc,acc_cfg,acc_end;
   input [5:0] bar_hit;
   input       ebar_hit;
   output      target_act;
   output      card_hit;
   output [5:0] t_barhit;
   output       t_ebarhit;

   reg          target_act;
   reg [5:0]    t_barhit;
   reg          t_ebarhit;
   

   assign card_hit = acc_cfg | bar_hit[0] | bar_hit[1] | bar_hit[2] |
                     bar_hit[3] | bar_hit[4] | bar_hit[5] | ebar_hit;
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         target_act <= 1'b0;
         t_barhit <= 6'b000000;
         t_ebarhit <= 1'b0;
      end else begin
         if(acc_end == 1'b1) target_act <= 1'b1;
         else if(card_hit == 1'b1) target_act <= 1'b0;

         if(acc_end == 1'b1)begin
            t_barhit <= 6'b000000;
            t_ebarhit <= 1'b0;
         end else if(first_cyc == 1'b1) begin
            t_barhit <= bar_hit;
            t_ebarhit <= ebar_hit;
         end
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
endmodule // pci_cfg_target
