/* Margareth Vela
Carné 19458
Sección: 20
*/
//Program counter
module counter(input wire clk, rst, enable, Load, input wire [11:0] Ld, output reg [11:0] PC);
  always @ (posedge clk, posedge rst) begin
    if (rst)
        PC <= 12'b0;
    else if (Load)
        PC <= Ld;
    else if (enable)
        PC <= PC + 1;
  end
endmodule

//Program ROM
module program_ROM(input wire [11:0] PC, output wire [7:0] program_byte);
  reg [7:0] memory [0:4095];
  initial begin
      $readmemh("memory.list", memory);
  end
  assign program_byte = memory[PC];
endmodule

//Fetch
module FETCH(input wire clk, rst, enable, input wire [7:0] program_byte, output wire [3:0] instr, oprnd);
  FF_D  G1(clk, rst, enable, program_byte[7], instr[3]);
  FF_D  G2(clk, rst, enable, program_byte[6], instr[2]);
  FF_D  G3(clk, rst, enable, program_byte[5], instr[1]);
  FF_D  G4(clk, rst, enable, program_byte[4], instr[0]);
  FF_D  G5(clk, rst, enable, program_byte[3], oprnd[3]);
  FF_D  G6(clk, rst, enable, program_byte[2], oprnd[2]);
  FF_D  G7(clk, rst, enable, program_byte[1], oprnd[1]);
  FF_D  G8(clk, rst, enable, program_byte[0], oprnd[0]);
endmodule

//Bus Driver
module Bus_Driver(input wire enable, input wire [3:0]oprnd, output wire [3:0] data_bus);
  assign data_bus = enable ? oprnd : 4'bz;
endmodule

//Accumulator
module Accumulator(input wire clk, rst, enable, input wire [3:0] d, output reg [3:0] accu);
  always @ (posedge clk, posedge rst, posedge enable) begin
    if(rst) begin
      accu <= 1'b0;
    end
    else if (enable) begin
      accu <= d;
    end
  end
endmodule

//ALU
module alu(input wire [3:0] A, B, input wire [2:0] F, output reg C, Z, output reg [3:0] Y);
  reg [4:0] Y1;

  always @(*) begin
    case(F)
      3'b000:   Y1 = A;
      3'b001:   Y1 = A - B;
      3'b010:   Y1 = B;
      3'b011:   Y1 = A + B;
      3'b100:   Y1 = {1'b0, A ~& B};
      default:  Y1 = 5'b0;
    endcase

    assign Y = Y1[3:0];
    assign C = Y1[4];
    assign Z = ~(Y1[3] | Y1[2] | Y1[1] | Y1[0]);

  end
endmodule

//FF tipo D de 1 bit
module FF_D(input wire clock, reset, enable, d, output reg Y);
  always @ (posedge clock, posedge reset) begin
    if(reset) begin
      Y <= 1'b0;
    end
    else if (enable) begin
      Y <= d;
    end
  end
endmodule

//PHASE
module PHASE(input wire clock, reset, enable, output wire phase);

  FF_D G1(clock, reset, enable, ~phase, phase);

endmodule

//Decoder
module Decoder(input wire [6:0]Address, output reg [12:0]Y);
  always @(Address) begin
    casex(Address)
      7'bxxxx_xx0: Y = 13'b1000_000_001000 ;//caso 1
      7'b0000_1x1: Y = 13'b0100_000_001000 ;//caso 2
      7'b0000_0x1: Y = 13'b1000_000_001000 ;//caso 3
      7'b0001_1x1: Y = 13'b1000_000_001000 ;//caso 4
      7'b0001_0x1: Y = 13'b0100_000_001000 ;//caso 5
      7'b0010_xx1: Y = 13'b0001_001_000010 ;//caso 6
      7'b0011_xx1: Y = 13'b1001_001_100000 ;//caso 7
      7'b0100_xx1: Y = 13'b0011_010_000010 ;//caso 8
      7'b0101_xx1: Y = 13'b0011_010_000100 ;//Caso 9
      7'b0110_xx1: Y = 13'b1011_010_100000 ;//caso 10
      7'b0111_xx1: Y = 13'b1000_000_111000 ;//caso 11
      7'b1000_x11: Y = 13'b0100_000_001000 ;//caso 12
      7'b1000_x01: Y = 13'b1000_000_001000 ;//caso 13
      7'b1001_x11: Y = 13'b1000_000_001000 ;//caso 14
      7'b1001_x01: Y = 13'b0100_000_001000 ;//caso 15
      7'b1010_xx1: Y = 13'b0011_011_000010 ;//caso 16
      7'b1011_xx1: Y = 13'b1011_011_100000 ;//caso 17
      7'b1100_xx1: Y = 13'b0100_000_001000 ;//caso 18
      7'b1101_xx1: Y = 13'b0000_000_001001 ;//caso 19
      7'b1110_xx1: Y = 13'b0011_100_000010 ;//caso 20
      7'b1111_xx1: Y = 13'b1011_100_100000 ;//caso 21
      default:    Y = 13'b1111111111111 ; // caso por default
    endcase
  end
endmodule

//RAM
module RAM(input wire enable, write, read, input wire [11:0]address_RAM, inout [3:0]data);
  reg [3:0] RAM [0:4095];
  reg [3:0]data_out;

  assign data = (enable & read & ~write) ? data_out:4'bz;
  //Escribir en la RAM
  always @ ( address_RAM or data or enable or write ) begin
    if (enable && write) begin
      RAM[address_RAM] = data;
    end
  end
  //Leer de la RAM
  always @ ( address_RAM or enable or write or read) begin
    if (enable && ~write && read) begin
      data_out = RAM[address_RAM];
    end
  end
endmodule

module out(input wire clock, reset, enable,input wire [3:0]d, output wire [3:0] FF_out);
  FF_D  G1(clock, reset, enable, d[3], FF_out[3]);
  FF_D  G2(clock, reset, enable, d[2], FF_out[2]);
  FF_D  G3(clock, reset, enable, d[1], FF_out[1]);
  FF_D  G4(clock, reset, enable, d[0], FF_out[0]);
endmodule

module Flags(input wire clock, reset, enable, C, Z, output wire c_flag, z_flag);
  FF_D  G1(clock, reset, enable, C, c_flag);
  FF_D  G2(clock, reset, enable, Z, z_flag);
endmodule

module uP(input wire clock, reset, input wire [3:0] pushbuttons, output wire phase, c_flag, z_flag, output wire [3:0] instr, oprnd, data_bus, FF_out, accu, output wire [7:0] program_byte, output wire [11:0] PC, address_RAM);

  wire C, Z;
  wire [3:0] ALU_out;
  wire [12:0] control_signals;

  assign  address_RAM = {oprnd, program_byte};

  counter       counter(clock, reset, control_signals[12], control_signals[11], address_RAM, PC);
  program_ROM   program_ROM(PC, program_byte);
  FETCH         FETCH(clock, reset, ~phase, program_byte, instr, oprnd);
  Bus_Driver    Bus_Driver1(control_signals[1], oprnd, data_bus);
  Accumulator   Accumulator(clock, reset, control_signals[10], ALU_out, accu);
  alu           ALU(accu, data_bus, {control_signals[8], control_signals[7], control_signals[6]}, C, Z, ALU_out);
  Bus_Driver    Bus_Driver2(control_signals[3], ALU_out, data_bus);
  PHASE         Phase(clock, reset, 1'b1 , phase);
  Flags         Flags(clock, reset, control_signals[9], C, Z, c_flag, z_flag);
  Decoder       Decode({instr, c_flag, z_flag, phase}, control_signals);
  RAM           RAM(control_signals[5], control_signals[4], control_signals[5], address_RAM, data_bus);
  out           Out(clock, reset, control_signals[0],data_bus, FF_out);
  Bus_Driver    In(control_signals[2], pushbuttons, data_bus);

endmodule