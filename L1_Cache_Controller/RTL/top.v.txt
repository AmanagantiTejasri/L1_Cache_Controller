`timescale 1ns / 1ps
module l1_top #(
    parameter ADDR_width = 32,
    parameter DATA_width = 32,
    parameter CACHE_size = 4096,
    parameter BLOCK_size = 64,
    parameter num_WAYS = 2,
    parameter BLOCK_WORDS=16)

   (input clk,
    input reset,
    
    input  [ADDR_width-1:0] cpu_addr,
    input  [DATA_width-1:0] cpu_w_data,
    input cpu_read,
    input cpu_write,
    output [DATA_width-1:0] cpu_r_data,
    output cpu_ready);

    wire [DATA_width-1:0] mem_r_data;
    wire mem_ready;
    wire [ADDR_width-1:0] mem_addr;
    wire [DATA_width-1:0] mem_w_data;
    wire mem_read;
    wire mem_write;

    cache_controller #(

    .ADDR_width(ADDR_width),
    .DATA_width(DATA_width))
    cache_inst (
    .clk(clk),
    .reset(reset),
    
    .cpu_addr(cpu_addr),
    .cpu_w_data(cpu_w_data),                                     //cache controller insatntiation
    .cpu_read(cpu_read),
    .cpu_write(cpu_write),
    .cpu_r_data(cpu_r_data),
    .cpu_ready(cpu_ready),
    
    .mem_r_data(mem_r_data),
    .mem_ready(mem_ready),
    .mem_addr(mem_addr),
    .mem_w_data(mem_w_data),
    .mem_read(mem_read),
    .mem_write(mem_write));


    main_memory #(
    .DATA_width(DATA_width),
    .ADDR_width(ADDR_width),
    .BLOCK_WORDS(BLOCK_WORDS))
     memory_inst (                                           //main memory instantiation
    .clk(clk),

    .mem_addr(mem_addr),
    .mem_w_data(mem_w_data),
    .mem_r_data(mem_r_data),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_ready(mem_ready));

endmodule

