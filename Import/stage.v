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
// Programmable 32 channel trigger stage. It can operate in serial
// and parallel mode. In serial mode any of the input channels
// can be used as input for the 32bit shift register. Comparison
// is done using the value and mask registers on the input in
// parallel mode and on the shift register in serial mode.
// If armed and 'level' has reached the configured minimum value,
// the stage will start to check for a match.
// The match and run output signal delay can be configured.
// The stage will disarm itself after a match occured or when reset is set.
//
// The stage supports "high speed demux" operation in serial and parallel
// mode. (Lower and upper 16 channels contain a 16bit sample each.)
//
// Matching is done using a pipeline. This should not increase the minimum
// time needed between two dependend trigger stage matches, because the
// dependence is evaluated in the last pipeline step.
// It does however increase the delay for the capturing process, but this
// can easily be compensated by software.
// (By adjusting the before/after ratio.)
//////////////////////////////////////////////////////////////////////////////////

module stage
	(
		input [31:0] dataInput,
		input inputReady,
		input [31:0] data,
		input clock,
		input reset,
		input wrMask,
		input wrValue,
		input wrConfig,
		input arm,
		input [1:0] level,
		input demuxed,
		output reg run,
		output reg match
	);

	// FSM states
	parameter OFF = 2'b00, ARMED = 2'b01, MATCHED = 2'b10;

	// Module contents

	reg [31:0] maskRegister, valueRegister, configRegister;
	reg [31:0] intermediateRegister, shiftRegister;
	wire [31:0] testValue;
	wire cfgStart, cfgSerial;
	wire [4:0] cfgChannel;
	wire [1:0] cfgLevel;
	wire [15:0] cfgDelay;
	reg [15:0] counter; 
	wire matchL16, matchH16;
	reg match32Register;
	reg [1:0] state;
	reg serialChannelL16, serialChannelH16;
	
	// assign configuration bits to more meaningful signal names
	assign cfgStart = configRegister[27];
	assign cfgSerial = configRegister[26];
	assign cfgChannel = configRegister[24:20];
	assign cfgLevel = configRegister[17:16];
	assign cfgDelay = configRegister[15:0];

	// use shift register or input depending on configuration
	assign testValue = (cfgSerial) ? shiftRegister : dataInput;

	// apply mask and value and create a additional pipeline step
	always @(posedge clock)
	begin
		intermediateRegister <= (testValue ^ valueRegister) & maskRegister;
	end

	// match upper and lower word separately
	assign matchL16 = (intermediateRegister[15:0] == 0) ? 1 : 0;
	assign matchH16 = (intermediateRegister[31:16] == 0) ? 1 : 0;

	// in demux mode only one half must match, in normal mode both words must match
	always @(posedge clock)
	begin
		if (demuxed)
			match32Register <= matchL16 || matchH16;
		else 
			match32Register <= matchL16 && matchH16;
	end

	// select serial channel based on cfgChannel
	always @(dataInput, cfgChannel)
	begin
		integer i;
		for (i = 0; i < 16 ; i = i + 1)
			begin
				// conv_integer in VHDL
				// if (conv_integer(cfgChannel[3:0]) == i)
				if (cfgChannel[3:0] == i)
					begin
						serialChannelL16 <= dataInput[i];
						serialChannelH16 <= dataInput[i + 16];
					end
			end
	end

	// shift in bit from selected channel whenever input is ready
	always @(posedge clock)
	begin
		if (inputReady)
			if (demuxed)	// in demux mode two bits come in per sample
				shiftRegister <= {shiftRegister[29:0], serialChannelH16, serialChannelL16};
			else if (cfgChannel[4])
				shiftRegister <= {shiftRegister[30:0], serialChannelH16};
			else
				shiftRegister <= {shiftRegister[30:0], serialChannelL16};
	end 

	// trigger state machine
	always @(posedge clock or posedge reset)
	begin
		if (reset)
			state <= OFF;
		else
			begin
				run <= 0;
				match <= 0;

				case (state) 
					OFF : 
						if (arm) 
							state <= ARMED;

					ARMED :
						if (match32Register && (level >= cfgLevel))
							begin
								counter <= cfgDelay;	// wait for delay
								state <= MATCHED;
							end

					MATCHED :
						if (inputReady)
							begin	// if cfgStart = 1, run immediately, otherwise, set match = 1;
								if (counter == 0)	// delay done
									begin		
										run <= cfgStart;
										match <= ~cfgStart;
										state <= OFF;
									end
								else
									counter <= counter - 1;
							end
				endcase 
			end
	end

	// handle mask, value & config register write requests
	always @(posedge clock) 
	begin
		if (wrMask)
			maskRegister <= data;
		if (wrValue)
			valueRegister <= data;
		if (wrConfig)
			configRegister <= data;
	end

endmodule
