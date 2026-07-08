module main_memory #(
parameter ADDR_width = 32,
parameter DATA_width = 32,
parameter MEM_BLOCKS  = 256,
parameter BLOCK_WORDS = 16)
(input clk,
 input mem_write,
 input mem_read,                             
 input [ADDR_width-1:0] mem_addr,
 input [DATA_width-1:0] mem_w_data,
 output reg [DATA_width-1:0] mem_r_data,
 output reg mem_ready);

 reg [DATA_width-1:0] memory [0:MEM_BLOCKS-1][0:BLOCK_WORDS-1];
 integer block, word;

 initial
   begin
     for(block=0; block<MEM_BLOCKS; block=block+1)
         for(word=0; word<BLOCK_WORDS; word=word+1)     
             memory[block][word] = block * word;
  end

 always @(posedge clk)
         begin
           mem_ready <= 0;
           if(mem_write)
              begin
                  memory[(mem_addr/4)/16][(mem_addr/4)%16] <= mem_w_data;          //memory write
                  mem_ready <= 1;                                                 
              end

           if(mem_read)
             begin
                mem_r_data <=memory[(mem_addr/4)/16][(mem_addr/4)%16];            //memory read
                mem_ready <= 1;
             end
         end
endmodule
