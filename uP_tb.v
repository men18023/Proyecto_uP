//Jonathan Menendez
// Electronica Digital - Proyecto 2
//uP_tb.v / nibbler de 4 bits

module testbench();
    reg clock, reset;       //salidas y entradas del uP
    reg [3:0] pushbuttons;
    wire phase, c_flag, z_flag;
    wire [3:0] instr, oprnd, accu, data_bus, FF_out;
    wire [7:0] program_byte;
    wire [11:0] PC, address_RAM;

    //llamado al modulo principal (uP) del proyectp
uP uP(.clock(clock),
      .reset(reset),
      .pushbuttons(pushbuttons),
      .phase(phase),
      .c_flag(c_flag),
      .z_flag(z_flag),
      .instr(instr),
      .oprnd(oprnd),
      .accu(accu),
      .data_bus(data_bus),
      .FF_out(FF_out),
      .program_byte(program_byte),
      .PC(PC),
      .address_RAM(address_RAM));

  initial
      #1000 $finish;    //tiempo donde finaliza la simulacion

  always
      #5 clock = ~clock;    //tiempo de cada flanco de reloj

    initial begin
      #1  //display sencillo del titulo y cada input y output en hexadecimal para hacerlo mas corto
      $display("\n");
      $display("Proyecto 2: uP Jonathan Menéndez");
      $display("\n");
      $display("| clk || rst || pushb || phase || c || z || instr || oprnd ||  accu || bus || FFo || pr_b ||   PC  || a_RAM |");
      $monitor("|  %h  ||  %h  ||   %h   ||   %h   || %h || %h ||   %h   ||   %h   ||   %h   ||  %h  ||  %h  ||  %h  ||  %h  ||  %h  |"
              ,clock, reset, pushbuttons, phase, c_flag, z_flag, instr, oprnd, accu, data_bus, FF_out, program_byte, PC, address_RAM);
      clock = 0; pushbuttons = 4'b0110; // valores iniciales y diferentes conbinaciones de los pushbuttons
      #2 reset = 1;
      #1 reset = 0;
      #200 pushbuttons = 4'b1001;
      #20 pushbuttons = 4'b0000;
      #20 pushbuttons = 4'b0001;
      #20 pushbuttons = 4'b0010;
      #20 pushbuttons = 4'b0011;
      #20 pushbuttons = 4'b0100;
      #20 pushbuttons = 4'b0101;
      #20 pushbuttons = 4'b0110;
      #20 pushbuttons = 4'b0111;
      #20 pushbuttons = 4'b1000;
      #20 pushbuttons = 4'b1001;
      #20 pushbuttons = 4'b1010;
      #20 pushbuttons = 4'b1011;
      #20 pushbuttons = 4'b1100;
      #20 pushbuttons = 4'b1101;
      #20 pushbuttons = 4'b1110;
      #20 pushbuttons = 4'b1111;

      end

      initial begin
          $dumpfile("uP_tb.vcd");  //llamado al GTKWave
          $dumpvars(0, testbench);
      end
  endmodule
