/*
* PROJECT: AQUAXIS JPEG DECODER
* ----------------------------------------------------------------------
*
* aq_djpeg_idct.v
* Copyright (C)2006-2011 H.Ishihara
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
* For further information please contact.
*   http://www.aquaxis.com/
*   info(at)aquaxis.com or hidemi(at)sweetcafe.jp
*
* 1.01 2006/10/01 1st Release
* 2.00 2008/03/19 Replace to RAM from D-FF
*/
`timescale 1ps / 1ps

module aq_djpeg_idct(
    rst,
    clk,

    ProcessInit,

    DataInEnable,
    DataInRead,
    DataInAddress,
    DataInA,
    DataInB,

    DataOutEnable,
    DataOutPage,
    DataOutCount,
    Data0Out,
    Data1Out
);

    input               rst;
    input               clk;

    input               ProcessInit;

    input               DataInEnable;
    output              DataInRead;
    output [4:0]        DataInAddress;
    input [15:0]        DataInA;
    input [15:0]        DataInB;

    output              DataOutEnable;
    output [2:0]        DataOutPage;
    output [1:0]        DataOutCount;
    output [8:0]        Data0Out;
    output [8:0]        Data1Out;

    wire                DctXEnable;
    wire [2:0]          DctXPage;
    wire [1:0]          DctXCount;
    wire [31:0]         DctXData0r;
    wire [31:0]         DctXData1r;

    aq_djpeg_idct_calc u_jpeg_idctx(
        .rst            ( rst           ),
        .clk            ( clk           ),

        .DataInEnable   ( DataInEnable  ),
        .DataInRead     ( DataInRead    ),
        .DataInAddress  ( DataInAddress ),
        .DataInA        ( DataInA       ),
        .DataInB        ( DataInB       ),

        .DataOutEnable  ( DctXEnable    ),
        .DataOutPage    ( DctXPage      ),
        .DataOutCount   ( DctXCount     ),
        .Data0Out       ( DctXData0r    ),
        .Data1Out       ( DctXData1r    )
    );

    wire            DctBEnable;
    wire            DctBRead;
    wire [4:0]      DctBAddress;
    wire [15:0]     DctBDataA;
    wire [15:0]     DctBDataB;

    aq_djpeg_idctb u_jpeg_idctb(
        .rst            ( rst               ),
        .clk            ( clk               ),

        .DataInit       ( ProcessInit       ),

        .DataInEnable   ( DctXEnable        ),
        .DataInPage     ( DctXPage          ),
        .DataInCount    ( DctXCount         ),
        .DataInIdle     ( DctBIdle          ),
        .DataInA        ( DctXData0r[26:11] ),
        .DataInB        ( DctXData1r[26:11] ),

        .DataOutEnable  ( DctBEnable        ),
        .DataOutRead    ( DctBRead          ),
        .DataOutAddress ( DctBAddress       ),
        .DataOutA       ( DctBDataA         ),
        .DataOutB       ( DctBDataB         )

    );

    wire [31:0] Data0OutW, Data1OutW;

    aq_djpeg_idct_calc u_jpeg_idcty(
        .rst            ( rst           ),
        .clk            ( clk           ),

        .DataInEnable   ( DctBEnable    ),
        .DataInRead     ( DctBRead      ),
        .DataInAddress  ( DctBAddress   ),
        .DataInA        ( DctBDataA     ),
        .DataInB        ( DctBDataB     ),

        .DataOutEnable  ( DataOutEnable ),
        .DataOutPage    ( DataOutPage   ),
        .DataOutCount   ( DataOutCount  ),
        .Data0Out       ( Data0OutW     ),
        .Data1Out       ( Data1OutW     )
    );

    assign Data0Out = Data0OutW[23:15];
    assign Data1Out = Data1OutW[23:15];

endmodule
