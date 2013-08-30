/*
* PROJECT: AQUAXIS JPEG DECODER
* ----------------------------------------------------------------------
*
* aq_djpeg_dqt.v
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
*/
`timescale 1ps / 1ps

module aq_djpeg_dqt(
    rst,
    clk,

    DataInEnable,
    DataInColor,
    DataInCount,
    DataIn,

    TableColor,
    TableNumber,
    TableData
);

    input           rst;
    input           clk;

    input           DataInEnable;
    input           DataInColor;
    input [5:0]     DataInCount;
    input [7:0]     DataIn;

    input           TableColor;
    input  [5:0]    TableNumber;
    output [7:0]    TableData;

    // RAM
    reg [7:0]       DQT_Y [0:63];
    reg [7:0]       DQT_C [0:63];

    // RAM
    always @(posedge clk) begin
        if(DataInEnable ==1'b1 && DataInColor ==1'b0) begin
            DQT_Y[DataInCount] <= DataIn;
        end
        if(DataInEnable ==1'b1 && DataInColor ==1'b1) begin
            DQT_C[DataInCount] <= DataIn;
        end
    end

    reg [7:0] TableDataY;
    reg [7:0] TableDataC;

    // RAM out
    always @(posedge clk) begin
        TableDataY <= DQT_Y[TableNumber];
        TableDataC <= DQT_C[TableNumber];
    end

    // Selector
    assign TableData = (TableColor)?TableDataC:TableDataY;

endmodule
