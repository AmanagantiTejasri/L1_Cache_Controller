`timescale 1ns / 1ps
module cache_controller #(
    parameter ADDR_width = 32, 
    parameter DATA_width = 32, 
    parameter CACHE_size = 4096,     
    parameter BLOCK_size = 64,       
    parameter num_WAYS = 2)

    (input clk,
    input reset,

    input  [ADDR_width-1:0] cpu_addr,
    input  [DATA_width-1:0] cpu_w_data,
    input cpu_read,
    input cpu_write,                              //CPU Interface signals
    output reg [DATA_width-1:0] cpu_r_data,
    output reg cpu_ready,

    input [DATA_width-1:0] mem_r_data,
    input mem_ready,
    output reg [ADDR_width-1:0] mem_addr,         //Memory Interface signals
    output reg [DATA_width-1:0] mem_w_data,     
    output reg mem_read,
    output reg mem_write);

    localparam num_SETS = CACHE_size/(BLOCK_size*num_WAYS);   //No.of sets
    localparam BLOCK_WORDS = BLOCK_size/(DATA_width/8);       //No.of Blocks per cache block
    localparam WORD_OFF_bits = $clog2(BLOCK_WORDS);           //No.of bits to select a word in a block
    localparam BYTE_OFF_bits = $clog2(DATA_width/8);          //No.of bits to select a byte inside word
    localparam INDEX_bits = $clog2(num_SETS);                 //No.of bits to select cache set
    localparam TAG_bits = (ADDR_width)-(INDEX_bits)-(WORD_OFF_bits)-(BYTE_OFF_bits); //No.of bits used as tag

// FSM states
    localparam IDLE        = 3'd0;
    localparam TAG_COMPARE = 3'd1;
    localparam MISS        = 3'd2;
    localparam WRITE_BACK  = 3'd3;
    localparam REFILL      = 3'd4;
    localparam RESPOND_CPU = 3'd5;

    reg [2:0] state;

    reg [ADDR_width-1:0] req_addr;
    reg req_r_w;                               
    reg [DATA_width-1:0] req_w_data;              //stored cpu requested address
    wire [TAG_bits-1:0] req_tag;                 
    wire [INDEX_bits-1:0] req_index;
    wire [WORD_OFF_bits-1:0] req_word_off;
    
    assign req_tag      = req_addr[ADDR_width-1 : (INDEX_bits)+ WORD_OFF_bits + BYTE_OFF_bits];
    assign req_index    = req_addr[WORD_OFF_bits + BYTE_OFF_bits + INDEX_bits-1 : WORD_OFF_bits + BYTE_OFF_bits];
    assign req_word_off = req_addr[WORD_OFF_bits + BYTE_OFF_bits-1 : BYTE_OFF_bits]; 
 
    reg hit_way;               //for way selection
    reg replace_way;

    reg [WORD_OFF_bits-1:0] current_word;
    reg [WORD_OFF_bits:0] refill_count;           //counters 
    reg [WORD_OFF_bits:0] wback_count;            

    reg lru [0:num_SETS-1];                        //LRU Bit
    
    reg [TAG_bits-1:0] tag_mem[0:num_SETS-1][0:num_WAYS-1];  
    reg valid_mem  [0:num_SETS-1][0:num_WAYS-1];                          //Cache storage Arrays  
    reg dirty_mem [0:num_SETS-1][0:num_WAYS-1]; 
    reg [DATA_width-1:0] data_mem [0:num_SETS-1][0:num_WAYS-1][0:BLOCK_WORDS-1]; 
 
    integer set, way, word;
    always @(posedge clk or posedge reset) 
              begin
              if(reset)
                 begin
                  state <= IDLE;
                  cpu_ready <= 1'b0;
                  cpu_r_data <= 0;
                  mem_read  <= 1'b0;
                  mem_write <= 1'b0;
                  mem_addr   <= 0;                
                  mem_w_data <= 0;
                  refill_count <= 0;
                  wback_count  <= 0;
                  current_word <= 0;

                 for(set=0; set<num_SETS; set=set+1)
                     begin
                      lru[set] <= 0;
                      for(way=0; way<num_WAYS; way=way+1)
                            begin                                             //CACHE INTIALIZATION
                             valid_mem[set][way] <= 0;
                             dirty_mem[set][way] <= 0;
                             tag_mem[set][way]   <= 0;
                             for(word=0; word<BLOCK_WORDS; word=word+1)
                                  data_mem[set][way][word] <= 0;
                     end
               end
          end

          else begin 
              case(state)
              
              IDLE:
                 begin 
                  cpu_ready <= 1'b0; 
                  mem_read  <= 1'b0; 
                  mem_write <= 1'b0;
                  cpu_r_data<=32'b0;
                  if(cpu_read||cpu_write) 
                     begin                                 //saving address before moving to next sate
                       req_addr <= cpu_addr; 
                       req_w_data <= cpu_w_data; 
                       req_r_w <= cpu_write; 
                  state <= TAG_COMPARE;
                end
             end
             
             
            TAG_COMPARE:
               begin 
                 if(valid_mem[req_index][0]&&(tag_mem[req_index][0] == req_tag))
                    begin 
                      hit_way <= 0;
                      lru[req_index] <= 1'b1; 
                      state <= RESPOND_CPU;                                            //LRU update
                     end 
            
                 else if(valid_mem[req_index][1] &&(tag_mem[req_index][1] == req_tag)) 
                       begin
                         hit_way <= 1;
                         lru[req_index] <= 1'b0;    
                         state <= RESPOND_CPU;
                       end   
               else 
                begin
                 if (!valid_mem[req_index][0])
                     replace_way <= 0;                       
                 else if (!valid_mem[req_index][1])
                      replace_way <= 1;
                 else
                      replace_way <= lru[req_index];          //Replacement way selection using LRU

                state <= MISS;
                end 
            end
            
            
    
           MISS:
             begin
               if(valid_mem[req_index][replace_way]&&(dirty_mem[req_index][replace_way])) 
                  begin
                    wback_count <= 0;
                    state <= WRITE_BACK;
                  end
               else
                 begin
                  current_word <= req_word_off; 
                  refill_count <= 0; 
                state <= REFILL;
                 end
            end
            
            
            
            WRITE_BACK:
               begin 
                 mem_write <= 1'b1;
                 mem_addr <= {tag_mem[req_index][replace_way],req_index,wback_count[WORD_OFF_bits-1:0],2'b00};
                 mem_w_data <=data_mem[req_index][replace_way][wback_count]; 
                 if(mem_ready)
                    begin
                      if(wback_count == BLOCK_WORDS-1)
                         begin
                           mem_write <= 1'b0;                              
                           wback_count <= 0; 
                           current_word <= req_word_off; 
                           refill_count <= 0;    
                       state <= REFILL;
                         end
                      else 
                        wback_count <=wback_count+1; 
                    end
               end 
            
            
          REFILL: 
            begin
              mem_read  <= 1'b1;
              mem_addr <= {req_tag,req_index,current_word,2'b00}; 
              if(mem_ready) 
                 begin 
                   data_mem[req_index][replace_way][current_word] <= mem_r_data;          //Refilling
                   refill_count <= refill_count + 1;  
                   
                   if(refill_count == BLOCK_WORDS-1) 
                       begin
                        mem_read <= 1'b0; 
                        tag_mem[req_index][replace_way]<= req_tag;        
                        valid_mem[req_index][replace_way]<= 1'b1;                        //updating cache arrays after refill
                        if(req_r_w) 
                           dirty_mem[req_index][replace_way] <= 1'b1;                   
                        else 
                           dirty_mem[req_index][replace_way] <= 1'b0;
                  if(req_r_w) 
                      begin 
                         data_mem[req_index][replace_way][req_word_off]<= req_w_data;
                      end
                    hit_way <= replace_way; 
                    if(replace_way == 0) 
                       lru[req_index] <= 1'b1;                                           //update LRU bit
                    else 
                      lru[req_index] <= 1'b0;
            refill_count <= 0; 
            current_word <= req_word_off; 
            
            state <= RESPOND_CPU;
        end 
        else 
          begin 
            if(current_word == BLOCK_WORDS-1) 
                current_word <= 0; 
            else 
                current_word <= current_word + 1; 
        end 
    end 
end
          
         RESPOND_CPU: 
          begin
           cpu_ready <= 1'b1;
 
           if(!req_r_w) 
             begin
              cpu_r_data <=data_mem[req_index][hit_way][req_word_off];              //CPU read
             end
          else 
            begin
               data_mem[req_index][hit_way][req_word_off]<= req_w_data;
               dirty_mem[req_index][hit_way]<= 1'b1;                                //CPU write
            end 
      
          state <= IDLE; 
end
endcase
end
end
endmodule

