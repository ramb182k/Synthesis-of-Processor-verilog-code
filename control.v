module control(input [6:0] opcode,
               input [2:0] funct3,
               input [6:0] funct7,
               output reg reg_we,
               output reg alu2_select,
               output reg [5:0] op_alu,
               output reg dmem_we,
               output reg [2:0] reg_wdata_select,
               output reg [2:0] imm_select,
               output reg [3:0] pc_select
              );
    

    
    always@(opcode or funct3 or funct7) begin

        if (opcode == 7'b0010011)            //arithmetic logic immediate operation            
            begin
                pc_select = 4'b0000;           //iaddr_next = iaddr+4
                alu2_select = 1'b1;            //select immediate value as 2nd alu operand
                reg_we = 1'b1 ;      
                dmem_we = 1'b0 ;
                reg_wdata_select = 3'b001;       //select alu result to write to reg
                
                if(funct3 == 001 | (funct3 == 101)) imm_select = 3'b001; //shamt value
                else                                imm_select = 3'b000; //I-immediate
            
                case (funct3)
                    3'b000:  op_alu = 6'b000000;   //addi
                    3'b010:  op_alu = 6'b000010;   //slti
                    3'b011:  op_alu = 6'b000011;   //sltiu
                    3'b100:  op_alu = 6'b000100;   //xori
                    3'b110:  op_alu = 6'b000110;   //ori
                    3'b111:  op_alu = 6'b000111;   //andi
                    3'b001:  op_alu = 6'b100000;   //slli
                    3'b101: if(funct7==7'b0100000) op_alu = 6'b110101;     //srai
                                        else op_alu = 6'b100101;     //srli
                    default: op_alu = 6'b000000;
                endcase
            
            end
                    
            
        else if (opcode == 7'b0110011)         //arithmetic logic operation
            
            begin
            
                pc_select = 4'b0000;           //advance pc to next addr
                alu2_select = 1'b0;            //select rv2 from register as 2nd alu operand
                reg_we = 1'b1 ;
                dmem_we = 1'b0 ;
                reg_wdata_select = 3'b001;       //select alu result to write to reg
                imm_select = 3'bx;            //don't care
        
                case (funct3)
                    3'b000:  if(funct7==7'b0100000) op_alu = 6'b110000;     //sub
                                         else op_alu = 6'b000000;     //add
                    3'b001:  op_alu = 6'b100000;   //sll
                    3'b010:  op_alu = 6'b000010;   //slt
                    3'b011:  op_alu = 6'b000011;   //sltu    
                    3'b100:  op_alu = 6'b000100;   //xor
                    3'b101:  if(funct7==7'b0100000) op_alu = 6'b110101 ;     //sra
                                         else op_alu = 6'b100101 ;     //srl
                    3'b110:  op_alu = 6'b000110;   //or
                    3'b111:  op_alu = 6'b000111;   //and
                    default: op_alu = 6'b000000;
                 endcase
        
             end
        
      
        
        else if(opcode == 7'b0000011)       //Load operation
            
            begin     
            
                pc_select = 4'b0000;           //iaddr_next = iaddr+4
                alu2_select = 1'b1;            //select immediate value as 2nd alu operand
                reg_we = 1'b1 ;
                dmem_we = 1'b0 ;
                reg_wdata_select = 3'b000;     //select dmem data to write to reg
                op_alu = 6'b000000;            //add
                imm_select = 3'b000;           //I-immediate
             
            end
        
        else if(opcode == 7'b0100011)      //Store operation
            
            begin     

                pc_select = 4'b0000;           //iaddr_next = iaddr+4
                alu2_select = 1'b1;            //select immediate value as 2nd alu operand
                reg_we = 1'b0 ;
                dmem_we = 1'b1 ;
                op_alu = 6'b000000;            //add
                imm_select = 3'b010;           //S-immediate
                reg_wdata_select = 3'bx;       //don't care
                       
            end
        
        else if(opcode == 7'b1100011)   //Branch operation
            
            begin
           
                alu2_select = 1'b0;            //select rv2 from reg as the 2nd alu operand
                reg_we = 1'b0 ;
                dmem_we = 1'b0 ;
                imm_select = 3'b011;           //B-immediate
                reg_wdata_select = 3'bx;       //don't care
            
                case(funct3)
                    3'b000:  
                        begin 
                            op_alu = 6'b110000;     //sub
                            pc_select = 4'b0001;           //iaddr_next = iaddr+imm(if eq)
                        end
                    3'b001:  
                        begin
                            op_alu = 6'b110000;   //sub
                            pc_select = 4'b0010;           //iaddr_next = iaddr+imm(if ne)
                        end
                    3'b100:  
                        begin
                            op_alu = 6'b000010;   //slt
                            pc_select = 4'b0010;           //iaddr_next = iaddr+imm(if lt)
                        end
                    3'b101:  
                        begin
                            op_alu = 6'b000010;   //slt
                            pc_select = 4'b0001;           //iaddr_next = iaddr+imm(if ge)
                        end
                    3'b110:  
                        begin
                            op_alu = 6'b000011;   //sltu
                            pc_select = 4'b0010;           //iaddr_next = iaddr+imm(if ltu)
                        end
                    3'b111:  
                        begin
                            op_alu = 6'b000011;   //sltu
                            pc_select = 4'b0001;           //iaddr_next = iaddr+imm(if geu)
                        end
                    default: 
                        begin 
                            op_alu = 6'b000000;     
                            pc_select = 4'b0000;          
                        end
                endcase
            end
        
        else if(opcode == 7'b1100111) begin       //jalr
            pc_select = 4'b0111;           //iaddr_next =  rv1 + imm
            alu2_select = 1'b1;            //select immediate value as 2nd alu operand
            reg_we = 1'b1 ;
            reg_wdata_select = 3'b010;      //store next pc value in reg
            dmem_we = 1'b0 ;
            op_alu = 6'b000000;            //add
            imm_select = 3'b000;            //I-immediate  
        end
        
        else if(opcode == 7'b1101111) begin       //jal
            pc_select = 4'b1000;            //iaddr_next = iaddr + imm
            reg_we = 1'b1 ;
            reg_wdata_select = 3'b010;      //store next pc value in reg
            dmem_we = 1'b0 ;
            imm_select = 3'b100;            //J-immediate  
            alu2_select = 1'bx;             //don't care
            op_alu = 6'bx;                  //don't care
        end
        
        else if(opcode == 7'b0110111) begin       //lui
            pc_select = 4'b0000;            //iaddr_next = iaddr+4
            reg_we = 1'b1;
            reg_wdata_select = 3'b011;      //write immediate value in reg
            dmem_we = 1'b0 ;
            imm_select = 3'b101;            //U-immediate 
            alu2_select = 1'bx;             //don't care
            op_alu = 6'bx;                  //don't care
        end
        
        else if(opcode == 7'b0010111) begin         //auipc
            pc_select = 4'b0000;            //iaddr_next = iaddr+4 
            reg_we = 1'b1;
            reg_wdata_select = 3'b100;      //store current pc+immediate in reg
            dmem_we = 1'b0 ;
            imm_select = 3'b101;           //U-immediate
            alu2_select = 1'bx;            //don't care
            op_alu = 6'bx;                 //don't care
            
        end
        
        else begin
            pc_select = 4'b0000;        //  iaddr_next = iaddr+4 
            reg_we = 1'b0 ;   
            dmem_we = 1'b0 ;
            alu2_select = 1'bx;          //don't care
            op_alu = 6'bx;               //don't care
            reg_wdata_select = 3'bx;     //don't care
            imm_select = 3'bx;           //don't care
        end
    end
   

    
endmodule