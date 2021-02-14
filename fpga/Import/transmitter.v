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
// Takes 32bit (one sample) and sends it out on the serial port.
// End of transmission is signalled by taking back the busy flag.
// Supports xon/xoff flow control.
//
//////////////////////////////////////////////////////////////////////////////////

module 	transmitter (
	input [31:0] data,
	input [3:0] disabledGroups,
	input write,
	input id,
	input xon,
	input xoff,
	input clock,
	input trxClock,
	input reset,
	output tx,
	output reg busy
//	output pause
	);
	parameter FREQ;
	parameter RATE;
	
	// Module contents
	parameter IDLE = 2'b00, SEND = 2'b01, POLL = 2'b10;
	parameter BITLENGTH = FREQ / RATE;

	reg [31:0] dataBuffer;
	reg [3:0] disabledBuffer;
	reg [9:0] txBuffer;
	reg [7:0] dataByte;
	reg [4:0] counter;
	reg [3:0] bits;
	reg [2:0] bytes;
	reg [1:0] state;
	reg paused, writeByte, byteDone, disabled;

//	assign pause <= paused;
	assign tx = txBuffer[0];	// send from bit 0
	
	// control mechanism for sending a 32 bit word
	always @(posedge clock or posedge reset)
	begin
		if (reset)
			begin
				writeByte <= 0;
				state <= IDLE;
				dataBuffer <= 0;
				disabledBuffer <= 0;
			end
		else
			begin
				if ((state != IDLE) || (write) || (paused))
					busy <= 1;
				else
					busy <= 0;
					
				case (state)
				
					// when write is '1', data will be available with next cycle
					IDLE :
						begin
							if (write)
								begin
									dataBuffer <= data;
									disabledBuffer <= disabledGroups;
									bytes <= 0;
									state <= SEND;
								end
							else if (id == 1)	// request for ID
								begin
									dataBuffer <= 32'h534c4131;	// send device ID
									disabledBuffer <= 0;
									bytes <= 0;
									state <= SEND;
								end
						end

					// sending data, send least significant byte/bit first
					SEND :
						begin
							if (bytes == 4)	// all 4 data bytes sent
								begin
									state <= IDLE;
								end
							else
								begin
									bytes <= bytes + 1;
									case (bytes)
										0 :
											begin
												dataByte <= dataBuffer[7:0];
												disabled <= disabledBuffer[0];
											end
										1 :
											begin
												dataByte <= dataBuffer[15:8];
												disabled <= disabledBuffer[1];
											end
										2 :
											begin
												dataByte <= dataBuffer[23:16];
												disabled <= disabledBuffer[2];
											end
										default :
											begin
												dataByte <= dataBuffer[31:24];
												disabled <= disabledBuffer[3];
										end
									endcase

									writeByte <= 1;		// init write one byte
									state <= POLL;
								end
						end

					// wait for completion of sending one byte
					POLL :
						begin
							writeByte <= 0;
							if ((byteDone) && (!writeByte) && (!paused))
							state <= SEND;
						end
				endcase

			end
	end

	// send one data byte
	always @(posedge clock)
	begin
		if (writeByte) // start sending a byte
			begin
				counter <= 0;
				bits <= 0;
				byteDone <= disabled;				// skip that group
				txBuffer <= {1'b1, dataByte, 1'b0};	// stop bit + data + start bit
			end
		else if (counter == BITLENGTH)	// one bit send
			begin
				counter <= 0;	// reset counter for next bit
				txBuffer <= {1'b1, txBuffer[9:1]};	// shift bits to left
				if (bits == 10)
					byteDone <= 1;
				else
					bits <= bits + 1;
			end
		else if (trxClock)
			begin
				counter <= counter + 1;
			end
	end
	
	// set paused mode according to xon/xoff commands
	always @(posedge clock or posedge reset)
	begin
		if (reset)
			begin
				paused <= 0;
			end
		else
			begin
				if (xon) 
					paused <= 0;
				else if (xoff)
					paused <= 1;
			end
	end
	
endmodule
