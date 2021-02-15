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
// Synchronizes input with clock on rising or falling edge and does some
// optional preprocessing. (Noise filter and demux.)
//
//////////////////////////////////////////////////////////////////////////////////

module 	sync (
		input [31:0] dataInput,
		input clock,
		input enableFilter,
		input enableDemux,
		input falling,
		output reg [31:0] dataOutput
	);

	wire [31:0] filteredInput, demuxedInput;
	reg [31:0] synchronizedInput, synchronizedInput180;

	demux demux0 (
		.dataInput(synchronizedInput[15:0]),
		.dataInput180(synchronizedInput180[15:0]),
		.clock(clock),
		.dataOutput(demuxedInput)
	);

	filter filter0 (
		.dataInput(synchronizedInput),
		.dataInput180(synchronizedInput180),
		.clock(clock),
		.dataOutput(filteredInput)
	);


	// synch input guarantees use of iob ff on spartan 3 (as filter and demux do)
	always @(posedge clock)
	begin
		synchronizedInput <= dataInput;
	end

	always @(negedge clock)
	begin
		synchronizedInput180 <= dataInput;
	end

	// add another pipeline step for input selector to not decrease maximum clock rate
	always @(posedge clock)
	begin
		if (enableDemux)
			dataOutput <= demuxedInput;
		else if (enableFilter)
			dataOutput <= filteredInput;
		else if (falling)
			dataOutput <= synchronizedInput180;
		else
			dataOutput <= synchronizedInput;
	end

endmodule
