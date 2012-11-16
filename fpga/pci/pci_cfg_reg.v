`timescale 1ns/10ps

module pci_cfg_reg
  (
   // Config
   bar0_enable,
   bar1_enable,
   bar2_enable,
   bar3_enable,
   bar4_enable,
   bar5_enable,
   ebar_enable,
   
   // Signals
   rst,
   clk,
   adi,
   cbeid,
   rom_adr,
   oe_rom,
   oe_bar,
   oe_ebar,
   oe_cmdr,
   oe_intr,
   we_bar,
   we_ebar,
   we_statr,
   we_cmdr,
   we_intr,
   t_abort,
//   set_mdperr,
   sig_serr,
   det_perr,
   first_cyc,
   acc_io,
   acc_mem,
   
   bar_hit,
   ebar_hit,
   bar_size,
   ebar_size,
   
   cfg_ado,
   
   cfg_ioen,
   cfg_memen,
   
   perr_en,
   serr_en
   );
   
   // Parameter
   parameter       bar0_ena      = 1'b1;
   parameter       bar0_map      = 1'b0;
   parameter       bar0_adrs_map = 32'hfff80000;
   parameter       bar0_width    = 13;
   
   parameter       bar1_ena      = 1'b0;
   parameter       bar1_map      = 1'b0;
   parameter       bar1_adrs_map = 32'hffffff01;
   parameter       bar1_width    = 16'd24;
   
   parameter       bar2_ena      = 1'b0;
   parameter       bar2_map      = 1'b1;
   parameter       bar2_adrs_map = 32'hffffff01;
   parameter       bar2_width    = 16'd24;
   
   parameter       bar3_ena      = 1'b0;
   parameter       bar3_map      = 1'b1;
   parameter       bar3_adrs_map = 32'hffffff01;
   parameter       bar3_width    = 16'd24;
   
   parameter       bar4_ena      = 1'b0;
   parameter       bar4_map      = 1'b1;
   parameter       bar4_adrs_map = 32'hffffff01;
   parameter       bar4_width    = 16'd24;
   
   parameter       bar5_ena      = 1'b0;
   parameter       bar5_map      = 1'b1;
   parameter       bar5_adrs_map = 32'hffffff01;
   parameter       bar5_width    = 16'd24;
   
   parameter       ebar_ena      = 1'b0;
   parameter       ebar_map      = 1'b1;
   parameter       ebar_adrs_map = 32'hffffff01;
   parameter       ebar_width    = 16'd24;
   
   parameter       vendor_id     = 16'h1234;
   parameter       device_id     = 16'h5678;
   
   parameter       subvendor_id  = 16'h1234;
   parameter       subdevice_id  = 16'h5678;
   
   parameter       cap_ptr       = 8'b00000000;
   parameter       max_lat       = 8'b00100000;
   parameter       min_gnt       = 8'b00000100;
   
   parameter       int_pin       = 8'b00000001;  // 0x00: no int, 0x01: inta
   parameter       int_line      = 8'b00000000;
   
   parameter       command_init  = 16'h0000;
   parameter       status_init   = 16'h0200;
   
   // class id & subclass & interface
   parameter       class_id      = {8'h02,8'h00,8'h00};
   parameter       rev_id        = 8'h10;
   
   // Config
   output          bar0_enable;
   output          bar1_enable;
   output          bar2_enable;
   output          bar3_enable;
   output          bar4_enable;
   output          bar5_enable;
   output          ebar_enable;

   assign          bar0_enable = bar0_ena;
   assign          bar1_enable = bar1_ena;
   assign          bar2_enable = bar2_ena;
   assign          bar3_enable = bar3_ena;
   assign          bar4_enable = bar4_ena;
   assign          bar5_enable = bar5_ena;
   assign          ebar_enable = ebar_ena;

   // signals
   input           rst,clk;
   input [31:0]    adi;
   input [3:0]     cbeid;
   input [3:0]     rom_adr;
   input           oe_rom;
   input [5:0]     oe_bar;
   input           oe_ebar,oe_cmdr,oe_intr;
   input [5:0]     we_bar;
   input           we_ebar,we_statr,we_cmdr,we_intr;
   // input        set_mdperr;
   input           t_abort,sig_serr,det_perr;
   input           first_cyc,acc_io,acc_mem;
   output [5:0]    bar_hit;
   output          ebar_hit;
   output [5:0]    bar_size;
   output          ebar_size;
   output [31:0]   cfg_ado;
   output          cfg_ioen,cfg_memen;
   output          perr_en,serr_en;
   
   reg [15:0]      commandreg;
   reg [15:0]      statusreg;
   reg [31:0]      bar0_adr;
   reg [31:0]      bar1_adr;
   reg [31:0]      bar2_adr;
   reg [31:0]      bar3_adr;
   reg [31:0]      bar4_adr;
   reg [31:0]      bar5_adr;
   reg [31:0]      ebar_adr;
   reg [7:0]       intline;
   
   wire [31:0]     romdata;
   
   wire [31:0]     cfg_ado;
   
   // command register
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         commandreg <= command_init;
      end else begin
         commandreg[15:10] <= 6'h00;
         commandreg[7]     <= 1'b0;
         commandreg[5:2]   <= 4'b0;
         if(we_cmdr == 1'b1) begin
            if(cbeid[0] == 1'b0) begin
               commandreg[1:0] <= adi[1:0];
//               commandreg[2]   <= 1'b0;   // master not supported
//               commandreg[3]   <= 1'b0;   // specitial cycle not supported
//               commandreg[4]   <= 1'b0;   // mwi not supported
//               commandreg[5]   <= 1'b0;
               commandreg[6]   <= adi[6];
//               commandreg[7]   <= 1'b0;   // stepping not supported
            end
            if(cbeid[1] == 1'b0) begin
//               commandreg[15:10] <= 6'b000000;
               commandreg[9:8]   <= adi[9:8];
            end
         end // if (we_cmdr == 1'b1)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   assign cfg_ioen = commandreg[0];
   assign cfg_memen = commandreg[1];
   // assign spec_cyc = commandreg[3];
   assign perr_en = commandreg[6];
   // assign stepping_en = commandreg[7];
   assign serr_en = commandreg[8];

   // status register
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         statusreg <= status_init;
      end else begin
         statusreg[13:12] <= 2'b00;
         statusreg[10:0]  <= 11'h000;
         if(we_statr == 1'b1 & cbeid[0] == 1'b0) begin
            if(adi[15] == 1'b1) statusreg[15] <= 1'b0;
            if(adi[14] == 1'b1) statusreg[14] <= 1'b0;
            if(adi[11] == 1'b1) statusreg[11] <= 1'b0;
//            if(adi[ 8] == 1'b1) statusreg[ 8] <= 1'b0;
         end else begin
            if(det_perr   == 1'b1) statusreg[15] <= 1'b1;
            if(sig_serr   == 1'b1) statusreg[14] <= 1'b1;
            if(t_abort    == 1'b1) statusreg[11] <= 1'b1;
//            if(set_mdperr == 1'b1) statusreg[ 8] <= 1'b1;
         end // else: !if(we_statr == 1'b1 & cbeid[0] == 1'b0)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)

   // bar0 register
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         bar0_adr <= 32'h00000000;
      end else begin
         if(we_bar[0] == 1'b1) begin
            if(cbeid[0] == 1'b0) begin
               bar0_adr[7:0]   <= adi[7:0];
            end
            if(cbeid[1] == 1'b0) begin
               bar0_adr[15:8]  <= adi[15:8];
            end
            if(cbeid[2] == 1'b0) begin
               bar0_adr[23:16] <= adi[23:16];
            end
            if(cbeid[3] == 1'b0) begin
               bar0_adr[31:24] <= adi[31:24];
            end
         end // if (we_bar[0] == 1'b1)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   assign bar_hit[0] = bar0_enable == 1'b1 & first_cyc == 1'b1 &
                       ((bar0_map == 1'b1 & acc_io == 1'b1) |
                        (bar0_map == 1'b0 & acc_mem == 1'b1)) &
                       adi[31:32-bar0_width] == bar0_adr[31:32-bar0_width];
   assign bar_size[0] = bar0_adr == 32'hffffffff;
   
   // bar1 register
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         bar1_adr <= 32'h00000000;
      end else begin
         if(we_bar[1] == 1'b1) begin
            if(cbeid[1] == 1'b0) begin
               bar1_adr[7:0] <= adi[7:0];
            end
            if(cbeid[1] == 1'b0) begin
               bar1_adr[15:8] <= adi[15:8];
            end
            if(cbeid[2] == 1'b0) begin
               bar1_adr[23:16] <= adi[23:16];
            end
            if(cbeid[3] == 1'b0) begin
               bar1_adr[31:24] <= adi[31:24];
            end
         end // if (we_bar[1] == 1'b1)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   assign bar_hit[1] = bar1_enable == 1'b1 & first_cyc == 1'b1 &
                       ((bar1_map == 1'b1 & acc_io == 1'b1) |
                        (bar1_map == 1'b0 & acc_mem == 1'b1)) &
                       adi[31:32-bar1_width] == bar2_adr[31:32-bar1_width];
   assign bar_size[1] = bar1_adr == 32'hffffffff;
   
   // bar2 register
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         bar2_adr <= 32'h00000000;
      end else begin
         if(we_bar[2] == 1'b1) begin
            if(cbeid[0] == 1'b0) begin
               bar2_adr[7:0] <= adi[7:0];
            end
            if(cbeid[1] == 1'b0) begin
               bar2_adr[15:8] <= adi[15:8];
            end
            if(cbeid[2] == 1'b0) begin
               bar2_adr[23:16] <= adi[23:16];
            end
            if(cbeid[3] == 1'b0) begin
               bar2_adr[31:24] <= adi[31:24];
            end
         end // if (we_bar[2] == 1'b1)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   assign bar_hit[2] = bar2_enable == 1'b1 & first_cyc == 1'b1 &
                       ((bar2_map == 1'b1 & acc_io == 1'b1) |
                        (bar2_map == 1'b0 & acc_mem == 1'b1)) &
                       adi[31:32-bar2_width] == bar2_adr[31:32-bar2_width];
   assign bar_size[2] = bar2_adr == 32'hffffffff;
   
   // bar3 register
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         bar3_adr <= 32'h00000000;
      end else begin
         if(we_bar[3] == 1'b1) begin
            if(cbeid[0] == 1'b0) begin
               bar3_adr[7:0] <= adi[7:0];
            end
            if(cbeid[1] == 1'b0) begin
               bar3_adr[15:8] <= adi[15:8];
            end
            if(cbeid[2] == 1'b0) begin
               bar3_adr[23:16] <= adi[23:16];
            end
            if(cbeid[3] == 1'b0) begin
               bar3_adr[31:24] <= adi[31:24];
            end
         end // if (we_bar[3] == 1'b1)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   assign bar_hit[3] = bar3_enable == 1'b1 & first_cyc == 1'b1 &
                       ((bar3_map == 1'b1 & acc_io == 1'b1) |
                        (bar3_map == 1'b0 & acc_mem == 1'b1)) &
                       adi[31:32-bar3_width] == bar3_adr[31:32-bar3_width];
   assign bar_size[3] = bar3_adr == 32'hffffffff;
   
   // bar4 register
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         bar4_adr <= 32'h00000000;
      end else begin
         if(we_bar[4] == 1'b1) begin
            if(cbeid[0] == 1'b0) begin
               bar4_adr[7:0] <= adi[7:0];
            end
            if(cbeid[1] == 1'b0) begin
               bar4_adr[15:8] <= adi[15:8];
            end
            if(cbeid[2] == 1'b0) begin
               bar4_adr[23:16] <= adi[23:16];
            end
            if(cbeid[3] == 1'b0) begin
               bar4_adr[31:24] <= adi[31:24];
            end
         end // if (we_bar[4] == 1'b1)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   assign bar_hit[4] = bar4_enable == 1'b1 & first_cyc == 1'b1 &
                       ((bar4_map == 1'b1 & acc_io == 1'b1) |
                        (bar4_map == 1'b0 & acc_mem == 1'b1)) &
                       adi[31:32-bar4_width] == bar4_adr[31:32-bar4_width];
   assign bar_size[4] = bar4_adr == 32'hffffffff;
   
   // bar5 register
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         bar5_adr <= 32'h00000000;
      end else begin
         if(we_bar[5] == 1'b1) begin
            if(cbeid[0] == 1'b0) begin
               bar5_adr[7:0] <= adi[7:0];
            end
            if(cbeid[1] == 1'b0) begin
               bar5_adr[15:8] <= adi[15:8];
            end
            if(cbeid[2] == 1'b0) begin
               bar5_adr[23:16] <= adi[23:16];
            end
            if(cbeid[3] == 1'b0) begin
               bar5_adr[31:24] <= adi[31:24];
            end
         end // if (we_bar[5] == 1'b1)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   assign bar_hit[5] = bar5_enable == 1'b1 & first_cyc == 1'b1 &
                       ((bar5_map == 1'b1 & acc_io == 1'b1) |
                        (bar5_map == 1'b0 & acc_mem == 1'b1)) &
                       adi[31:32-bar5_width] == bar5_adr[31:32-bar5_width];
   assign bar_size[5] = bar5_adr == 32'hffffffff;
   
   // ebar register
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         ebar_adr <= 32'h00000000;
      end else begin
         if(we_ebar == 1'b1) begin
            if(cbeid[0] == 1'b0) begin
               ebar_adr[7:0] <= adi[7:0];
            end
            if(cbeid[1] == 1'b0) begin
               ebar_adr[15:8] <= adi[15:8];
            end
            if(cbeid[2] == 1'b0) begin
               ebar_adr[23:16] <= adi[23:16];
            end
            if(cbeid[3] == 1'b0) begin
               ebar_adr[31:24] <= adi[31:24];
            end
         end // if (we_ebar == 1'b1)
      end // else: !if(!rst)
   end // always @ (posedge clk or negedge rst)
   assign ebar_hit = ebar_enable == 1'b1 & first_cyc == 1'b1 &
                       ((ebar_map == 1'b1 & acc_io == 1'b1) |
                        (ebar_map == 1'b0 & acc_mem == 1'b1)) &
                       adi[31:32-ebar_width] == ebar_adr[31:32-ebar_width];
   assign ebar_size = ebar_adr == 32'hffffffff;
   
   // interrupt register
   always @(posedge clk or negedge rst) begin
      if(!rst) begin
         intline <= 8'h00;
      end else begin
         if(we_intr == 1'b1 & cbeid[0] == 1'b0) begin
            intline[7:0] <= adi[7:0];
         end
      end
   end

   // configuration space read   
   function [31:0] cfg_adof;
      input         oe_cmdr;
      input [5:0]   oe_bar;
      input         oe_ebar,oe_intr;
      input         oe_rom;
      input [15:0]  commandreg,statusreg;
      input [31:0]  bar0_adr,bar1_adr,bar2_adr,bar3_adr,bar4_adr,bar5_adr;
      input [7:0]   intline;
      input [31:0]  romdata;

      begin
         case({oe_rom,oe_intr,oe_ebar,oe_bar,oe_cmdr})
           10'b0000000001: begin // Command Register
              cfg_adof = {statusreg,commandreg};
           end
           10'b0000000010: begin // BAR0
              cfg_adof = {bar0_adr[31:4],romdata[3:0]};
           end
           10'b0000000100: begin // BAR1
              cfg_adof = {bar1_adr[31:4],romdata[3:0]};
           end
           10'b0000001000: begin // BAR2
              cfg_adof = {bar2_adr[31:4],romdata[3:0]};
           end
           10'b0000010000: begin // BAR3
              cfg_adof = {bar3_adr[31:4],romdata[3:0]};
           end
           10'b0000100000: begin // BAR4
              cfg_adof = {bar4_adr[31:4],romdata[3:0]};
           end
           10'b0001000000: begin // BAR5
              cfg_adof = {bar5_adr[31:4],romdata[3:0]};
           end
           10'b0010000000: begin // EBAR_HIT
              cfg_adof[31:32-ebar_width] = ebar_adr[31:32-ebar_width];
              cfg_adof[31-ebar_width:1] = 0;
              cfg_adof[0] = ebar_adr[0];
           end
           10'b0100000000: begin
              cfg_adof = {max_lat,min_gnt,int_pin,int_line};
           end
           10'b1000000000: begin // ROM
              cfg_adof = romdata;
           end
           default: cfg_adof = 32'h00000000;
         endcase // case({oe_rom,oe_intr,oe_ebar,oe_bar,oe_cmdr})
      end
   endfunction // cfg_adof
   assign cfg_ado = cfg_adof(oe_cmdr,oe_bar,oe_ebar,oe_intr,oe_rom,
                             commandreg,statusreg,bar0_adr,bar1_adr,bar2_adr,
                             bar3_adr,bar4_adr,bar5_adr,intline,romdata);
   
   // configuration rom
   function [31:0] rom_data;
      input [3:0] rom_adr;

      case (rom_adr)
        4'h0:begin
           // device id + vendor id
           rom_data = {device_id,vendor_id};
        end
        4'h1:begin
           // unused (status & command)
           rom_data = 32'h00000000;
        end
        4'h2:begin
           // class id & subclass & interface & revision id
           rom_data = {class_id,rev_id};
        end
        4'h3:begin
           // bist + header type + latency timer + cache line size
           rom_data = 32'h00000000;
        end
        4'h4:begin
           rom_data = (bar0_ena)?bar0_adrs_map:32'd0;
        end
        4'h5:begin
           rom_data = (bar1_ena)?bar1_adrs_map:32'd0;
        end
        4'h6:begin
           rom_data = (bar2_ena)?bar2_adrs_map:32'd0;
        end
        4'h7:begin
           rom_data = (bar3_ena)?bar3_adrs_map:32'd0;
        end
        4'h8:begin
           rom_data = (bar4_ena)?bar4_adrs_map:32'd0;
        end
        4'h9:begin
           rom_data = (bar5_ena)?bar5_adrs_map:32'd0;
        end
        4'ha:begin
           // cis pointer
           rom_data = 32'h00000000;
        end
        4'hb:begin
           // subsystem device id + subsystem verndor id
           rom_data = {subdevice_id,subvendor_id};
        end
        4'hc:begin
           rom_data = (ebar_ena)?ebar_adrs_map:32'd0;
        end
        4'hd:begin
           rom_data = {24'h000000,cap_ptr};
        end
        4'he:begin
           rom_data = 32'h00000000;
        end
        4'hf:begin
           rom_data = {max_lat,min_gnt,int_pin,int_line};
        end
      endcase // case(rom_adr)
   endfunction // rom_data
   assign romdata = rom_data(rom_adr);
endmodule // pci_cfg_reg

  
