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
// Controls the capturing & readback operation.
// 
// If no other operation has been activated, the controller samples data
// into the memory. When the run signal is received, it continues to do so
// for fwd * 4 samples and then sends bwd * 4 samples  to the transmitter.
// This allows to capture data from before the trigger match which is a nice 
// feature.
//
//////////////////////////////////////////////////////////////////////////////////

module 	controller (
		input clock,
		input reset,
		input [31:0] dataInput,
		input inputReady,
		input run,
		input wrSize,
		input [31:0] data,
		input busy,
		output send,
		output [31:0] dataOutput,
		input [31:0] memoryIn,
		output [31:0] memoryOut,
		output reg memoryRead,
		output reg memoryWrite
	);

	// FSM states
	parameter SAMPLE = 2'b00, DELAY = 2'b01, READ = 2'b10, READWAIT = 2'b11;
	
	reg [15:0] fwd, bwd;
	reg [17:0] ncounter, counter;
	reg [1:0] nstate, state;
	reg sendReg;
	
	assign dataOutput = memoryIn;
	assign memoryOut = dataInput;
	assign send = sendReg;
	
	// synchronization and reset logic
	// (run, clock, reset) in original design ? 
	always @(posedge clock or posedge reset)
	begin
		if (reset)
			state <= SAMPLE;
		else
			begin
				state <= nstate;
				counter <= ncounter;
			end
	end
	
	// FSM to control the controller action
	always @(state, run, counter, fwd, inputReady, bwd, busy)
	begin
		case (state)
		
			// default mode, keep sampling from input to memory
			SAMPLE :
				begin
					if (run)	// start capure
						nstate <= DELAY;
					else
						nstate <= state;
						
					ncounter <= 0;
					memoryWrite <= inputReady;
					memoryRead <= 0;
					sendReg <= 0;
				end
				
			// keep sampling for 4 * fwd + 4 samples after run condition
			DELAY :
				begin
					if (counter == {fwd, 2'b11})	// start reading data
						begin
							ncounter <= 0;
							nstate <= READ;
						end
					else							// keep sampling for 4 * fwd + 4 samples
						begin
							if (inputReady)
								ncounter <= counter + 1;
							else
								ncounter <= counter;
								
							nstate <= state;
						end
						
					memoryWrite <= inputReady;
					memoryRead <= 0;
					sendReg <= 0;					
				end
			
			// read back 4 * bwd + 4 samples after DELAY
			// go into wait state after each sample to give transmitter time
			READ :
				begin
					if (counter == {bwd, 2'b11})	// read DONE
						begin
							ncounter <= 0;
							nstate <= SAMPLE;
						end
					else
						begin
							ncounter <= counter + 1;
							nstate <= READWAIT;
						end
					memoryWrite <= 0;
					memoryRead <= 1;
					sendReg <= 1;					
				end
				
			// wait for the transmitter to become ready again
			READWAIT :
				begin
					if (!busy && !sendReg)	// send next
						nstate <= READ;
					else
						nstate <= state;
						
					ncounter <= counter;
					memoryWrite <= 0;
					memoryRead <= 0;
					sendReg <= 0;					
				end
		endcase
	end

	// set speed and size registers if indicated
	always @(posedge clock)
	begin
		if (wrSize)
			begin
				fwd <= data[31:16];
				bwd <= data[15:0];
			end
	end
		
endmodule
