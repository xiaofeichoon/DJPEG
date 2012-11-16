`timescale 1ns/10ps

module pci_target_fsm
  (
   rst,          // reset
   clk,          // clock
   frameni,      // frame#
   framenid,     //
   irdyni,       // irdy#
   irdynid,      //
   trdynid,      //
   card_hit,     // hit on address decode
   t_drdy,       // ready to transfer data
   cfg_drdy,     // 
   t_term,       // terminate transaction
   t_abort,      // target error - abort transaction
   acc_wr,       // command is write
   acc_rd,       // commandins read
   new_devselno, // devsel#
   new_trdyno,   // trdy#
   new_stopno,   // stop#
   ce_adodir,    // data output ffs clock enable direct
   ce_adordy,    // data output ffs clock enable ready
   ot_ad,        // ad bus enable
   ot_trdy,      // trdy# enable
   ot_stop,      // stop# enable
   ot_devsel,    // devsel# enable
   acc_end,      // end of target device access
   cfg_sent,     // config data sent
   inc_adr,      // incement address counter
   t_nextd,      // target ready to process next data
   t_we,         // target write enable
   t_wr,         // target write in progress
   t_rd          // target read in progress
   );

   input  rst,clk;

   input  frameni,framenid,irdyni,irdynid,trdynid;
   input  card_hit;

   input  t_drdy,cfg_drdy;
   input  t_term,t_abort;

   input  acc_wr,acc_rd;

   output new_devselno,new_trdyno,new_stopno;
   output ce_adodir,ce_adordy;
   output ot_ad,ot_trdy,ot_stop,ot_devsel;
   output acc_end;
   output cfg_sent;
   output inc_adr;
   output t_nextd,t_wr,t_we,t_rd;

   wire   dataready;
   wire   lotctrl;
   
   reg [1:0] targetstate;
   parameter idle = 2'b00;
   parameter b_busy = 2'b01;
   parameter s_data = 2'b10;
   parameter turn_ar = 2'b11;

   reg       ltrdyno,lstopno;
   wire      next_turn_ar;

   assign dataready = t_drdy | cfg_drdy;
   assign next_turn_ar = frameni == 1'b1 & irdyni == 1'b0 &
			 (ltrdyno == 1'b0 | lstopno == 1'b0);
   
   // target state    
   always @(posedge clk or negedge rst) begin
      if(!rst) targetstate <= idle;
      else begin
         case (targetstate)
           idle: begin
              if(frameni == 1'b0 & framenid == 1'b1) targetstate <= b_busy;
              else targetstate <= idle;
           end
           b_busy: begin
              if(framenid == 1'b0 & card_hit == 1'b1) targetstate <= s_data;
              else targetstate <= idle;
              
           end
           s_data: begin
              if(frameni == 1'b1 & irdyni == 1'b0 & (ltrdyno == 1'b0 |
                                                     lstopno == 1'b0))
                   targetstate <= turn_ar;
              else targetstate <= s_data;
           end
           turn_ar: begin
              if(frameni == 1'b0 & card_hit == 1'b0) targetstate <= b_busy;
              else targetstate <= idle;
           end
         endcase // case(targetstate)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   
   assign new_devselno = ~((targetstate == b_busy & framenid == 1'b0 & 
                            card_hit == 1'b1) |
                           (targetstate == s_data & 
                            ~((frameni == 1'b1 & irdyni == 1'b0 &
                               (ltrdyno == 1'b0 | lstopno == 1'b0)) |
                              t_abort == 1'b1)));

   reg    waitd;
   
   always @(posedge clk or negedge rst) begin
      if(!rst) waitd <= 1'b0;
      else begin
         if((targetstate == b_busy & card_hit == 1'b1 &
             (frameni == 1'b0 | irdyni == 1'b0)) |
            (targetstate == s_data & irdyni == 1'b0 & ltrdyno == 1'b0 &
             dataready == 1'b0))                             waitd <= 1'b1;
         else if(targetstate == turn_ar | dataready == 1'b1) waitd <= 1'b0;
      end
   end

   always @(posedge clk or negedge rst) begin
      if(!rst) ltrdyno <= 1'b1;
      else begin
         if(ltrdyno == 1'b0 & irdyni == 1'b0 & 
            (frameni == 1'b1 | dataready == 1'b0))          ltrdyno <= 1'b1;
         else if(targetstate == s_data & dataready == 1'b1) ltrdyno <= 1'b0;
      end
   end

   assign new_trdyno = ~((targetstate == s_data & dataready ==1'b1 &
                          ltrdyno == 1'b1) |
                         (ltrdyno == 1'b0 & ~(irdyni == 1'b0 & 
                                              (frameni == 1'b1 |
                                               dataready == 1'b0))));
   
   always @(posedge clk or negedge rst) begin
      if(!rst) lstopno <= 1'b1;
      else begin
         if(lstopno == 1'b0 & frameni == 1'b1 & irdyni == 1'b0) 
           lstopno <= 1'b1;
         else if(targetstate == s_data & (t_term == 1'b1 | t_abort == 1'b1))
           lstopno <= 1'b0;
      end
   end

   assign new_stopno = ~(((targetstate == s_data & 
                           (t_term == 1'b1 | t_abort == 1'b1) & 
                           lstopno == 1'b1) | 
                          (lstopno == 1'b0 &
                           ~(frameni == 1'b1 & irdyni ==1'b0))));
   
   assign ce_adodir = targetstate == s_data & waitd == 1'b1 & dataready == 1'b1;
   assign ce_adordy = targetstate == s_data & ltrdyno == 1'b0 & dataready == 1'b1;
   
   assign ot_ad = ~(targetstate == s_data & acc_rd == 1'b1 & ~(frameni == 1'b1 & irdyni == 1'b0 & (ltrdyno == 1'b0 & lstopno == 1'b0)));

   assign lotctrl = ~(((frameni == 1'b0 | irdyni == 1'b0) & card_hit == 1'b1 &
                       targetstate == b_busy) | targetstate == s_data);


   reg    ot_devsel,ot_trdy,ot_stop;
   
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         ot_devsel <= 1'b1;
         ot_trdy   <= 1'b1;
         ot_stop   <= 1'b1;
      end else begin
         ot_devsel <= lotctrl;
         ot_trdy   <= lotctrl;
         ot_stop   <= lotctrl;
      end
   end // always @ (posedge clk or negedge rst)

   assign acc_end = targetstate == turn_ar;

   assign t_we = targetstate != idle & acc_wr == 1'b1 & trdynid == 1'b0 &
                  irdynid == 1'b0;

   assign t_wr = targetstate != idle   & acc_wr == 1'b1;
   assign t_rd = targetstate == s_data & acc_rd == 1'b1 & next_turn_ar == 1'b0;
   
   reg    lce_adod;
   
   always @(posedge clk or negedge rst) begin
      if(!rst) lce_adod <= 1'b0;
      else if(targetstate == s_data &
	      ((irdyni == 1'b0 & ltrdyno == 1'b0 & dataready == 1'b1) |
	       (waitd ==1'b1 & dataready == 1'b1)))
	   lce_adod <= 1'b1;
      else lce_adod <= 1'b0;
   end

   reg wr_inc;
   
   
   function t_nextd_f;
      input [1:0] targetstate;
      input       acc_rd,lce_adod,wr_inc;
      if(acc_rd == 1'b1) begin
         if(targetstate == s_data) t_nextd_f = lce_adod;
         else                      t_nextd_f = 1'b0;
      end else begin
         if(targetstate != idle)   t_nextd_f = wr_inc;
         else                      t_nextd_f = 1'b0;
      end
   endfunction // t_nextd_f
   //assign t_nextd = t_nextd_f(targetstate,acc_rd,lce_adod,wr_inc);
   assign t_nextd = (frameni)?1'b0:t_nextd_f(targetstate,acc_rd,lce_adod,wr_inc);

   always @(posedge clk or negedge rst) begin
      if(!rst) wr_inc <= 1'b0;
      else     wr_inc <= ~(irdynid | trdynid);
   end

   function inc_adr_f;
      input [1:0] targetstate;
      input       acc_rd,lce_adod,wr_inc;
      if(acc_rd == 1'b1) begin
         if(targetstate == s_data) inc_adr_f = lce_adod;
         else                      inc_adr_f = 1'b0;
      end else begin
         if(targetstate != idle)   inc_adr_f = wr_inc;
         else                      inc_adr_f = 1'b0;
      end
   endfunction // inc_adr_f
   assign inc_adr = inc_adr_f(targetstate,acc_rd,lce_adod,wr_inc);
   
   assign cfg_sent = ~ltrdyno;

endmodule // pci_target_fsm
