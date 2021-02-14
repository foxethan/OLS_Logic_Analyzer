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
// Complex 4 stage 32 channel trigger. 
//
// All commands are passed on to the stages. This file only maintains
// the global trigger level and it outputs the run condition if it is set
// by any of the stages.
// 
//////////////////////////////////////////////////////////////////////////////////

module 	trigger (
		input [31:0] dataInput,
		input inputReady,
		input [31:0] data,
		input clock,
		input reset,
		input [3:0] wrMask,
		input [3:0] wrValue,
		input [3:0] wrConfig,
		input arm,
		input demuxed,
		output reg run
	);

	wire [3:0] stageRun, stageMatch;
	reg [1:0] levelReg;

	// create stages
	generate
		genvar i;
		for (i = 0; i < 4; i = i + 1)
		begin: s
			stage stage0 (
				.dataInput(dataInput),
				.inputReady(inputReady),
				.data(data),
				.clock(clock),
				.reset(reset),
				.wrMask(wrMask[i]),
				.wrValue(wrValue[i]),
				.wrConfig(wrConfig[i]),
				.arm(arm),	
				.level(levelReg),
				.demuxed(demuxed),
				.run(stageRun[i]),
				.match(stageMatch[i])
			);
		end
	endgenerate

	// increase level on match
	always @(posedge clock or posedge arm)
	begin
		if (arm)
			levelReg <= 0;
		else if (| stageMatch)	// reduction, any stage matched
			levelReg <= levelReg + 1;
	end


	// if any of the stages set run, capturing starts
	always @(stageRun)
	begin
		run <= (| stageRun);	// reduction, any stage run
	end

endmodule
