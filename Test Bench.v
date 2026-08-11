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

// 1.COLD READ MISS

cpu_addr  = 32'h00000948;       // Set 5, Word 2
cpu_write = 1'b0;
cpu_read  = 1'b1;
wait(cpu_ready);
 @(posedge clk);             
    cpu_read  = 1'b0;
    cpu_write = 1'b0;            
    @(posedge clk);
#20;

// 2.COLD WRITE MISS

cpu_addr   = 32'h000009B4;      // Set 6, Word 13
cpu_write  = 1'b1;
cpu_read   = 1'b0;
cpu_w_data = 32'd500;
wait(cpu_ready);
@(posedge clk);              
    cpu_read  = 1'b0;
    cpu_write = 1'b0;            
    @(posedge clk);
#20;

// 3.READ HIT

cpu_addr  = 32'h00000954;       // Set 5, Word 5
cpu_read  = 1'b1;
cpu_write = 1'b0;
wait(cpu_ready);
@(posedge clk);             
    cpu_read  = 1'b0;
    cpu_write = 1'b0;           
    @(posedge clk);
#20;

// 4.WRITE HIT

cpu_addr   = 32'h00000948;      // Set 5, Word 2
cpu_write  = 1'b1;
cpu_read   = 1'b0;
cpu_w_data = 32'd900000;
wait(cpu_ready);
@(posedge clk);             
    cpu_read  = 1'b0;
    cpu_write = 1'b0;            
    @(posedge clk);
#20;

// 5. 2-WAY FILLING
// Fills first way

cpu_addr  = 32'h00000848;        //set 1 ,word 2 (Tag 0)
cpu_read  = 1'b1;
cpu_write = 1'b0;
wait(cpu_ready);
@(posedge clk);             
    cpu_read  = 1'b0;
    cpu_write = 1'b0;            
    @(posedge clk);
#20;

//fills second way

cpu_addr  = 32'h00001048;       // set 1 ,word 2 (Tag 1)
cpu_read  = 1'b1;
cpu_write = 1'b0;
wait(cpu_ready);
@(posedge clk);              
    cpu_read  = 1'b0;
    cpu_write = 1'b0;            
    @(posedge clk);
#20;

// 6.LRU REPLACEMENT 
// Clean Eviction

cpu_addr  = 32'h00001848;       // set 1 ,word 2 (Tag 3)
cpu_read  = 1'b1;
cpu_write = 1'b0;
wait(cpu_ready);
@(posedge clk);              
    cpu_read  = 1'b0;
    cpu_write = 1'b0;            
    @(posedge clk);
#20;

// 7. Write Back

cpu_addr  = 32'h00000160;       // Set 5, Word 8 (Tag 0,way 1)
cpu_read  = 1'b1;
cpu_write = 1'b0;
wait(cpu_ready);
@(posedge clk);              
    cpu_read  = 1'b0;
    cpu_write = 1'b0;            
    @(posedge clk);
#20;
//Replaces set 5 ,way 0
cpu_addr  = 32'h000001160;       // Set 5, Word 8 (tag 2)
cpu_read  = 1'b1;
cpu_write = 1'b0;
wait(cpu_ready);
@(posedge clk);              
    cpu_read  = 1'b0;
    cpu_write = 1'b0;            
    @(posedge clk);
#20;
#10000;
end
endmodule
