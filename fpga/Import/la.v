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
// Logic Analyzer top level module. It connects the core with the hardware
// dependend IO modules and defines all inputs and outputs that represent
// phyisical pins of the fpga.
//
// It defines two constants FREQ and RATE. The first is the clock frequency 
// used for receiver and transmitter for generating the proper baud rate.
// The second defines the speed at which to operate the serial port.
//
//////////////////////////////////////////////////////////////////////////////////

module la (
		input resetSwitch,
		input xtalClock,
		input exClock,
		input [31:0] dataInput,
		output ready50,
		input rx,
		output tx,	// why inout in original design?
		input [1:0] speedSwitch,

//for debugging
		output clock,
		output trxClock,
		output [39:0] cmd, 
		output execute
	);


parameter FREQ = 100000000;		// 100MHz
parameter TRXSCALE = 28;		// 100M / 28 /115200 = 31 (5 bits)
parameter RATE = 115200;		// baud rate

//wire clock, trxClock;
//wire [39:0] cmd;
//wire execute;
wire send, busy;
wire [31:0] dataOutput;
wire [31:0] memoryIn, memoryOut;
wire read, write;

// Module contents

	clockman1 clockman0 (.inclk0(xtalClock), .c0(clock));

	eia232 eia232_0 (
		.clock(clock),
		.reset(resetSwitch),
		.speed(speedSwitch),
		.rx(rx),
		.tx(tx),
		.cmd(cmd),
		.execute(execute),
		.data(dataOutput),
		.send(send),
		.busy(busy),
		
		.trxClock(trxClock)
	);
	defparam eia232_0.FREQ = FREQ;
	defparam eia232_0.SCALE = TRXSCALE;
	defparam eia232_0.RATE = RATE;

	core core0 (
		.clock(clock),
		.extReset(resetSwitch),
		.cmd(cmd),
		.execute(execute),
		.dataInput(dataInput),
		.inputClock(exClock),
		.sampleReady50(ready50),
		.dataOutput(dataOutput),
		.outputSend(send),
		.outputBusy(busy),
		.memoryIn(memoryIn),
		.memoryOut(memoryOut),
		.memoryRead(read),
		.memoryWrite(write)
	);

	// interface to m4kRAM32x8k
	m4kram ram0 (
		.clock(clock),
		.dataInput(memoryOut),
		.dataOutput(memoryIn),
		.read(read),
		.write(write)
	);

endmodule
