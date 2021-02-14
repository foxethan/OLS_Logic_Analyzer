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
// Takes the opcode from the command received by the receiver and decodes it.
// The decoded command will be executed for one cycle.
//
// The receiver keeps the cmd output active long enough so all the
// data is still available on its cmd output when the command has
// been decoded and sent out to other modules with the next
// clock cycle. (Maybe this paragraph should go in receiver.vhd?)
//
//////////////////////////////////////////////////////////////////////////////////

module 	decoder (
		input [7:0] opcode,
		input execute,
		input clock,
		output reg [3:0] wrtrigmask,
		output reg [3:0] wrtrigval,
		output reg [3:0] wrtrigcfg,
		output reg wrspeed,
		output reg wrsize,
		output reg wrFlags,
		output reg arm,
		output reg reset
	);

	wire exe;
	reg exeReg;

	assign exe = execute;
	
	always @(posedge clock)
	begin
		reset <= 0;
		arm <= 0;
		wrspeed <= 0;
		wrsize <= 0;
		wrFlags <= 0;
		wrtrigmask <= 0;
		wrtrigval <= 0;
		wrtrigcfg <= 0;
		
		if (exe && !exeReg)		// rising edge
			begin
				case (opcode)
					8'h00 : reset <= 1;
					8'h01 : arm <= 1;
					8'h80 : wrspeed <= 1;
					8'h81 : wrsize <= 1;
					8'h82 : wrFlags <= 1;
					8'hC0 : wrtrigmask[0] <= 1'b1;
					8'hC1 : wrtrigval[0] <= 1'b1;
					8'hC2 : wrtrigcfg[0] <= 1'b1;
					8'hC4 : wrtrigmask[1] <= 1'b1;
					8'hC5 : wrtrigval[1] <= 1'b1;
					8'hC6 : wrtrigcfg[1] <= 1'b1;
					8'hC8 : wrtrigmask[2] <= 1'b1;
					8'hC9 : wrtrigval[2] <= 1'b1;
					8'hCA : wrtrigcfg[2] <= 1'b1;
					8'hCC : wrtrigmask[3] <= 1'b1;
					8'hCD : wrtrigval[3] <= 1'b1;
					8'hCE : wrtrigcfg[3] <= 1'b1;
				endcase
			end
			
		exeReg <= exe;
	end
	
endmodule
