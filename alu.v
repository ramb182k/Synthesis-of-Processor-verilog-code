module alu(
    input [5:0]  op,      // some input encoding of your choice
    input [31:0] rv1,    // First operand
    input [31:0] rv2,    // Second operand
    output [31:0] rvout,  // Output value
    output alu_zero      // for Branch operation
);
    reg [31:0] rvout;
    always@(op or rv1 or rv2)
    begin
        case(op)
            6'b000000: rvout = rv1 + rv2;                                 //add  && addi
            6'b110000: rvout = rv1 - rv2;                                 //sub
            6'b000010: rvout = ($signed(rv1) < $signed(rv2))?32'b1:32'b0; //slt  && slti
            6'b000011: rvout = (rv1 < rv2)?32'b1:32'b0;                   //sltu && sltiu
            6'b000100: rvout = rv1 ^ rv2;                                 //xor  && xori
            6'b000110: rvout = rv1 | rv2;                                 //or   && ori
            6'b000111: rvout = rv1 & rv2;                                 //and  && andi
            6'b100000: rvout = rv1 << rv2;                                //sll  && slli
            6'b100101: rvout = rv1 >> rv2;                                //srl  && srli
            6'b110101: rvout = rv1 >>> rv2;                               //sra  && srai
            default:   rvout = 32'b0;
        endcase
    end
    
    
    assign alu_zero = (rvout==0)? 1'b1:1'b0;           //setting true for branch operation
            

endmodule
