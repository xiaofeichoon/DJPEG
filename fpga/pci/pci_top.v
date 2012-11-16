`timescale 1ns/10ps

`define BM_WIDTH	8
`define BM_HEIGHT	8

module pci_top
  (
   // PCI Loacl Bus
   pci_rst,   // PCI Reset(Low Active)
   pci_clk,   // PCI Clock(33MHz)

   pci_frame_ni,   // 
   pci_idsel_i,    // 
   pci_devsel_no,  // 
   pci_devsel_ot,  //
   pci_irdy_ni,    // 
   pci_trdy_no,    //
   pci_trdy_ot,    //  
   pci_stop_no,    // 
   pci_stop_ot,    // 

   pci_cbe_i,  //
   
   pci_ad_i,  // Address/Data Input
   pci_ad_o,  // Data Out
   pci_ad_ot, // 0:Output,1:Input
   
   pci_par_i,   //
   pci_par_o,   //
   pci_par_ot,  //

   pci_serr_ot, //
   pci_perr_no, //
   pci_perr_ot, //
   pci_inta_ot, //
   
   // System Clock & Reset
   sys_clk,              // System Clock Posedge

	jpeg_start,
	jpeg_idle,
	jpeg_reset,
	
	fifo_enable,
	fifo_data,
	fifo_read,
	
	bm_enable,
	bm_width,
	bm_height,
	bm_x,
	bm_y,
	bm_r,
	bm_g,
	bm_b,
	
	status
  );

   // PCI-BUS Interface
   input           pci_rst;
   input           pci_clk;
   
   input           pci_frame_ni;
   input           pci_idsel_i;
   output          pci_devsel_no;
   output          pci_devsel_ot;
   input           pci_irdy_ni;
   output          pci_trdy_no;
   output          pci_trdy_ot;
   output          pci_stop_no;
   output          pci_stop_ot;
   
   input [3:0]     pci_cbe_i;
   
   input [31:0]    pci_ad_i;
   output [31:0]   pci_ad_o;
   output          pci_ad_ot;
   
   input           pci_par_i;
   output          pci_par_o;
   output          pci_par_ot;
   
   output          pci_serr_ot;
   output          pci_perr_no;
   output          pci_perr_ot;
   output          pci_inta_ot;

   input           sys_clk;
   
	output		jpeg_start;
	input		jpeg_idle;
	output		jpeg_reset;
	
	output			fifo_enable;
	output [31:0]	fifo_data;
	input			fifo_read;
	
	input	bm_enable;
	input [15:0]	bm_width;
	input [15:0]	bm_height;
	input [`BM_WIDTH-1:0]		bm_x;
	input [`BM_HEIGHT-1:0]	bm_y;
	input [7:0]	bm_r;
	input [7:0]	bm_g;
	input [7:0]	bm_b;
	
	output [7:0]	status;

	wire	jpeg_reset;
	wire	sys_rst;

	// Internal Signals
   wire [31:0]     app_adr;
   wire [31:0]     app_adi;
   wire [31:0]     app_ado;
   wire            app_int_n;
   wire [5:0]      t_barhit;
   wire            t_ebarhit;
   wire [3:0]      t_be_n;
   wire [3:0]      t_cmd;
   wire            t_rd;
   wire            t_wr;
   wire            t_we;
   wire            t_nextd;
   wire            t_drdy;
   wire            t_term;
   wire            t_abort;

   wire            cmd_we;
   wire [31:0]     cmd_do;
   wire            cmd_busy;
   
	wire 			fifo_we;
	wire [31:0]		fifo_wd;
	wire 			fifo_full;
	wire 			fifo_amlfull;
   
	wire	fifo_empty;
	

   wire            cmd_clr;
   wire [31:0]     cmd_di;
   wire            cmd_int_req;
   
   wire            int_we;
   wire [31:0]     int_do;
   wire				int_clr;
   wire [31:0]		int_di;

	reg [31:0]	bm_data;
   
	assign sys_rst = jpeg_reset;
   
   ///////////////////////////////////////////////////////////////////////////
   // PCI 32bit/33MHz Target core
   ///////////////////////////////////////////////////////////////////////////
   pci_t_core u_pci_t_core (
                           .pci_rst       ( pci_rst       ),
                           .pci_clk       ( pci_clk       ),
                           .pci_adi       ( pci_ad_i      ),
                           .pci_ado       ( pci_ad_o      ),
                           .pci_ado_ot    ( pci_ad_ot     ),
                           .pci_cbei      ( pci_cbe_i     ),
                           .pci_pari      ( pci_par_i     ),
                           .pci_paro      ( pci_par_o     ),
                           .pci_paro_ot   ( pci_par_ot    ),
                           .pci_frame_ni  ( pci_frame_ni  ),
                           .pci_irdy_ni   ( pci_irdy_ni   ),
                           .pci_trdy_no   ( pci_trdy_no   ),
                           .pci_trdy_ot   ( pci_trdy_ot   ),
                           .pci_devsel_no ( pci_devsel_no ),
                           .pci_devsel_ot ( pci_devsel_ot ),
                           .pci_stop_no   ( pci_stop_no   ),
                           .pci_stop_ot   ( pci_stop_ot   ),
                           .pci_idseli    ( pci_idsel_i   ),
                           .pci_perr_no   ( pci_perr_no   ),
                           .pci_perr_ot   ( pci_perr_ot   ),
                           .pci_serr_ot   ( pci_serr_ot   ),
                           .pci_inta_ot   ( pci_inta_ot   ),
                           
                           .app_adr       ( app_adr       ),
                           .app_adi       ( app_adi       ),
                           .app_ado       ( app_ado       ),
                           .app_int_n     ( app_int_n     ),
                           .t_barhit      ( t_barhit      ),
                           .t_ebarhit     ( t_ebarhit     ),
                           .t_cmd         ( t_cmd         ),
                           .t_be_n        ( t_be_n        ),
                           .t_rd          ( t_rd          ),
                           .t_wr          ( t_wr          ),
                           .t_we          ( t_we          ),
                           .t_nextd       ( t_nextd       ),
                           .t_drdy        ( t_drdy        ),
                           .t_term        ( t_term        ),
                           .t_abort       ( t_abort       )
                           
                           );

   ///////////////////////////////////////////////////////////////////////////
   // PCI Apprication control
   ///////////////////////////////////////////////////////////////////////////
   if_app u_if_app(
                  .rst			( pci_rst       ),
                  .clk        ( pci_clk       ),
                  
                  .s_adr      ( app_adr       ),
                  .s_adi      ( app_adi       ),
                  .s_ado      ( app_ado       ),
                  .s_int_n    ( app_int_n     ),
                  .s_barhit   ( t_barhit      ),
                  .s_ebarhit  ( t_ebarhit     ),
                  .s_be_n     ( t_be_n        ),
                  .s_rd       ( t_rd          ),
                  .s_wr       ( t_wr          ),
                  .s_we       ( t_we          ),
                  .s_nextd    ( t_nextd       ),
                  .s_drdy     ( t_drdy        ),
                  .s_term     ( t_term        ),
                  .s_abort    ( t_abort       ),
                  
                  .fifo_we		( fifo_we		),
                  .fifo_wd		( fifo_wd		),
                  .fifo_full	( fifo_full		),
                  .fifo_almfull	( fifo_almfull	),
                  
                  .bm_data		( bm_data		),
                  
                  .cmd_we     ( cmd_we        ),
                  .cmd_do     ( cmd_do        ),
                  .cmd_busy   ( cmd_busy      ),
                  
                  .int_clr	( int_clr     ),
                  .int_di	( int_di      ),

					.bm_width	( bm_width	),
					.bm_height	( bm_height	),
					
					.jpeg_idle	( jpeg_idle	),
					.jpeg_reset	( jpeg_reset	),
                  
                  .status		( status		)
                  );

   ///////////////////////////////////////////////////////////////////////////
   // Command Register
   ///////////////////////////////////////////////////////////////////////////
   cmd_reg u_cmd_reg(
                    .rst         ( sys_rst     ),
                    
                    .pci_clk     ( pci_clk     ),
                    .cmd_we      ( cmd_we      ),
                    .cmd_do      ( cmd_do      ),
                    .cmd_busy    ( cmd_busy    ),
                    
                    .sys_clk     ( sys_clk     ),
                    .cmd_clr     ( cmd_clr     ),
                    .cmd_di      ( cmd_di      ),
                    .cmd_int_req ( cmd_int_req )
                    );
//	assign jpeg_start	= cmd_int_req;
	assign cmd_clr		= ~jpeg_idle;
	
	reg jpeg_start;
	always @(posedge sys_clk or negedge sys_rst) begin
		if(!sys_rst) begin
			jpeg_start <= 1'b0;
		end else begin
			if(~jpeg_idle)			jpeg_start <= 1'b0;
			else if(cmd_int_req)	jpeg_start <= 1'b1;
		end
	end

   ///////////////////////////////////////////////////////////////////////////
   // Interrupt Register
   ///////////////////////////////////////////////////////////////////////////
   int_reg u_int_reg(
                      .rst		( sys_rst		),

                      .in_clk	( sys_clk		),
                      .we		( int_we		),
                      .din		( int_do		),
                      
                      .out_clk	( pci_clk		),
                      .clr		( int_clr		),
                      .dout		( int_di		)
                      );
	assign int_do[31:1]	= 31'd0;
    assign int_do[0]	= int_we;
    assign int_we		= (bm_width[`BM_WIDTH-1:0] == bm_x[`BM_WIDTH-1:0] +1) && (bm_height[`BM_HEIGHT-1:0] == bm_y[`BM_HEIGHT-1:0] +1);
    
	///////////////////////////////////////////////////////////////////////////
	// FIFO
	///////////////////////////////////////////////////////////////////////////
	fifo #(8) u_fifo(
		.RST				( sys_rst		),

		.FIFO_WR_CLK		( pci_clk		),
		.FIFO_WR_ENA		( fifo_we		),
		.FIFO_WR_DATA		( fifo_wd		),
		.FIFO_WR_FULL		( fifo_full		),
		.FIFO_WR_ALM_FULL	( fifo_almfull	),
		.FIFO_WR_ALM_COUNT	( 8'd0			),

		.FIFO_RD_CLK		( sys_clk		),
		.FIFO_RD_ENA		( fifo_read		),
		.FIFO_RD_DATA		( fifo_data		),
		.FIFO_RD_EMPTY		( fifo_empty	),
		.FIFO_RD_ALM_EMPTY	(				),
		.FIFO_RD_ALM_COUNT	( 8'd0			)
		);

	assign fifo_enable	= ~fifo_empty;

	///////////////////////////////////////////////////////////////////////////
	// Bitmap RAM(Default: 512dot x 512dot)
	///////////////////////////////////////////////////////////////////////////
	reg [23:0]	bm_ram [(2**(`BM_WIDTH+`BM_HEIGHT))-1:0];

	always @(posedge sys_clk) begin
		if(bm_enable)	bm_ram[{bm_y,bm_x}] = {bm_r,bm_g,bm_b};
	end

	always @(posedge pci_clk) begin
		bm_data = bm_ram[app_adr[(`BM_WIDTH+`BM_HEIGHT+2)-1:2]];
	end

endmodule
