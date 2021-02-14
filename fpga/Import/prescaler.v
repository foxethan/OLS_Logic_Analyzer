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
// Shared prescaler for transmitter and receiver timings.
// Used to control the transfer speed.
//
//////////////////////////////////////////////////////////////////////////////////

module prescaler (
		input clock,
		input reset,
		input [1:0]	div,
		output reg scaled
	);
	parameter SCALE;

	// Module contents

//	range 0 to (6 * SCALE)-1
	reg [7:0] counter;
		
	always @(posedge clock or posedge reset)
	begin
		if (reset)
			begin
				counter <= 0;
			end
		else
			begin
				if ((div == 2'b00) && (counter == SCALE - 1) ||			// 115200
					(div == 2'b01) && (counter == 2 * SCALE - 1) ||		// 57600
					(div == 2'b10) && (counter == 3 * SCALE - 1) ||		// 38400
					(div == 2'b11) && (counter == 6 * SCALE - 1)) 		// 19200
					begin
						counter <= 0;
						scaled <= 1'b1;			// scaled output clock
					end
				else
					begin
						counter <= counter + 1;
					scaled <= 1'b0;
					end
			end
	end
	
endmodule
