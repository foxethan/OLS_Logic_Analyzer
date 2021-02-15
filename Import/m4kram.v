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
// Simple m4k block (32-bit x 8k) interface.
//
//////////////////////////////////////////////////////////////////////////////////

module 	m4kram (
		input clock,
		input [31:0] dataInput,
		output [31:0] dataOutput,
		input read,
		input write
	);

	reg [17:0] address;

	m4kRAM32x8k m4k0 (
		.address(address),
		.clock(clock),
		.data(dataInput),
		.wren(write),
		.q(dataOutput)
		);
	
	//memory address controller
	always @(posedge clock)
	begin
		if (write) 
			address <= address + 1;
		else if (read)
			address <= address - 1;
	end
	
endmodule
