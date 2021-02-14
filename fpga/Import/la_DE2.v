module la_DE2 (
    ////////////////////////    Clock Input     ////////////////////////
    input           CLOCK_50,               //  50 MHz
    input           EXT_CLOCK,              //  External Clock
    ////////////////////////    Push Button     ////////////////////////
//  input   [3:0]   KEY,                    //  Pushbutton[3:0]
    ////////////////////////    DPDT Switch     ////////////////////////
//  input   [17:0]  SW,                     //  Toggle Switch[17:0]
    ////////////////////////    7-SEG Dispaly   ////////////////////////
//  output  [0:6]   HEX0,                   //  Seven Segment Digit 0
//  output  [0:6]   HEX1,                   //  Seven Segment Digit 1
//  output  [0:6]   HEX2,                   //  Seven Segment Digit 2
//  output  [0:6]   HEX3,                   //  Seven Segment Digit 3
//  output  [0:6]   HEX4,                   //  Seven Segment Digit 4
//  output  [0:6]   HEX5,                   //  Seven Segment Digit 5
//  output  [0:6]   HEX6,                   //  Seven Segment Digit 6
//  output  [0:6]   HEX7,                   //  Seven Segment Digit 7
    ////////////////////////////    LED     ////////////////////////////
//  output  [8:0]   LEDG,                   //  LED Green[8:0]
//  output  [17:0]  LEDR,                   //  LED Red[17:0]
    ////////////////////////////    UART    ////////////////////////////
    output          UART_TXD,               //  UART Transmitter
    input           UART_RXD,               //  UART Receiver
    ////////////////////////    SRAM Interface  ////////////////////////
//  inout   [15:0]  SRAM_DQ,                //  SRAM Data bus 16 Bits
//  output  [17:0]  SRAM_ADDR,              //  SRAM Address bus 18 Bits
//  output          SRAM_UB_N,              //  SRAM High-byte Data Mask 
//  output          SRAM_LB_N,              //  SRAM Low-byte Data Mask 
//  output          SRAM_WE_N,              //  SRAM Write Enable
//  output          SRAM_CE_N,              //  SRAM Chip Enable
//  output          SRAM_OE_N,              //  SRAM Output Enable
    ////////////////////////    GPIO    ////////////////////////////////
//  inout   [35:0]  GPIO_0,                 //  GPIO Connection 0
    inout   [35:0]  GPIO_1                  //  GPIO Connection 1

//for debugging
//  output clock,
//  output trxClock
    );


// Module contents

wire resetSwitch, xtalClock, exClock, ready50, rx, tx;
wire [1:0] speedSwitch;

/*
wire [17:0] ramA;
wire ramWE;
wire ramOE;
wire [15:0] ramIO1;
wire ramCE1;
wire ramUB1;
wire ramLB1;
wire [15:0] ramIO2;
wire ramCE2;
wire ramUB2;
wire ramLB2;
*/

assign xtalClock = CLOCK_50;
assign rx = UART_RXD;
assign UART_TXD = tx;
//assign resetSwitch = ~KEY[3]; // H/W reset switch
assign resetSwitch = 1'b0;
//assign speedSwitch = SW[17:16];   // LL = 115200, LH = 57600, HL = 38400, HH = 19200
assign speedSwitch = 1'b00;


//assign LEDG[0] = exClock;         // external clock indicator
//assign LEDG[2] = ready50;         // sample ready50 indicator
//assign LEDR[17:16] = speedSwitch; // speed switch indicator

// SRAM interface
//assign SRAM_DQ = ramIO1;
//assign SRAM_ADDR = ramA;
//assign SRAM_WE_N = ramWE;
//assign SRAM_OE_N = ramOE;
//assign SRAM_CE_N = ramCE1;
//assign SRAM_UB_N = ramUB1;
//assign SRAM_LB_N = ramLB1;

// display last op and data on HEX display
//reg [39:0] op;
//always @(posedge clock or negedge KEY[3])
//begin
//  if (!KEY[3])
//      op <= 0;
//  else if (cmd[7:0] != 0)
//      op <= cmd;
//end

//seg7 opcode1 (op[7:4], HEX5); 
//seg7 opcode0 (op[3:0], HEX4);
//seg7 data0 (KEY[2]?op[23:20]:op[39:36], HEX1);    
//seg7 data1 (KEY[2]?op[19:16]:op[35:32], HEX0);    
//seg7 data2 (KEY[2]?op[15:12]:op[31:28], HEX3);    
//seg7 data3 (KEY[2]?op[11:8]:op[27:24], HEX2); 

// for debugging
wire [39:0] cmd;
wire execute;

//wire [31:0] testsample;
//tester tester0 (.clock(clock), .data(testsample));

assign exClock = EXT_CLOCK;
//assign LEDG[1] = execute;

// end debugging
 

    la la0(
        .resetSwitch(resetSwitch),
        .xtalClock(xtalClock),
//      .exClock(EXT_CLOCK),
        .dataInput(GPIO_1[31:0]),
        .exClock(exClock),
//      .dataInput(testsample),
        .ready50(ready50),
        .rx(rx),
        .tx(tx),
        .speedSwitch(speedSwitch),
//      .ramIO1(ramIO1),
//      .ramIO2(ramIO2),
//      .ramA(ramA),
//      .ramWE(ramWE),
//      .ramOE(ramOE),
//      .ramCE1(ramCE1),
//      .ramUB1(ramUB1),
//      .ramLB1(ramLB1),
//      .ramCE2(ramCE2),
//      .ramUB2(ramUB2),
//      .ramLB2(ramLB2),

//for debugging
        .clock(clock),
        .trxClock(trxClock),
        .cmd(cmd),
        .execute(execute)
    );  

endmodule
