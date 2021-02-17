module register(
    input [4:0] rs1,     // address of first operand to read - 5 bits
    input [4:0] rs2,     // address of second operand
    input [4:0] rd,      // address of value to write
    input we,            // should write update occur
    input [31:0] wdata,  // value to be written
    output [31:0] rv1,   // First read value
    output [31:0] rv2,   // Second read value
    input clk           // Clock signal - all changes at clock posedge
);
    reg [31:0] A [31:0]; //32 32-bit registers
    integer i;           //variable for for-loop
    initial 
      begin
        for(i=0; i<32 ; i=i+1) 
            A[i] <= 32'b0;          //initializing the registers to 0
      end
    
    // Desired function
    // rv1, rv2 are combinational outputs - they will update whenever rs1, rs2 change
    // on clock edge, if we=1, regfile entry for rd will be updated
    
    assign rv1 = A[rs1];           //Assigning the value in address rs1
    assign rv2 = A[rs2];           //Assigning the value in address rs2
    
    always@(posedge clk) 
    begin
        if(we & rd!=32'b0) A[rd] <= wdata;        //writing the data at positive clock edge when write enable is ON and x0 is always 0
    end
            


endmodule