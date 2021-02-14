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
// Fast 32 channel digital noise filter using a single LUT function for each
// individual channel. It will filter out all pulses that only appear for half
// a clock cycle. This way a pulse has to be at least 5-10ns long to be accepted
// as valid. This is sufficient for sample rates up to 100MHz.
//
//////////////////////////////////////////////////////////////////////////////////

module 	filter (
		input [31:0] dataInput,
		input [31:0] dataInput180,
		input clock,
		output [31:0] dataOutput
	);

	reg [31:0] dataInput360, dataInput180Delay, result;
	
	assign dataOutput = result;

	always @(posedge clock)
	begin
	
		// determine next result
// original design, but why? any special reasons		
//		integer i;
//		for (i = 0; i < 32; i = i + 1)
//			begin
//				result[i] <= (result[i] || dataInput360[i] || dataInput[i]) && dataInput180Delay[i];
//			end

		result <= (result | dataInput360 | dataInput) & dataInput180Delay;

		// shift in input data
		dataInput360 <= dataInput;
		dataInput180Delay <= dataInput180;
	end


endmodule
