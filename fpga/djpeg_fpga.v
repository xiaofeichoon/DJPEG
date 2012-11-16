`timescale 1ps / 1ps

module djpeg_fpga
  (
   // PCI Loacl Bus
   PCI_RST,     // PCI Reset(Low Active)
   PCI_CLK,     // PCI Clock(33MHz)

   PCI_FRAME_N,
   PCI_IDSEL,
   PCI_DEVSEL_N,
   PCI_IRDY_N,
   PCI_TRDY_N,
   PCI_STOP_N,

   PCI_CBE,
   PCI_AD,
   PCI_PAR,

   PCI_SERR_N,
   PCI_PERR_N,
   PCI_INTA_N,

	SYS_CLK,

   LED
   );

   input          PCI_RST;
   input          PCI_CLK;

   input          PCI_FRAME_N;
   input          PCI_IDSEL;
   output         PCI_DEVSEL_N;
   input          PCI_IRDY_N;
   output         PCI_TRDY_N;
   output         PCI_STOP_N;

   inout [3:0]    PCI_CBE;
   inout [31:0]   PCI_AD;
   inout          PCI_PAR;

   output         PCI_SERR_N;
   output         PCI_PERR_N;
   output         PCI_INTA_N;
   
   input		SYS_CLK;

        output [8:1]    LED;
        
   wire           pci_devsel_no;
   wire           pci_devsel_ot;
   wire           pci_trdy_no;
   wire           pci_trdy_ot;
   wire           pci_stop_no;
   wire           pci_stop_ot;
   wire [31:0]    pci_ad_o;
   wire           pci_ad_ot;
   wire           pci_par_o;
   wire           pci_par_ot;
   wire           pci_serr_ot;
   wire           pci_perr_no;
   wire           pci_perr_ot;
   wire           pci_inta_ot;
   wire           pci_frame_ni;
   wire           pci_idsel_i;
   wire           pci_irdy_ni;
   wire [3:0]     pci_cbe_i;
   wire [31:0]    pci_ad_i;
   wire           pci_par_i;

        wire    sys_clk;
        
        wire    jpeg_start;
        wire    jpeg_idle;
        wire    jpeg_reset;
        
        wire    fifo_enable;
        wire [31:0]     fifo_data;
        wire    fifo_read;
        
        wire    bm_enable;
        wire [15:0]     bm_width;
        wire [15:0]     bm_height;
        wire [15:0]     bm_x;
        wire [15:0]     bm_y;
        wire [7:0]      bm_r;
        wire [7:0]      bm_g;
        wire [7:0]      bm_b;

   // ------------------------------------------------------------
   // PCI Signals
   // ------------------------------------------------------------
   assign         pci_frame_ni = PCI_FRAME_N;
   assign         pci_idsel_i  = PCI_IDSEL;
   assign         pci_irdy_ni  = PCI_IRDY_N;
   assign         pci_cbe_i    = PCI_CBE;
   assign         pci_ad_i     = PCI_AD;
   assign         pci_par_i    = PCI_PAR;
   
   assign         PCI_DEVSEL_N = pci_devsel_ot ? 1'bz       : pci_devsel_no;
   assign         PCI_TRDY_N   = pci_trdy_ot   ? 1'bz       : pci_trdy_no;
   assign         PCI_STOP_N   = pci_stop_ot   ? 1'bz       : pci_stop_no;
   assign         PCI_AD       = pci_ad_ot     ? {32{1'bz}} : pci_ad_o[31:0];
   assign         PCI_PAR      = pci_par_ot    ? 1'bz       : pci_par_o;
   assign         PCI_SERR_N   = pci_serr_ot   ? 1'bz       : 1'b0;
   assign         PCI_PERR_N   = pci_perr_ot   ? 1'bz       : pci_perr_no;
   assign         PCI_INTA_N   = pci_inta_ot   ? 1'bz       : 1'b0;

        pci_top u_pci_top (
            // PCI Loacl Bus
            .pci_rst       ( PCI_RST       ),     // PCI Reset(Low Active)
            .pci_clk       ( PCI_CLK       ),     // PCI Clock(33MHz)
        
            .pci_frame_ni  ( pci_frame_ni  ),     //
            .pci_idsel_i   ( pci_idsel_i   ),     //
            .pci_devsel_no ( pci_devsel_no ),     //
            .pci_devsel_ot ( pci_devsel_ot ),     //
            .pci_irdy_ni   ( pci_irdy_ni   ),     //
            .pci_trdy_no   ( pci_trdy_no   ),     //
            .pci_trdy_ot   ( pci_trdy_ot   ),     //
            .pci_stop_no   ( pci_stop_no   ),     //
            .pci_stop_ot   ( pci_stop_ot   ),     //
        
            .pci_cbe_i     ( pci_cbe_i     ),     //
        
            .pci_ad_i      ( pci_ad_i      ),     // Address/Data Input
            .pci_ad_o      ( pci_ad_o      ),     // Data Out
            .pci_ad_ot     ( pci_ad_ot     ),     // 1:Output,0:Input
        
            .pci_par_i     ( pci_par_i     ),     //
            .pci_par_o     ( pci_par_o     ),     //
            .pci_par_ot    ( pci_par_ot    ),     //
        
            .pci_serr_ot   ( pci_serr_ot   ),     //
            .pci_perr_no   ( pci_perr_no   ),     //
            .pci_perr_ot   ( pci_perr_ot   ),     //
            .pci_inta_ot   ( pci_inta_ot   ),     //
        
            .sys_clk       ( SYS_CLK            ),
        
                .jpeg_start             ( jpeg_start    ),
                .jpeg_idle              ( jpeg_idle             ),
                .jpeg_reset             ( jpeg_reset    ),
        
                .fifo_enable    ( fifo_enable   ),
                .fifo_data              ( fifo_data             ),
                .fifo_read              ( fifo_read             ),
        
                .bm_enable              ( bm_enable             ),
                .bm_width               ( bm_width              ),
                .bm_height              ( bm_height             ),
                .bm_x                   ( bm_x[7:0]                     ),
                .bm_y                   ( bm_y[7:0]                     ),
                .bm_r                   ( bm_r                  ),
                .bm_g                   ( bm_g                  ),
                .bm_b                   ( bm_b                  ),
                
                .status                 ( LED                   )
        );

        jpeg_decode u_jpeg_decode(
                .rst( jpeg_reset        ),
                .clk( SYS_CLK           ),

                // From FIFO
                .DataIn                 ( fifo_data             ),
                .DataInEnable   ( fifo_enable   ),
                .DataInRead             ( fifo_read             ),

                .JpegDecodeIdle ( jpeg_idle             ),

                .OutEnable              ( bm_enable             ),
                .OutWidth               ( bm_width              ),
                .OutHeight              ( bm_height             ),
                .OutPixelX              ( bm_x                  ),
                .OutPixelY              ( bm_y                  ),
                .OutR                   ( bm_r                  ),
                .OutG                   ( bm_g                  ),
                .OutB                   ( bm_b                  )
   );

endmodule

