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
// Receives commands from the serial port. The first byte is the commands
// opcode, the following (optional) four byte are the command data.
// Commands that do not have the highest bit in their opcode set are
// considered short commands without data (1 byte long). All other commands are
// long commands which are 5 bytes long.
//
// After a full command has been received it will be kept available for 10 cycles
// on the op and data outputs. A valid command can be detected by checking if the
// execute output is set. After 10 cycles the registers will be cleared
// automatically and the receiver waits for new data from the serial port.
//
//////////////////////////////////////////////////////////////////////////////////

module 	receiver (
		input rx,
		input clock,		// 100Mhz clock
		input trxClock,		// scaled clock
		input reset,
		output [7:0] op,
		output [31:0] data,
		output reg execute
	);
	parameter FREQ;			// scaled 
	parameter RATE;

	// Module contents
	
	// FSM states
	parameter INIT = 3'b000, WAITSTOP = 3'b001, WAITSTART = 3'b010, 
			  WAITBEGIN = 3'b011, READBYTE = 3'b100, 
			  ANALYZE = 3'b101, READY = 3'b110;

	// counter value for sampling a bit
	parameter BITLENGTH = FREQ / RATE;	// basic rate for sampling = 100M/28/RATE = 31 counts

//	wire counter, ncounter : integer range 0 to BITLENGTH;	-- clock prescaling counter
	reg [4:0] counter, ncounter;	// clock prescaling counter
	reg [3:0] bitcount, nbitcount; // count rxed bits of current byte
	reg [3:0] bytecount, nbytecount; // count rxed bytes of current command
	reg [2:0] state, nstate;		// receiver state
	reg [7:0] opcode, nopcode;	// opcode byte
	reg [31:0] dataBuf, ndataBuf; // data dword

	assign op = opcode;
	assign data = dataBuf;
	
	// sequential part of FSM
//	always @(posedge clock or posedge reset)
	always @(posedge trxClock or posedge reset)
	begin
		if (reset)
				state <= INIT;
		else
			begin
				counter <= ncounter;
				bitcount <= nbitcount;
				bytecount <= nbytecount;
				dataBuf <= ndataBuf;
				opcode <= nopcode;
				state <= nstate;
			end
	end
	
	// combinational next state logic of FSM
//	always @(trxClock, state, counter, bitcount, bytecount, dataBuf, opcode, rx)
	always @(*)
	begin
	case (state)

		INIT :			// reset uart
			begin
				ncounter <= 0;
				nbitcount <= 0;
				nbytecount <= 0;
				nopcode <= 0;
				ndataBuf <= 0;
				nstate <= WAITSTOP;
			end

		WAITSTOP :		// wait for stop bit
			begin
				ncounter <= 0;
				nbitcount <= 0;
				nbytecount <= bytecount;
				nopcode <= opcode;
				ndataBuf <= dataBuf;
				if (rx)
					nstate <= WAITSTART;
				else
					nstate <= state;
			end

		WAITSTART :		// wait for start bit
			begin
				ncounter <= 0;
				nbitcount <= 0;
				nbytecount <= bytecount;
				nopcode <= opcode;
				ndataBuf <= dataBuf;
				if (!rx)
					nstate <= WAITBEGIN;
				else
					nstate <= state;
			end

		WAITBEGIN :		// wait for first half of start bit
			begin
				nbitcount <= 0;
				nbytecount <= bytecount;
				nopcode <= opcode;
				ndataBuf <= dataBuf;
				if (counter == (BITLENGTH / 2))
					begin
						ncounter <= 0;
						nstate <= READBYTE;
					end
				else //if (trxClock)	// advance counter based on scaled clock
					begin
							ncounter <= counter + 1;
							nstate <= state;
					end
//				else
//					begin
//							ncounter <= counter;
//							nstate <= state;
//					end
			end

		READBYTE :		// start reading a byte
			begin
				if (counter == BITLENGTH)	// reach sample point
					begin
						ncounter <= 0;		// reset counter
						nbitcount <= bitcount + 1;
						if (bitcount == 8)	// all 8 bits received
							begin
								nbytecount <= bytecount + 1;
								nopcode <= opcode;
								ndataBuf <= dataBuf;
								nstate <= ANALYZE;	// analyze the byte
							end
						else			
							begin
								nbytecount <= bytecount;
								if (bytecount == 0) // receiving opcode
									begin
										nopcode <= {rx, opcode[7:1]};	// shift in bit
										ndataBuf <= dataBuf;
									end
								else				// receiving data
									begin
										nopcode <= opcode;
										ndataBuf <= {rx, dataBuf[31:1]};// shift in bit
									end
								nstate <= state;
							end
					end
				else						// not yet reach sample point
					begin
//						if (trxClock)	// advance counter based on scaled clock
							ncounter <= counter + 1;
//						else
//							ncounter <= counter;
							
						nbitcount <= bitcount;
						nbytecount <= bytecount;
						nopcode <= opcode;
						ndataBuf <= dataBuf;
						nstate <= state;
					end
			end

		ANALYZE :		// check if long or short command has been fully received
			begin
				ncounter <= 0;
				nbitcount <= 0;
				nbytecount <= bytecount;
				nopcode <= opcode;
				ndataBuf <= dataBuf;
				
				if (opcode[7] == 1'b0) 		// a short command
					nstate <= READY;
				else if (bytecount == 5)	// long command with all 5 bytes received
					nstate <= READY;
				else
					nstate <= WAITSTOP;		// continue receiving
			
			end

		READY :		// done, give 10 cycles for processing
			begin
				ncounter <= counter + 1;
				nbitcount <= 0;
				nbytecount <= 0;
				nopcode <= opcode;
				ndataBuf <= dataBuf;
//				if (counter == 1) 
					nstate <= INIT;
//				else					
//					nstate <= state;		// execute will be high for 10 cycles
			end

		default :
			begin
				nstate <= state;
			end
	endcase
	end	
	
	always @(state)
	begin
		if (state == READY)
			execute <= 1;
		else
			execute <= 0;
	end
	
endmodule
