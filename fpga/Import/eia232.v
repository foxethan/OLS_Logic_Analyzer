//////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2006 Michael Poppitz
//
// Original design by Michael Poppitz in VHDL
// Converted to Verilog (with minor modifications) by Kenneth Tsang
// 
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
//
//////////////////////////////////////////////////////////////////////////////////
//
// Details: http://www.sump.org/projects/analyzer/
//
// EIA232 aka RS232 interface.
//
//////////////////////////////////////////////////////////////////////////////////

module eia232 (
	input clock,
	input reset,
	input [1:0] speed,
	input rx,
	output tx,
	output [39:0] cmd,
	output execute,
	input [31:0] data,
	input send,
	output busy,

// for debugging
	output trxClock
	);
	parameter FREQ = 100000000;		// 100MHz
	parameter SCALE = 28;			// 100M / 28 /115200 = 31 (5 bits)
	parameter RATE = 115200;		// baud rate
	
	// Module contents

	parameter TRXFREQ = FREQ / SCALE;	// reduced rx & tx clock for receiver and transmitter

//	wire trxClock;
	wire executeReg;
	reg executePrev, id, xon, xoff, wrFlags;
	reg [3:0] disabledGroupsReg;
	wire [7:0] opcode;
	wire [31:0] opdata;
	
	prescaler prescaler0 (
		.clock(clock),
		.reset(reset),
		.div(speed),
		.scaled(trxClock)				// scaled clock output
	);
	defparam prescaler0.SCALE = SCALE;
	
	receiver receiver0 (
		.rx(rx),
		.clock(clock),
		.trxClock(trxClock),
		.reset(reset),
		.op(opcode),
		.data(opdata),
		.execute(executeReg)
	);
	defparam receiver0.FREQ = TRXFREQ;
	defparam receiver0.RATE = RATE;

	transmitter transmitter0 (
		.data(data),
		.disabledGroups(disabledGroupsReg),
		.write(send),
		.id(id),
		.xon(xon),
		.xoff(xoff),
		.clock(clock),
		.trxClock(trxClock),
		.reset(reset),
		.tx(tx),
		.busy(busy)
	);
	defparam transmitter0.FREQ = TRXFREQ;
	defparam transmitter0.RATE = RATE;

	assign cmd = {opdata, opcode};	// byte3, byte2, by byte1, byte0, opcode
	assign execute = executeReg;
	
	// process special uart commands that do not belong in core decoder
	always @(posedge clock)
	begin
		id <= 1'b0;
		xon <= 1'b0;
		xoff <= 1'b0;
		wrFlags <= 1'b0;
		executePrev <= executeReg;
		if ((executePrev == 1'b0) && (executeReg == 1'b1))	// rising edge (execute will be high for 10 cycles
		begin
			case (opcode)
				8'h02: id <= 1'b1;		// signal last for one cycle only
				8'h11: xon <= 1'b1;
				8'h13: xoff <= 1'b1;
				8'h82: wrFlags <= 1'b1;
			endcase
		end
	end
	
	always @(posedge clock)
	begin
		if (wrFlags == 1'b1)
		begin			
			disabledGroupsReg <= opdata[5:2];	// get dissabledGroups flags
		end
	end
	
endmodule

