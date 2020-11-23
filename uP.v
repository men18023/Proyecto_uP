//Jonathan Menéndez 18023
//Electrónica Digital - Proyecto 2
//uP nibbler de 4 bits


// FlipFlops tipo D para uso de Fetch, Flags, Outputs
module FFD1(
	input clk, reset, enable, d,
	output reg q);

	always@(posedge clk, posedge reset)
	if (reset) q <= 0;
	else if (enable) q <= d;
	else q <= q;
endmodule

module FFD2(
	input clk, reset, enable,
	input [1:0] d,
	output reg [1:0] q);

	always@(posedge clk, posedge reset)
		if (reset)
		  q <= 2'b0;
		else if (enable)
			q <= d;
		else
			q <= q;
endmodule

module FFD4(
	input clk, reset, enable,
  input [3:0] d,
	output reg [3:0] q);

	always@(posedge clk, posedge reset)
		if (reset)
			q <= 3'b0;
		else if (enable)
			q <= d;
		else
			q <= q;
endmodule

module FFD8(
	input clk, reset, enable,
	input [7:0] d,
	output reg [7:0] q);

	always@(posedge clk, posedge reset)
		if (reset)
			q <= 8'b0;
		else if (enable)
			q <= d;
  	else
			q <= q;
endmodule

 // FliFlop tipo T para el phase
module FFT (
  input clk, reset, enable,
  output q);

  wire d;
  assign d = ~q; // se niega el fetch para utilizarlo luego como enable

      FFD1 T(clk, reset, enable, d, q);

endmodule

 // Program Counter
module COUNTER (
	input clk, reset, enable, load, //inPC y loadPC
  input [0:11] data,      //12 bits de entrada y salida
  output reg [0:11] out);

  always @(posedge clk, posedge reset)
    if (~enable & ~load)
      out <= out;
    else if (reset)
      out <= 12'b0;
    else if (load)
      out <= data;
    else if (enable & ~load)
      out <= out + 12'b000000000001;

endmodule // contador

// Rom de instrucciones
module ROM (
  input [11:0] address,
  output [7:0] out); // parte de instr y oprnd que pasan al fetch

  reg [7:0] data [0:4095]; //numero de datos en la memoria

  initial begin
    $readmemh ("memory.list", data); //utiliza memoria con las instrucciones
  end
    assign out = data[address];

endmodule

// Buffer Tri-Estado para inputs y bus drivers
module BUFFTRI (
  input [3:0] a,
  input enable,
  output [3:0] y);  //para el data_bus

    assign y = enable ? a : 4'bz;

endmodule

// RAM
module RAM(
  input clk, we, cs,  //we = write enable ; cs = chip select
  input [11:0] address,
  input [3:0] in,
  output [3:0] out); // salida a un buffer

  reg [3:0] data [0:4095];

  always @ (posedge clk)
    if (cs & we) data[address] <= in;

  assign out = (cs&~we) ? data[address] : 4'bz;

endmodule

// Decoder
module DECODER (
  input wire [6:0] address,
  output reg [12:0] d);

  always @ ( address ) begin
    casex (address)  //casex para las instrucciones que van a la ALU
			//any
		7'bxxxxxx0: d <= 13'b1000000001000;
		  //JC = Jump if carry
    7'b00001x1: d <= 13'b0100000001000;
    7'b00000x1: d <= 13'b1000000001000;
			//JNC = Jump if not carry
    7'b00011x1: d <= 13'b1000000001000;
    7'b00010x1: d <= 13'b0100000001000;
			//CMP1
    7'b0010xx1: d <= 13'b0001001000010;
			//CMPM
    7'b0011xx1: d <= 13'b1001001100000;
			//LIT
    7'b0100xx1: d <= 13'b0011010000010;
			//IN
    7'b0101xx1: d <= 13'b0011010000100;
			//LD
    7'b0110xx1: d <= 13'b1011010100000;
			//ST
    7'b0111xx1: d <= 13'b1000000111000;
			//JZ
    7'b1000x11: d <= 13'b0100000001000;
    7'b1000x01: d <= 13'b1000000001000;
			//JNZ
    7'b1001x11: d <= 13'b1000000001000;
    7'b1001x01: d <= 13'b0100000001000;
			//ADDI
    7'b1010xx1: d <= 13'b0011011000010;
			//ADDM
    7'b1011xx1: d <= 13'b1011011100000;
			//JMP
    7'b1100xx1: d <= 13'b0100000001000;
			//OUT
    7'b1101xx1: d <= 13'b0000000001001;
			//NANDI
    7'b1110xx1: d <= 13'b0011100000010;
			//NANDM
    7'b1111xx1: d <= 13'b1011100100000;
    endcase
  end
endmodule

// ALU
module ALU (
  input reset,
  input [3:0] a, b,
  input [2:0] f,
  output reg [3:0] y,
  output reg c, zeta);

  parameter Pa = 3'b000; // se definen terminos para simplificar el case
  parameter Pb = 3'b010;
  parameter CMP = 3'b001;
  parameter ADD = 3'b011;
  parameter NOR = 3'b100;

  always @(*) begin
    c = 0;
		case(f)
      Pa: y = a;
      Pb: y = b;
      CMP: begin
            {c, y} = a-b; // necesario concatenar
           end
      ADD: begin
            {c, y} = a+b; // necesario concatenar
           end
      NOR: y = a~|b;
      default: y = 3'b0;
    endcase

  if (y == 0)
    zeta = 1;
  else
    zeta = 0;
  if (reset == 1)
    c = 0;
					  end
endmodule

// uP implementado con todos los módulos anteriores
module uP(
  input clock, reset, //entradas y salidas para el modulo completo
  input [3:0] pushbuttons,
  output phase, c_flag, z_flag,
  output [3:0] instr, oprnd, accu, data_bus, FF_out,
  output [7:0] program_byte,
  output [11:0] PC, address_RAM);


  wire [11:0] PC;  // Wire del nibbler y sus respectivos modulos
  wire enable_pc, load_pc;
  wire [7:0] program_byte;
  wire [3:0] instr, oprnd;
  wire we, cs;
	wire [3:0] data_bus;
  wire busA;
	wire [11:0] address_RAM;
	assign address_RAM = {oprnd, program_byte};
	wire [3:0] accu, res;
	wire enable_accu;
  wire [2:0] f;
  wire c, zeta;
  wire busB;
  wire enable_inputs;
	wire enable_outputs;
	wire phase;
	wire [1:0] flags;
  wire e_flags, c_flag, z_flag;
  assign c_flag = flags[1];
  assign z_flag = flags[0];
		//llamado a todos los modulos y su interconexion con los wires de arriba
  COUNTER counter(clock, reset, enable_pc, load_pc, address_RAM, PC);
  ROM rom(PC, program_byte);
  FFD8 fetch(clock, reset, ~phase, program_byte, {instr, oprnd});
	DECODER decoder({instr, flags, phase}, {enable_pc, load_pc, enable_accu, e_flags,
									f[2], f[1], f[0], cs, we, busB, enable_inputs, busA, enable_outputs});
  BUFFTRI FbusA(oprnd, busA, data_bus);
	RAM ram(clock, we, cs, address_RAM, data_bus, data_bus);
  FFD4 Faccu(clock, reset, enable_accu, res, accu);
  ALU alu(reset, accu, data_bus, f, res, c, zeta);
  BUFFTRI FbusB(res, busB, data_bus);
  BUFFTRI inputs(pushbuttons, enable_inputs, data_bus);
  FFD4 outputs(clock, reset, enable_outputs, data_bus, FF_out);
  FFT Fphase(clock, reset, 1'b1, phase);
  FFD2 Fflags(clock, reset, e_flags, {c, zeta}, flags);

endmodule
