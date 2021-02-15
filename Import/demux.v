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
// Demultiplexes 16 input channels into 32 output channels,
// thus doubling the sampling rate for those channels.
//
// This module barely does anything anymore, but is kept for historical reasons.
// 
//////////////////////////////////////////////////////////////////////////////////

module 	demux (
		input [15:0] dataInput,
		input [15:0] dataInput180,
		input clock,
		output reg [31:0] dataOutput
	);

/* original VHDL design
	output(15 downto 0) <= input;
	
	process (clock)
	begin
		if rising_edge(clock) then
			output(31 downto 16) <= input180;
		end if;
	end process;
*/

//	assign dataOutput = {dataInput180, dataInput};

	always @(posedge clock)
	begin
		dataOutput <= {dataInput180, dataInput};
	end

endmodule
