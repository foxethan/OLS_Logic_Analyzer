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
// Produces samples from input applying a programmable divider to the clock.
// Sampling rate can be calculated by:
//
//     r = f / (d + 1)
//
// Where r is the sampling rate, f is the clock frequency and d is the value
// programmed into the divider register.
//
// As of version 0.6 sampling on an external clock is also supported. If external
// is set '1', the external clock will be used to sample data. (Divider is
// ignored for this.)
//
//////////////////////////////////////////////////////////////////////////////////

module 	sampler (
		input [31:0] dataInput,	// 32 input channels
		input clock,		// internal clock
		input exClock,		// external clock
		input external,		// clock selection
		input [23:0] data,	// configuration data
		input wrDivider,	// write divider register
		output reg [31:0] sample,	// sampled data
		output reg ready,		// new sample ready
		output reg ready50		// low rate sample signal with 50% duty cycle
	);

	reg [23:0] divider, counter;
	reg lastExClock, syncExClock;

	// sample data
	always @(posedge clock)
	begin
		syncExClock <= exClock;
		if (wrDivider)
			begin
				divider <= data[23:0];
				counter <= 0;
				ready <= 0;
			end
		else if (external)
			begin
				if (!syncExClock && lastExClock)
					begin
	//					sample <= {dataInput[31:10], exClock, lastExClock, dataInput[7:0]};
						ready <= 1;
					end
				else
					begin
						sample <= dataInput;
						ready <= 0;
					end
				lastExClock <= syncExClock;
			end
		else if (counter == divider)
			begin
				sample <= dataInput;
				counter <= 0;
				ready <= 1;
			end
		else
			begin
				counter <= counter + 1;
				ready <= 0;
			end
	end

	// generate ready50 50% duty cycle sample signal
	always @(posedge clock)
	begin
		if (counter == divider)
			ready50 <= 1;
		else if (counter[22:0] == divider[23:1])
			ready50 <= 0;
	end

endmodule
