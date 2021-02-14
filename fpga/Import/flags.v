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
// Flags register.
//
// I moved the MUX to generate sampleClock in this module as the timing requirement
// could not be fulfilled in Quartus 7.1 (but OK in 7.0?)
//
//////////////////////////////////////////////////////////////////////////////////

module 	flags (
		input [7:0] data,
		input clock,
		input write,
		output reg demux,
		output reg filter,
		output reg external,
		output reg inverted,
		
		input inputClock,
		output sampleClock
	);

	// mux to generate the sampleClock signal
	assign sampleClock = external ? inputClock : clock;

	// set flags
	always @(posedge clock)
	begin
		if (write)
			begin
				demux <= data[0];
				filter <= data[1];
				external <= data[6];
				inverted <= data[7];
			end
	end
	
endmodule
