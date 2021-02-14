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
// The core contains all "platform independent" modules and provides a
// simple interface to those components. The core makes the analyzer
// memory type and computer interface independent.
//
// This module also provides a better target for test benches as commands can
// be sent to the core easily.
//
//////////////////////////////////////////////////////////////////////////////////

module 	core (
		input clock,
		input extReset,
		input [39:0] cmd,
		input execute,
		input [31:0] dataInput,
		input inputClock,
		output sampleReady50,
		output [31:0] dataOutput,
		output outputSend,
		input outputBusy,
		input [31:0] memoryIn,
		output [31:0] memoryOut,
		output memoryRead,
		output memoryWrite
	);

	// module contents

	wire [7:0] opcode;
	wire [31:0] data;
	wire [31:0] sample, syncedInput;
	wire sampleClock;
	wire run, reset;
	wire [3:0] wrtrigmask, wrtrigval, wrtrigcfg;
	wire wrDivider, wrsize, arm, resetCmd;
	wire flagDemux, flagFilter, flagExternal, flagInverted, wrFlags, sampleReady;

	assign opcode = cmd[7:0];
	assign data = cmd[39:8];
	assign reset = extReset || resetCmd;


//	this module was incorporated into flags.v, as it sometimes breaks timing requirement 
//	In Quartus 7.0, it's OK but failed in 7.1
/*
	// select between internal and external sampling clock
	mux2to1 mux0 (
		.data0(clock),
		.data1(inputClock),
		.sel(flagExternal),
		.result(sampleClock));
*/

	decoder decoder0 (
		.opcode(opcode),
		.execute(execute),
		.clock(clock),
		.wrtrigmask(wrtrigmask),
		.wrtrigval(wrtrigval),
		.wrtrigcfg(wrtrigcfg),
		.wrspeed(wrDivider),
		.wrsize(wrsize),
		.wrFlags(wrFlags),
		.arm(arm),
		.reset(resetCmd)
	);

	flags flags0 (
		.data(data[7:0]),
		.clock(clock),
		.write(wrFlags),
		.demux(flagDemux),
		.filter(flagFilter),
		.external(flagExternal),
		.inverted(flagInverted),
		
		.inputClock(inputClock),
		.sampleClock(sampleClock)
	);


	sync sync0 (
		.dataInput(dataInput),
		.clock(sampleClock),
		.enableFilter(flagFilter),
		.enableDemux(flagDemux),
		.falling(flagInverted),
		.dataOutput(syncedInput)
	);

	sampler sampler0 (
		.dataInput(syncedInput),	// 32 input channels
		.clock(clock),				// internal clock
		.exClock(inputClock),		// use sampleClock?
		.external(flagExternal),	// clock selection
		.data(data[23:0]),			// configuration data
		.wrDivider(wrDivider),		// write divider register
		.sample(sample),			// sampled data
		.ready(sampleReady),		// new sample ready
		.ready50(sampleReady50)		// low rate sample signal with 50% duty cycle
	);

	trigger trigger0 (
		.dataInput(sample),
		.inputReady(sampleReady),
		.data(data),
		.clock(clock),
		.reset(reset),
		.wrMask(wrtrigmask),
		.wrValue(wrtrigval),
		.wrConfig(wrtrigcfg),
		.arm(arm),
		.demuxed(flagDemux),
		.run(run)
	);


	controller controller0 (
		.clock(clock),
		.reset(reset),
		.dataInput(sample),
		.inputReady(sampleReady),
		.run(run),
		.wrSize(wrsize),
		.data(data),
		.busy(outputBusy),
		.send(outputSend),
		.dataOutput(dataOutput),
		.memoryIn(memoryIn),
		.memoryOut(memoryOut),
		.memoryRead(memoryRead),
		.memoryWrite(memoryWrite)
	);

	
endmodule
