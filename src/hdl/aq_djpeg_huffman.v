/*
* PROJECT: AQUAXIS JPEG DECODER
* ----------------------------------------------------------------------
*
* aq_djpeg_huffman.v
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
* 2.00 2008/03/05 Replace Ziguzagu source
*/
`timescale 1ps / 1ps

module aq_djpeg_huffman(
    rst,
    clk,

    // Init
    ProcessInit,

    // DQT Table
    DqtInEnable,
    DqtInColor,
    DqtInCount,
    DqtInData,

    // DHT Table
    DhtInEnable,
    DhtInColor,
    DhtInCount,
    DhtInData,

    // Huffman Table
    HuffmanTableEnable, // Table Data In Enable
    HuffmanTableColor,  // Huffman Table Color Number
    HuffmanTableCount,  // Table Number
    HuffmanTableCode,   // Huffman Table Code
    HuffmanTableStart,  // Huffman Table Start Number

    // Huffman Decode
    DataInRun,          // Data In Start
    DataInEnable,       // Data In Enable
    DataIn,             // Data In

    DecodeUseBit,       // Used Data Bit
    DecodeUseWidth,     // Used Data Width

    // Data Out
    DataOutEnable,
    DataOutColor,
    DataOutRead,
    DataOutAddress,
    DataOutA,
    DataOutB
);

    input           rst;
    input           clk;

    input           ProcessInit;

    // DQT Table
    input           DqtInEnable;
    input           DqtInColor;
    input [5:0]     DqtInCount;
    input [7:0]     DqtInData;

    // DHT Table
    input           DhtInEnable;
    input [1:0]     DhtInColor;
    input [7:0]     DhtInCount;
    input [7:0]     DhtInData;

    input           HuffmanTableEnable; // Table Data In Enable
    input [1:0]     HuffmanTableColor;
    input [3:0]     HuffmanTableCount;  // Table Number
    input [15:0]    HuffmanTableCode;   // Huffman Table Data
    input [7:0]     HuffmanTableStart;  // Huffman Table Start Number

    input           DataInRun;
    input           DataInEnable;       // Data In Enable
    input [31:0]    DataIn;             // Data In

    output          DecodeUseBit;
    output [6:0]    DecodeUseWidth;

    // Data Out
    output          DataOutEnable;
    output [2:0]    DataOutColor;
    input           DataOutRead;
    input [4:0]     DataOutAddress;
    output [15:0]   DataOutA;
    output [15:0]   DataOutB;

    wire            HmDqtColor;
    wire [5:0]      HmDqtNumber;
    wire [7:0]      HmDqtData;

    // DQT Table
    aq_djpeg_dqt u_jpeg_dqt(
        .rst            ( rst               ),
        .clk            ( clk               ),

        .DataInEnable   ( DqtInEnable       ),
        .DataInColor    ( DqtInColor        ),
        .DataInCount    ( DqtInCount[5:0]   ),
        .DataIn         ( DqtInData         ),

        .TableColor     ( HmDqtColor        ),
        .TableNumber    ( HmDqtNumber       ),
        .TableData      ( HmDqtData         )
    );

    wire [1:0]      HmDhtColor;
    wire [7:0]      HmDhtNumber;
    wire [3:0]      HmDhtZero;
    wire [3:0]      HmDhtWidth;

    aq_djpeg_dht u_jpeg_dht(
        .rst            ( rst           ),
        .clk            ( clk           ),

        .DataInEnable   ( DhtInEnable   ),
        .DataInColor    ( DhtInColor    ),
        .DataInCount    ( DhtInCount    ),
        .DataIn         ( DhtInData     ),

        .ColorNumber    ( HmDhtColor    ),
        .TableNumber    ( HmDhtNumber   ),
        .ZeroTable      ( HmDhtZero     ),
        .WidhtTable     ( HmDhtWidth    )
    );

    wire [5:0]      HmDecCount;
    wire [15:0]     HmDecData;

    wire            HmOutEnable;
    wire [2:0]      HmOutColor;

    aq_djpeg_hm_decode u_jpeg_hm_decode(
        .rst                ( rst                   ),
        .clk                ( clk                   ),

        // Huffman Table
        .HuffmanTableEnable ( HuffmanTableEnable    ),
        .HuffmanTableColor  ( HuffmanTableColor     ),
        .HuffmanTableCount  ( HuffmanTableCount     ),
        .HuffmanTableCode   ( HuffmanTableCode      ),
        .HuffmanTableStart  ( HuffmanTableStart     ),

        // Huffman Decode
        .DataInRun          ( DataInRun             ),
        .DataInEnable       ( DataInEnable          ),
        .DataIn             ( DataIn                ),

        // Huffman Table List
        .DhtColor           ( HmDhtColor            ),
        .DhtNumber          ( HmDhtNumber           ),
        .DhtZero            ( HmDhtZero             ),
        .DhtWidth           ( HmDhtWidth            ),

        // DQT Table
        .DqtColor           ( HmDqtColor            ),
        .DqtNumber          ( HmDqtNumber           ),
        .DqtData            ( HmDqtData             ),

        .DataOutIdle        ( HmOutIdle             ),
        .DataOutEnable      ( HmOutEnable           ),
        .DataOutColor       ( HmOutColor            ),

        // Output decode data
        .DecodeUseBit       ( DecodeUseBit          ),
        .DecodeUseWidth     ( DecodeUseWidth        ),

        .DecodeEnable       ( HmDecEnable           ),
        .DecodeColor        (                       ),
        .DecodeCount        ( HmDecCount            ),
        .DecodeZero         (                       ),
        .DecodeCode         ( HmDecData             )
        );

    // Ziguzagu to iDCTx Matrix
    aq_djpeg_ziguzagu u_jpeg_ziguzagu(
        .rst                ( rst               ),
        .clk                ( clk               ),

        .DataInit           ( ProcessInit       ),
        .HuffmanEndEnable   ( HmOutEnable       ),

        .DataInEnable       ( HmDecEnable       ),
        .DataInAddress      ( HmDecCount        ),
        .DataInColor        ( HmOutColor        ),
        .DataInIdle         ( HmOutIdle         ),
        .DataIn             ( HmDecData         ),

        .DataOutEnable      ( DataOutEnable     ),
        .DataOutRead        ( DataOutRead       ),
        .DataOutAddress     ( DataOutAddress    ),
        .DataOutColor       ( DataOutColor      ),
        .DataOutA           ( DataOutA          ),
        .DataOutB           ( DataOutB          )
    );
endmodule
