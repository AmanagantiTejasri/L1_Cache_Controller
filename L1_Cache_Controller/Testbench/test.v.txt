`timescale 1ns / 1ps

module test;
parameter ADDR_width = 32;
parameter DATA_width = 32;

reg clk;
reg reset;
reg  [ADDR_width-1:0] cpu_addr;
reg  [DATA_width-1:0] cpu_w_data;
reg   cpu_read;
reg   cpu_write;
wire [DATA_width-1:0] cpu_r_data;
wire                  cpu_ready;

l1_top dut (
    .clk(clk),
    .reset(reset),

    .cpu_addr(cpu_addr),
    .cpu_w_data(cpu_w_data),
    .cpu_read(cpu_read),
    .cpu_write(cpu_write),
    .cpu_r_data(cpu_r_data),
    .cpu_ready(cpu_ready));


initial
  begin
    clk = 0;
    forever #5 clk = ~clk;
  end
initial
    begin
     reset=1;
     cpu_addr   = 0;
     cpu_w_data = 0;
     cpu_read   = 0;
     cpu_write  = 0;
#20;
     reset=0;
#20;

//READ MISS

cpu_addr = 32'h00000948;
cpu_write=1'b0;
cpu_read=1'b1;                   //set 5 
wait(cpu_ready);
#20;

cpu_addr=32'h00000148;
cpu_read = 1'b1;
cpu_write = 1'b0;
wait(cpu_ready);
#20;

//WRITE HIT

cpu_addr=32'h00000948;
cpu_write=1'b1;
cpu_read=1'b0;
cpu_w_data=900000;
wait(cpu_ready);
#30;

//REPALCEMENT USING LRU
cpu_addr=32'h0000116C;
cpu_read=1'b0;
cpu_write=1'b1;
cpu_w_data=98888;
wait(cpu_ready);
#20;

//WRITE BACK
cpu_addr=32'h00003954;
cpu_read=1'b1;
cpu_write=1'b0;
wait(cpu_ready);
#8000;
$finish;
end
endmodule

