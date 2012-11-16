`timescale 1ns/10ps

module pci_gen_par
  (
   rst,
   clk,
   ce_ado,
   ado,
   cbei,
   new_paro
   );

   input        rst;
   input 	clk;
   input 	ce_ado;
   input [31:0] ado;
   input [3:0] 	cbei;
   output 	new_paro;
   
   reg 		datapar;

   always @(posedge clk or negedge rst) begin
      if(!rst) datapar <= 1'b0;
      else datapar <= (^ {ado});
   end
   
   assign new_paro = (^ {datapar, cbei});
   
endmodule // pci_gen_par
