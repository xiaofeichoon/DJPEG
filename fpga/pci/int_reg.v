`timescale 1ns/10ps

module int_reg
  (
   rst,     // Reset

   in_clk,  // Inside Clock
   we,      // Write Enable
   din,     // Interrupt Data in

   out_clk, // Outside Clock
   clr,     // Interrupt Clear
   dout     // Interrupt Register
   );

   input         rst;

   input         in_clk;
   input 	 we;
   input [31:0]  din;

   input         out_clk;
   input         clr;
   output [31:0] dout;

   reg [1:0] 	 queue_state;
   reg [31:0] 	 queue_data;
   parameter 	 S_QUEUE_IDLE    = 2'b00;
   parameter 	 S_QUEUE_RESERVE = 2'b01;
   parameter 	 S_QUEUE_REQUEST = 2'b10;

   reg [1:0]	 active_state;
   reg [31:0] 	 active_data;
   parameter 	 S_ACTIVE_IDLE    = 2'b00;
   parameter 	 S_ACTIVE_REQUEST = 2'b01;
   parameter 	 S_ACTIVE_WAIT    = 2'b10;

   reg 		 d1_ff,d2_ff;
   reg [31:0] 	 trans1_data,trans2_data;

   wire 	 report,int_req;
      
   reg 		 delay1_req,delay2_req;
   reg [31:0] 	 delay_data;
   wire 	 delay_req;

   reg [31:0] 	 dout;
   
   // Queue State Machine   
   always @(posedge in_clk or negedge rst) begin
      if(!rst) begin
	 queue_state <= S_QUEUE_IDLE;
	 queue_data  <= 32'h00000000;
      end else begin
	 case(queue_state)
	   S_QUEUE_IDLE: begin
	      if(we == 1'b1) begin
		 queue_state <= S_QUEUE_RESERVE;
		 queue_data  <= din;
	      end
	   end
	   S_QUEUE_RESERVE: begin
	      if(active_state == S_ACTIVE_IDLE)
		queue_state <= S_QUEUE_REQUEST;
	      if(we == 1'b1) queue_data <= queue_data | din;
	   end
	   S_QUEUE_REQUEST: begin
	      if(we == 1'b1) begin
		 queue_state <= S_QUEUE_RESERVE;
		 queue_data  <= din;
	      end else begin
		 queue_state <= S_QUEUE_IDLE;
		 queue_data  <= 32'h0000000;
	      end
	   end
	 endcase // case(queue_state)
      end // else: !if(!rst)
   end // always @ (posedge in_clk or negedge rst)

   // Active State Machine
   always @(posedge in_clk or negedge rst) begin
      if(!rst) begin
	 active_state <= S_ACTIVE_IDLE;
	 active_data  <= 32'h00000000;
      end else begin
	case(active_state)
	  S_ACTIVE_IDLE: begin
	     if(queue_state == S_QUEUE_REQUEST) begin
		active_state <= S_ACTIVE_REQUEST;
		active_data  <= queue_data;
	     end
	  end
	  S_ACTIVE_REQUEST: begin
	     if(report == 1'b1) active_state <= S_ACTIVE_WAIT;
	  end
	  S_ACTIVE_WAIT: begin
	     if(report == 1'b0) active_state <= S_ACTIVE_IDLE;
	  end
	endcase // case(active_state)
      end // else: !if(!rst)
   end // always @ (posedge in_clk or negedge rst)

   // Clock exchange
   always @(posedge out_clk or negedge rst) begin
      if(!rst) begin
	 d1_ff       <= 1'b0;
	 d2_ff       <= 1'b0;
	 trans1_data <= 32'h00000000;
	 trans2_data <= 32'h00000000;
      end else begin
	 d1_ff       <= active_state == S_ACTIVE_REQUEST;
	 d2_ff       <= d1_ff;
	 trans1_data <= active_data;
	 trans2_data <= trans1_data;
      end // else: !if(!rst)
   end // always @ (posedge out_clk or negedge rst)
   assign report  = d1_ff == 1'b1 & d2_ff == 1'b1;
   assign int_req = d1_ff == 1'b0 & d2_ff == 1'b1;

   // Delay from Interrupt Request
   always @(posedge out_clk or negedge rst) begin
      if(!rst) begin
	 delay1_req  <= 1'b0;
	 delay2_req  <= 1'b0;
	 delay_data <= 32'h00000000;
      end else begin
	 delay1_req  <= int_req;
	 delay2_req  <= int_req;
	 delay_data <= trans2_data;
      end
   end // always @ (posedge out_clk or negedge rst)
   assign delay_req = delay1_req == 1'b1 & delay2_req == 1'b0;

   // Output Interrupt Data
   always @(posedge out_clk or negedge rst) begin
      if(!rst) dout <= 32'h00000000;
      else begin
	 if(clr == 1'b1) begin
	    if(int_req == 1'b1)        dout <= trans2_data;
	    else if(delay_req == 1'b1) dout <= delay_data;
	    else                       dout <= 32'h00000000;
	 end else begin
	    if(int_req == 1'b1)        dout <= dout | trans2_data;
	 end
      end
   end // always @ (posedge out_clk or negedge rst)

endmodule // irr_ctl
