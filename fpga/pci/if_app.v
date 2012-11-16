`timescale 1ns/10ps

module if_app
  (
   rst,
   clk,

   s_adr,
   s_adi,
   s_ado,
   s_int_n,
   s_barhit,
   s_ebarhit,
   s_be_n,
   s_rd,
   s_wr,
   s_we,
   s_nextd,
   s_drdy,
   s_term,
   s_abort,

	fifo_we,
	fifo_wd,
	fifo_full,
	fifo_almfull,
	
	bm_data,

   cmd_we,
   cmd_do,
   cmd_busy,

	int_clr,
	int_di,
	
	bm_width,
	bm_height,
	
	jpeg_idle,
	jpeg_reset,

	status
   );

   input            rst, clk;
   input [31:0]     s_adr;
   input [31:0]     s_adi;
   output [31:0]    s_ado;
   output           s_int_n;
   input [5:0]      s_barhit;
   input            s_ebarhit;
   input [3:0]      s_be_n;
   input            s_rd,s_wr,s_we,s_nextd;
   output           s_drdy,s_term,s_abort;

	output fifo_we;
	output [31:0] fifo_wd;
	input fifo_full;
	input fifo_almfull;
	
	input [31:0]	bm_data;
	
   output           cmd_we;
   output [31:0]    cmd_do;
   input            cmd_busy;

	output int_clr;
	input [31:0] int_di;
	
	input [15:0]	bm_width;
	input [15:0]	bm_height;

	input	jpeg_idle;
	output	jpeg_reset;

	output [7:0] status;

	reg	jpeg_reset;

   // Decode Address Hit
   wire 	    hit_cmd_reg;
   wire 	    hit_int_reg;
   wire 	    hit_fifo_sts;
   wire 	    hit_fifo_reg;
   wire 	    hit_reg;
   wire			hit_jpeg_sts;
   wire 	    hit_notprocess;
   
   assign 	    hit_bm			= s_barhit[0] == 1'b1 & s_adr[18] == 1'b0;
   assign 	    hit_cmd_reg		= s_barhit[0] == 1'b1 & s_adr[18:2] == 17'b100_0000_0000_0000_00;
   assign 	    hit_int_reg		= s_barhit[0] == 1'b1 & s_adr[18:2] == 17'b100_0000_0000_0000_01;
   assign 	    hit_fifo_sts		= s_barhit[0] == 1'b1 & s_adr[18:2] == 17'b100_0000_0000_0000_10;
   assign 	    hit_fifo_reg		= s_barhit[0] == 1'b1 & s_adr[18:2] == 17'b100_0000_0000_0000_11;
   assign 	    hit_reg			= s_barhit[0] == 1'b1 & s_adr[18:2] == 17'b100_0000_0000_0001_00;
   assign 	    hit_jpeg_sts		= s_barhit[0] == 1'b1 & s_adr[18:2] == 17'b100_0000_0000_0001_01;
   assign 	    hit_jpeg_ctl		= s_barhit[0] == 1'b1 & s_adr[18:2] == 17'b100_0000_0000_0001_11;
   assign 	    hit_notprocess	= s_barhit[0] == 1'b1 & ~(hit_bm | hit_cmd_reg | hit_int_reg | hit_fifo_sts | hit_fifo_reg | hit_reg | hit_jpeg_sts | hit_jpeg_ctl);
   
   // Command Regster Process
   assign 	    cmd_we   = (hit_cmd_reg == 1'b1 & s_wr == 1'b1 & cmd_busy == 1'b0)? s_we:1'b0;
   assign 	    cmd_do   = (hit_cmd_reg == 1'b1 & s_wr == 1'b1 & cmd_busy == 1'b0)? s_adi:32'h00000000;
   
   // Interrupt
   reg 	  hit_intd;
   always @(posedge clk or negedge rst) begin
      if(!rst) hit_intd <= 1'b0;
      else if(hit_int_reg == 1'b1 & s_rd == 1'b1) hit_intd <= 1'b1;
      else                                      hit_intd <= 1'b0;
   end
   assign int_clr = (hit_intd == 1'b1);

	reg	hit_bm_d;
	always @(posedge clk or negedge rst) begin
		if(!rst)	hit_bm_d <= 1'b0;
		else		hit_bm_d <= hit_bm;
	end

   // Term
   assign s_drdy	= (hit_bm & hit_bm_d) | hit_cmd_reg | hit_int_reg | hit_fifo_sts | hit_fifo_reg | hit_reg | hit_jpeg_sts | hit_jpeg_ctl | hit_notprocess;
   assign s_term	= 1'b0;
   assign s_abort	= 1'b0;
	assign s_int_n	= 1'b1;

	reg [31:0]	reg_data;
	// Reg
	always @(posedge clk or negedge rst) begin
		if(!rst) reg_data <= 32'd0;
		else if(hit_reg == 1'b1 & s_we == 1'b1) reg_data <= s_adi;
	end

	always @(posedge clk or negedge rst) begin
		if(!rst)										jpeg_reset <= 1'b1;
		else if(hit_jpeg_ctl == 1'b1 & s_we == 1'b1)	jpeg_reset <= s_adi[0];
	end
   
   // Output Data
   wire [31:0] out0_data, out1_data, out2_data, out3_data, out4_data, out5_data, out6_data;
   assign out0_data = (hit_bm)?bm_data:32'h00000000;
   assign out1_data = (hit_cmd_reg)?cmd_do:32'h00000000;
   assign out2_data = (hit_int_reg)?int_di:32'h00000000;
   assign out3_data = (hit_fifo_sts)?{28'd0, jpeg_idle, fifo_almfull, fifo_full, cmd_busy}:32'h00000000;
   assign out4_data = (hit_reg)?reg_data:32'h00000000;
   assign out5_data = (hit_reg)?{bm_height,bm_width}:32'h00000000;
   assign out6_data = (hit_reg)?{31'd0,jpeg_reset}:32'h00000000;
   
   assign s_ado = out0_data | out1_data | out2_data | out3_data | out4_data | out5_data;
   
	assign fifo_we	= hit_fifo_reg & s_we;
	assign fifo_wd	= s_adi;
	
	assign status = {4'd0,jpeg_idle, fifo_almfull, fifo_full, cmd_busy};
endmodule
