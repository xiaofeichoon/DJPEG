`timescale 1ps/1ps

module TEST;

        // --------------------------------------------------
        //  Parameter Setting
        // --------------------------------------------------
        parameter   TIME30N         =  30000;   //  33 MHz

        reg     End_Of_Config;
        initial begin
                End_Of_Config = 1;
        end

        // --------------------------------------------------
        //  Global variables/events for Task/Functions
        // --------------------------------------------------
        integer            i, fp;

        initial begin
            i              = 0;
        end

        // --------------------------------------------------
        //  Top Module Ports
        // --------------------------------------------------
        // Reset & Clock
        reg             RST;

        reg           pci_rst;
        reg           pci_clk;

        reg [31:0]    pci_rom[0:65535]; // Dummy ROM
  
        wire [31:0]   pci_ad;
        wire [3:0]    pci_cbe;
        wire          pci_par;
        tri1          pci_frame_n;
        tri1          pci_trdy_n;
        tri1          pci_irdy_n;
        tri1          pci_stop_n;
        tri1          pci_devsel_n;
        wire          pci_idsel;
        tri1          pci_inta_n;
        tri1          pci_perr_n;
        tri1          pci_serr_n;
        
        reg [31:0]      read_data;
        
        wire [7:0]      LED;

        // --------------------------------------------------
        // Clock Generator
        // --------------------------------------------------
        initial begin
            pci_clk     = 1'b0;
        end

        always begin
            #(TIME30N/2) pci_clk <= ~pci_clk;
        end


        task INTERCYCLE_GAP;
           begin
              @(posedge pci_clk);
              @(posedge pci_clk);
              @(posedge pci_clk);
              @(posedge pci_clk);
           end
        endtask

        task T_SystemReset;
        begin
            RST <= 1'b0;
            repeat (4) @(negedge pci_clk); #2;
            RST <= 1'b1;
        end
        endtask

integer       sendlength = 256;

reg [31:0] pci_senddata [0:511]; // Send Data Buffer
integer pci_send_count;

   // Define Timing Parameters
   parameter     TDEL  =  5;

   // Define Internal Registers
   reg [3:0]     status_code;
   
   reg [31:0]    reg_ad;
   reg           ad_oe;
   reg [3:0]     reg_cbe;
   reg           cbe_oe;
   reg           reg_par;
   reg           par_oe;
   reg           reg_frame_n;
   reg           frame_oe;
   reg           reg_trdy_n;
   reg           trdy_oe;
   reg           reg_irdy_n;
   reg           irdy_oe;
   reg           reg_stop_n;
   reg           stop_oe;
   reg           reg_devsel_n;
   reg           devsel_oe;
   reg           reg_idsel;
   reg           reg_rst_n;
   reg           reg_term;
   reg           reg_abort;
   reg           reg_inta;

   // Define port hookup
   assign        #TDEL pci_ad       = ad_oe     ? reg_ad       : 32'bz;
   assign        #TDEL pci_cbe      = cbe_oe    ? reg_cbe      : 4'bz;
   assign        #TDEL pci_par      = par_oe    ? reg_par      : 1'bz;
   assign        #TDEL pci_frame_n  = frame_oe  ? reg_frame_n  : 1'bz;
   assign        #TDEL pci_trdy_n   = trdy_oe   ? reg_trdy_n   : 1'bz;
   assign        #TDEL pci_irdy_n   = irdy_oe   ? reg_irdy_n   : 1'bz;
   assign        #TDEL pci_stop_n   = stop_oe   ? reg_stop_n   : 1'bz;
   assign        #TDEL pci_devsel_n = devsel_oe ? reg_devsel_n : 1'bz;
   assign        #TDEL pci_idsel    = reg_idsel;
   
   ///////////////////////////////////////////////////////////////////////////
   // Initialize
   ///////////////////////////////////////////////////////////////////////////
   initial begin
       End_Of_Config = 0;

       $display(" PCI-BUS Reset...");

       reg_ad       <= 32'h0;
       ad_oe        <= 0;
       reg_cbe      <= 4'h0;
       cbe_oe       <= 0;
       reg_frame_n  <= 1;
       frame_oe     <= 0;
       reg_trdy_n   <= 1;
       trdy_oe      <= 0;
       reg_irdy_n   <= 1;
       irdy_oe      <= 0;
       reg_stop_n   <= 1;
       stop_oe      <= 0;
       reg_devsel_n <= 1;
       devsel_oe    <= 0;
       reg_idsel    <= 0;
       pci_rst      <= 0;
       reg_term     <= 0;
       reg_abort    <= 0;
       reg_inta     <= 1'b1;

       // system reset
       INTERCYCLE_GAP;
       pci_rst    <= 1;
       INTERCYCLE_GAP;
       INTERCYCLE_GAP;
       INTERCYCLE_GAP;
       INTERCYCLE_GAP;
       INTERCYCLE_GAP;
       INTERCYCLE_GAP;
       INTERCYCLE_GAP;

       PCI_CONFIG;

       End_Of_Config = 1;
   end

   task PCI_CONFIG;
     begin
       //////////////////////////////////////////////////////////////////////
       // Configuration Access (PCI)
       //////////////////////////////////////////////////////////////////////
       $display(" PCI Configuratin Start...");
       // read device and vendor id
       READ_CONFIG(32'h00000000);
     
       // write latency timer
       WRITE_CONFIG(32'h0000000c, 32'h0000ff00);
       READ_CONFIG(32'h0000000c);
     
       // setup io base address register
       //WRITE_CONFIG(32'h00000010, 32'h10000000);
       //READ_CONFIG(32'h00000010);
     
       // setup mem32 base address register
       WRITE_CONFIG(32'h00000010, 32'hFFFFFFFF);
       READ_CONFIG(32'h00000010);
     
       // setup mem32 base address register
       WRITE_CONFIG(32'h00000010, 32'h20000000);
       READ_CONFIG(32'h00000010);
     
       // setup command register to enable mastering
       WRITE_CONFIG(32'h00000004, 32'hff000147); 
       READ_CONFIG(32'h00000004);

       $display(" PCI Configuratin Read...");

       READ_CONFIG(32'h00000000);
       READ_CONFIG(32'h00000004);
       READ_CONFIG(32'h00000008);
       READ_CONFIG(32'h0000000C);
       READ_CONFIG(32'h00000010);
       READ_CONFIG(32'h00000014);
       READ_CONFIG(32'h00000018);
       READ_CONFIG(32'h0000001C);
       READ_CONFIG(32'h00000020);
       READ_CONFIG(32'h00000024);
       READ_CONFIG(32'h00000028);
       READ_CONFIG(32'h0000002C);
       READ_CONFIG(32'h00000030);
       READ_CONFIG(32'h00000034);
       READ_CONFIG(32'h00000038);
       READ_CONFIG(32'h0000003C);

       $display(" PCI Configuratin End...");
       End_Of_Config = 1;
     end
   endtask

   ///////////////////////////////////////////////////////////////////////////
   // PCI Parity Generation
   ///////////////////////////////////////////////////////////////////////////
   always @(posedge pci_clk)
     begin
        // Always computed, selectively enabled
        reg_par <= (^ {pci_ad, pci_cbe});
     end
   
   wire drive;
   
   assign #TDEL drive = ad_oe;
   
   always @(posedge pci_clk)
     begin
        par_oe <= drive;
     end

   ///////////////////////////////////////////////////////////////////////////
   // Task for reading from the PCI32's configuration space
   ///////////////////////////////////////////////////////////////////////////
   task READ_CONFIG;
      input [31:0] address;
      begin
         @(posedge pci_clk);
         reg_frame_n  <= 0;
         reg_irdy_n   <= 1;
         reg_ad       <= address;
         reg_cbe      <= 4'b1010;
         reg_idsel    <= 1;
         frame_oe     <= 1;
         irdy_oe      <= 1;
         ad_oe        <= 1;
         cbe_oe       <= 1;
         @(posedge pci_clk);
         reg_frame_n  <= 1;
         reg_irdy_n   <= 0;
         reg_cbe      <= 4'b0000;
         reg_idsel    <= 0;
         frame_oe     <= 1;
         irdy_oe      <= 1;
         ad_oe        <= 0;
         cbe_oe       <= 1;
         XFER_STATUS(0, status_code);
         reg_irdy_n   <= 1;
         frame_oe     <= 0;
         irdy_oe      <= 1;
         ad_oe        <= 0;
         cbe_oe       <= 0;
         @(posedge pci_clk);
         frame_oe     <= 0;
         irdy_oe      <= 0;
         @(posedge pci_clk);
         INTERCYCLE_GAP;
      end
   endtask
   
   ///////////////////////////////////////////////////////////////////////////
   // Task for writing to the PCI32's configuration space
   ///////////////////////////////////////////////////////////////////////////
   task WRITE_CONFIG;
      input [31:0] address;
      input [31:0] data;
      begin
         @(posedge pci_clk);
         reg_frame_n   <= 0;
         reg_irdy_n    <= 1;
         reg_ad        <= address;
         reg_cbe       <= 4'b1011;
         reg_idsel     <= 1;
         frame_oe      <= 1;
         irdy_oe       <= 1;
         ad_oe         <= 1;
         cbe_oe        <= 1;
         @(posedge pci_clk);
         reg_frame_n   <= 1;
         reg_irdy_n    <= 0;
         reg_ad        <= data;
         reg_cbe       <= 4'b0000;
         reg_idsel     <= 0;
         frame_oe      <= 1;
         irdy_oe       <= 1;
         ad_oe         <= 1;
         cbe_oe        <= 1;
         XFER_STATUS(1, status_code);
         reg_irdy_n    <= 1;
         frame_oe      <= 0;
         irdy_oe       <= 1;
         ad_oe         <= 0;
         cbe_oe        <= 0;
         @(posedge pci_clk);
         frame_oe      <= 0;
         irdy_oe       <= 0;
         @(posedge pci_clk);
         INTERCYCLE_GAP;
      end
   endtask
   
   ///////////////////////////////////////////////////////////////////////////
   // Task for reading from the PCI32
   ///////////////////////////////////////////////////////////////////////////
   task READ32;
      input [31:0] address;
      begin
         @(posedge pci_clk);
         reg_frame_n   <= 0;
         reg_irdy_n    <= 1;
         reg_ad        <= address;
         reg_cbe       <= 4'b0110;
         frame_oe      <= 1;
         irdy_oe       <= 1;
         ad_oe         <= 1;
         cbe_oe        <= 1;
         @(posedge pci_clk);
         reg_frame_n   <= 1;
         reg_irdy_n    <= 0;
         reg_cbe       <= 4'b0000;
         frame_oe      <= 1;
         irdy_oe       <= 1;
         ad_oe         <= 0;
         cbe_oe        <= 1;
         XFER_STATUS(0, status_code);
                        read_data               <= pci_ad;
         reg_irdy_n    <= 1;
         frame_oe      <= 0;
         irdy_oe       <= 1;
         ad_oe         <= 0;
         cbe_oe        <= 0;
         @(posedge pci_clk);
         frame_oe      <= 0;
         irdy_oe       <= 0;
         @(posedge pci_clk);
         INTERCYCLE_GAP;
      end
   endtask
   
   ///////////////////////////////////////////////////////////////////////////
   // Task for writing to the PCI32
   ///////////////////////////////////////////////////////////////////////////
   task WRITE32;
      input [31:0] address;
      input [31:0] data;
      begin
         @(posedge pci_clk);
         reg_frame_n   <= 0;
         reg_irdy_n    <= 1;
         reg_ad        <= address;
         reg_cbe       <= 4'b0111;
         frame_oe      <= 1;
         irdy_oe       <= 1;
         ad_oe         <= 1;
         cbe_oe        <= 1;
         @(posedge pci_clk);
         reg_frame_n   <= 1;
         reg_irdy_n    <= 0;
         reg_ad        <= data;
         reg_cbe       <= 4'b0000;
         frame_oe      <= 1;
         irdy_oe       <= 1;
         ad_oe         <= 1;
         cbe_oe        <= 1;
         XFER_STATUS(1, status_code);
         reg_irdy_n    <= 1;
         frame_oe      <= 0;
         irdy_oe       <= 1;
         ad_oe         <= 0;
         cbe_oe        <= 0;
         @(posedge pci_clk);
         frame_oe      <= 0;
         irdy_oe       <= 0;
         @(posedge pci_clk);
         INTERCYCLE_GAP;
      end
   endtask
   
   
   ///////////////////////////////////////////////////////////////////////////
   // Task for monitoring the actual data transfer
   ///////////////////////////////////////////////////////////////////////////
   task XFER_STATUS;
      input write_read;
      output [3:0] return_stat;
      integer      devsel_cnt;
      integer      trdy_cnt;
      begin
         devsel_cnt = 0;
         trdy_cnt = 0;
         while(pci_devsel_n && (devsel_cnt < 10))
           begin
              @(posedge pci_clk);
              devsel_cnt = devsel_cnt + 1; // increment count
           end
         while(pci_trdy_n  && pci_stop_n && ((trdy_cnt < 16) && (devsel_cnt < 10)))
           begin
              trdy_cnt = trdy_cnt + 1;
              @(posedge pci_clk);
           end
         if (devsel_cnt < 10)
           begin
              if (trdy_cnt <= 16)
                begin
                   if (pci_trdy_n == 0 && pci_stop_n == 1)
                     begin
                        /*
                        if (write_read)
                          $display("  STM-->PCI: Normal Termination, Data Transferred");
                        else
                          $display("  STM<--PCI: Normal Termination, Data Transferred");
                        */
                        return_stat = 1;
                     end
                   else if(pci_trdy_n == 0 && pci_stop_n == 0)
                     begin
                        if (write_read)
                          $display("[PCI-STOP]  STM-->PCI: Disconnect, Data Transferred");
                        else
                          $display("[PCI-STOP]  STM<--PCI: Disconnect, Data Transferred");
                        return_stat = 2;
                     end
                   else if (pci_trdy_n==1 && pci_stop_n == 0 && pci_devsel_n == 0)
                     begin
                        if (write_read)
                          $display("[PCI-STOP]  STM-->PCI: Retry, No Data Transferred");
                        else
                          $display("[PCI-STOP]  STM<--PCI: Retry, No Data Transferred");
                        return_stat = 3;
                     end
                   else if (pci_trdy_n==1 && pci_stop_n == 0 && pci_devsel_n == 1)
                     begin
                        if (write_read)
                          $display("[PCI-STOP]  STM-->PCI: Target Abort, No Data Transferred");
                        else
                          $display("[PCI-STOP]  STM<--PCI: Target Abort, No Data Transferred");
                        return_stat = 4;
                     end
                   else if (pci_trdy_n==1 && pci_stop_n == 1)
                     begin
                        $display("  ERROR: Check Transfer Procedure");
                        return_stat = 5;
                     end
                end
              else
                begin
                   $display("  ERROR: No Target Response");
                   return_stat = 6;
                end
           end
         else
           begin
              $display("  ERROR: Master Abort");
              return_stat = 7;
           end
      end
   endtask
   
//-------------------------------------------------------------------------
// Task for reading and compare from the PCI32
//-------------------------------------------------------------------------
task READCMP32;
   input [31:0] address;
   input [31:0] data;

   integer      cmp;
   integer      count;

   begin
      cmp        = 1;
      count      = 0;
      while(cmp) begin
         @(posedge pci_clk);
         reg_frame_n   <= 0;
         reg_irdy_n    <= 1;
         reg_ad        <= address;
         reg_cbe       <= 4'b0110;
         frame_oe      <= 1;
         irdy_oe       <= 1;
         ad_oe         <= 1;
         cbe_oe        <= 1;
         @(posedge pci_clk);
         reg_frame_n   <= 1;
         reg_irdy_n    <= 0;
         reg_cbe       <= 4'b0000;
         frame_oe      <= 1;
         irdy_oe       <= 1;
         ad_oe         <= 0;
         cbe_oe        <= 1;
         XFER_STATUS(0, status_code);
         casex(pci_ad)
           data: begin
              cmp = 0;
           end
           default: begin
//          count = count +1;
//          if(count >1024) begin
//             $display("**************************************************");
//             $display(" Error: Can not Compare!!!");
//             $display("**************************************************");
//             cmp = 0;
//                      $finish();
//            end
           end
         endcase
         reg_irdy_n    <= 1;
         frame_oe      <= 0;
         irdy_oe       <= 1;
         ad_oe         <= 0;
         cbe_oe        <= 0;
         @(posedge pci_clk);
         frame_oe      <= 0;
         irdy_oe       <= 0;
         @(posedge pci_clk);
         INTERCYCLE_GAP;
      end // while (cmp)
   end
endtask // READCMP32
   
   ///////////////////////////////////////////////////////////////////////////
   // Tasks for Target Term
   ///////////////////////////////////////////////////////////////////////////
   task TTERM_SET;
      begin
         @(posedge pci_clk);
         reg_term <= 1'b1;
         @(posedge pci_clk);
      end
   endtask
   
   task TTERM_FREE;
      begin    
         @(posedge pci_clk); 
         reg_term <= 1'b0; 
         @(posedge pci_clk); 
      end 
   endtask 

   ///////////////////////////////////////////////////////////////////////////
   // Tasks for Target Abort
   ///////////////////////////////////////////////////////////////////////////
   task TABORT_SET;
      begin
         @(posedge pci_clk);
         reg_abort <= 1'b1;
         @(posedge pci_clk);
      end
   endtask
   
   task TABORT_FREE;
      begin    
         @(posedge pci_clk); 
         reg_abort <= 1'b0; 
         @(posedge pci_clk); 
      end 
   endtask 

   ///////////////////////////////////////////////////////////////////////////
   // Tasks for Target Interrupt A
   ///////////////////////////////////////////////////////////////////////////
   task TINTA_SET;
      begin
         @(posedge pci_clk);
         reg_inta <= 1'b0;
         @(posedge pci_clk);
      end
   endtask
   
   task TINTA_FREE;
      begin    
         @(posedge pci_clk); 
         reg_inta <= 1'b1; 
         @(posedge pci_clk); 
      end 
   endtask 

djpeg_fpga u_djpeg_fpga(
    .PCI_RST      ( pci_rst       ),
    .PCI_CLK      ( pci_clk       ),
                        
    .PCI_FRAME_N  ( pci_frame_n   ),
    .PCI_IDSEL    ( pci_idsel     ),
    .PCI_DEVSEL_N ( pci_devsel_n  ),
    .PCI_IRDY_N   ( pci_irdy_n    ),
    .PCI_TRDY_N   ( pci_trdy_n    ),
    .PCI_STOP_N   ( pci_stop_n    ),
                        
    .PCI_CBE      ( pci_cbe       ),
    .PCI_AD       ( pci_ad        ),
    .PCI_PAR      ( pci_par       ),
                        
    .PCI_SERR_N   ( pci_serr_n    ),
    .PCI_PERR_N   ( pci_perr_n    ),
    .PCI_INTA_N   ( pci_inta_n    ),

        .LED            ( LED   )
);
   
 
        ///////////////////////////////////////////////////////////////////////////
        // Begin the actual simulation sequence
        ///////////////////////////////////////////////////////////////////////////
        initial begin
      
        $readmemh("test.mem", TEST.pci_rom);
      
      T_SystemReset;
      wait(End_Of_Config == 1);

      //////////////////////////////////////////////////////////////////////
      // Main Task
      //////////////////////////////////////////////////////////////////////
      
      $display("==========================================================");
      $display(" Start Simulation");
      $display("==========================================================");
      

                #100000;

                WRITE32(32'h2004001C,32'h00000000);
                repeat (10) @(posedge pci_clk);
                WRITE32(32'h2004001C,32'h00000001);

                READCMP32(32'h20040008,{28'hXXXXXXX,4'b1XXX});

                i = 0;
                while(!TEST.u_djpeg_fpga.u_jpeg_decode.u_jpeg_regdata.DataEnd) begin
                        READCMP32(32'h20040008,{28'hXXXXXXX,4'bX0XX});
                        WRITE32(32'h2004000C,pci_rom[i]);
                        i=i+1;
                end

//              WRITE32(32'h20040000,32'h00000001);
    
//              repeat (100) @(posedge pci_clk);

                READCMP32(32'h20040008,{28'hXXXXXXX,4'b1XXX});
                //while(!(u_jpeg_decode.OutPixelX == u_jpeg_decode.OutWidth -1 & u_jpeg_decode.OutPixelY == u_jpeg_decode.OutHeight -1 & count > 1000)) @(posedge clk);

      $display("==========================================================");
      $display(" End Jpeg Decode");
      $display("==========================================================");

                @(posedge pci_clk);

                fp = $fopen("sim.dat");
                READ32(32'h20040010);
                $fwrite(fp,"%0d\n",256);
                $fwrite(fp,"%0d\n",256);
      
                for(i=0;i<256*256;i=i+1) begin
                        READ32(32'h20000000+i*4);
                        $fwrite(fp,"%06x\n",read_data[23:0]);
                end
                $fclose(fp);

      $display("==========================================================");
      $display(" Finish Smiulation");
      $display("==========================================================");

                $finish();
        end
endmodule
