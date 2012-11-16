`timescale 1ns/10ps

module pci_check_par
  (
   rst,
   clk,
   adi,
   cbeid,
   first_cyc,  // first cycle after frame# falling edge
   irdynid,
   acc_wr,
   pari,       // parity input
   perr_en,    // parity error response enable
   serr_en,    // serr# enable
   target_act,
   new_perrno,
   new_otperr, // parity error buffer control
   new_serrno,
   sig_serr,   // set signaled system error bit(14)
   det_perr    // set detected parity error bit(15)
   );

   input rst,clk;
   input [31:0] adi;
   input [3:0]  cbeid;
   input        first_cyc,irdynid,acc_wr,pari,perr_en,serr_en,
                target_act;
   output       new_perrno,new_otperr,new_serrno,sig_serr,det_perr;

   reg          mdvalid;

   wire         par,pardiff;
   reg          dpardiff,cmderr;
   wire         target_write_err;
   reg          sig_serr;
   
      
   always @(posedge clk or negedge rst) begin
      if(!rst) mdvalid <= 1'b0;
      else mdvalid <= ~(irdynid);
   end
   
   assign par = adi[0] ^ adi[1] ^ adi[2] ^ adi[3] ^
                adi[4] ^ adi[5] ^ adi[6] ^ adi[7] ^
                adi[8] ^ adi[9] ^ adi[10] ^ adi[11] ^
                adi[12] ^ adi[13] ^ adi[14] ^ adi[15] ^
                adi[16] ^ adi[17] ^ adi[18] ^ adi[19] ^
                adi[20] ^ adi[21] ^ adi[22] ^ adi[23] ^
                adi[24] ^ adi[25] ^ adi[26] ^ adi[27] ^
                adi[28] ^ adi[29] ^ adi[30] ^ adi[31] ^
                cbeid[0] ^ cbeid[1] ^ cbeid[2] ^ cbeid[3];
   assign pardiff = par ^ pari;

   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         dpardiff <= 1'b0;
         cmderr <= 1'b0;
      end else begin
         dpardiff <= pardiff;
         cmderr <= pardiff & first_cyc;
      end
   end

   // serr# generator
   assign new_serrno = ~(pardiff & serr_en & first_cyc);
   // set signaled system error bit(14)
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         sig_serr <= 1'b0;
      end else begin
         sig_serr <= ~(new_serrno);
      end
   end
   // perr# generator
   assign new_perrno = ~(pardiff & perr_en);
   assign new_otperr = ~(~(irdynid) & target_act & acc_wr);
   // bar parity detected during trget write transaction
   assign target_write_err = dpardiff & mdvalid & target_act & acc_wr;
   // set detected parity error bit(15)
   assign det_perr = cmderr | target_write_err;
endmodule // pci_check_par
