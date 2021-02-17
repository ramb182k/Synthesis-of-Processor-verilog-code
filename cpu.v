module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe
);
    reg [31:0] iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [3:0]  dwe;

    reg [31:0] reg_wdata;
    reg [31:0] imm;
    reg [31:0] drdata_mod;
    reg [31:0] iaddr_next;
    wire [31:0] rvout;
    
    wire [31:0] alu_1, alu_2, rv1, rv2, dwaddr; 
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [5:0] op_alu;
    wire [3:0] pc_select;
    wire alu_zero, reg_we, we, alu2_select, dmem_we;
    wire [4:0] rs1, rs2, rd;
    wire [2:0] reg_wdata_select, imm_select;
    
    assign opcode = idata[6:0];
    assign funct3 = idata[14:12];
    assign funct7 = idata[31:25];
    
    assign rs1 = idata[19:15];
    assign rs2 = idata[24:20];
    assign rd = idata[11:7];
    
    assign alu_1 = rv1;
    assign alu_2 = (alu2_select)? imm : rv2;    //selecting immediate or register value to send to alu
    assign we = (reset)?0:reg_we;  //reg_write enable
    
    always@(rvout or reset) begin if(!reset) daddr <= rvout;    //dmem write address(result from alu(rs1+imm))
                    else daddr <= 0;
    end
    
    
    
    always@(reg_wdata_select or rvout or drdata_mod or imm or iaddr) //reg write data
        begin
            case(reg_wdata_select)
                3'b000: reg_wdata = drdata_mod;          //load data 
                3'b001: reg_wdata = rvout;               //alu_result
                3'b010: reg_wdata = iaddr + 4;           //next pc value
                3'b011: reg_wdata = imm;                //lui
                3'b100: reg_wdata = iaddr + imm;        //auipc
                default: reg_wdata = 32'b0; 
            endcase
        end
    
    


    
    always@(imm_select or idata)   //immediate value for different opcode
        begin
            case(imm_select)
                3'b000: imm = {{20{idata[31]}},idata[31:20]};            //I-immediate
                3'b001: imm = {{27{idata[24]}},idata[24:20]};            //shamt
                3'b010: imm = {{20{idata[31]}},idata[31:25],idata[11:7]};                             //S-immediate
                3'b011: imm = {{19{idata[31]}},idata[31],idata[7],idata[30:25],idata[11:8],{1'b0}};   //B-immediate
                3'b100: imm = {{11{idata[31]}},idata[31],idata[19:12],idata[20],idata[30:21],{1'b0}}; //J-immediate
                3'b101: imm = {idata[31:12],{12{1'b0}}};                                              //U-immediate
                default: imm = 32'b0;
            endcase
        end
          
    
    

    
    always@(rvout or funct3 or drdata)  //load data from dmem (modifying for byte, halfword & word)
        
        begin

            case(funct3)
                3'b000: //load byte
                begin 
                    if(rvout[1:0]==0)  drdata_mod = {{24{drdata[7]}},drdata[7:0]};
                    else if(rvout[1:0]==1)   drdata_mod = {{24{drdata[15]}},drdata[15:8]};
                    else if(rvout[1:0]==2)  drdata_mod = {{24{drdata[23]}},drdata[23:16]};
                    else  drdata_mod = {{24{drdata[31]}},drdata[31:24]};
                end
                
                3'b001: //load halfword
                begin 
                    if(rvout[1:0]==0)  drdata_mod = {{16{drdata[15]}},drdata[15:0]};
                    else  drdata_mod = {{16{drdata[31]}},drdata[31:16]};
                end
                
                3'b010: if(rvout[1:0]==0) drdata_mod = drdata; //load word
                        else drdata_mod = 32'b0;
                
                3'b100:  //load byte unsigned
                    begin 
                        if(rvout[1:0]==0)  drdata_mod = drdata[7:0];
                        else if(rvout[1:0]==1)  drdata_mod = drdata[15:8];
                        else if(rvout[1:0]==2)  drdata_mod = drdata[23:16];
                        else  drdata_mod = drdata[31:24];
                    end
                
                3'b101: //load halfword unsigned
                    begin 
                        if(rvout[1:0]==0)  drdata_mod = drdata[15:0];
                        else  drdata_mod = drdata[31:16];
                    end
                default: drdata_mod = 32'b0;

            endcase
            
        end
    
    always@(daddr or rv2 or reset) begin    //store data
        if(!reset)  dwdata = rv2<<(daddr[1:0]*8);
        else dwdata = 0;
    end
    
    
    always@(rvout or dmem_we or funct3 or reset)     //dmem write enable for byte halfword & word
      
        begin
        
            if(dmem_we & !reset) begin
                case(funct3)
                    3'b000:  //store byte
                    begin 
                             if(rvout[1:0]==0) dwe = 4'b0001;
                        else if(rvout[1:0]==1) dwe = 4'b0010;
                        else if(rvout[1:0]==2) dwe = 4'b0100;
                                          else dwe = 4'b1000;
                    end
                    3'b001: //store halfword
                    begin 
                        if(rvout[1:0]==0) dwe = 4'b0011;
                                     else dwe = 4'b1100;
                    end
                    3'b010: //store word
                    begin 
                        if(rvout[1:0]==0) dwe = 4'b1111;
                                     else dwe = 4'b0000;
                    end
                    default: dwe = 4'b0000;
                endcase
            end
           
            else dwe = 4'b0000;    //disable write otherwise

        end

    always@(pc_select or alu_zero or imm or iaddr or rvout) //PC for branch and jump instr
        
        begin
        
            case(pc_select)
                4'b0000: iaddr_next <= iaddr + 4;                          //next pc value
                4'b0001: iaddr_next <= (alu_zero)? iaddr + imm: iaddr +4;  //beq,blt,bltu
                4'b0010: iaddr_next <= (~alu_zero)? iaddr + imm: iaddr +4; //bne,bge,bgeu
                4'b0111: iaddr_next <= rvout;                             //jalr
                4'b1000: iaddr_next <= iaddr + imm;                        //jal
                default: iaddr_next <= iaddr + 4;

            endcase
            
    end
    
    always @(posedge clk) begin
        if (reset) begin
            iaddr <= 0;
//             daddr <= 0;
//             dwdata <= 0;           defined these as combinational elements, hence, commenting to avoid multi-driver nets
//             dwe <= 0;
        end else begin 
            iaddr <= iaddr_next;        // next pc value           
        end
    end
    
    control control1(.opcode(opcode),
                     .funct3(funct3),
                     .funct7(funct7),
                     .reg_we(reg_we),
                     .alu2_select(alu2_select),
                     .op_alu(op_alu),
                     .dmem_we(dmem_we),
                     .reg_wdata_select(reg_wdata_select),
                     .imm_select(imm_select),
                     .pc_select(pc_select)); 

    alu alu1(.op(op_alu),
             .rv1(alu_1),
             .rv2(alu_2),
             .rvout(rvout),
             .alu_zero(alu_zero));
    
    register register1(.rs1(rs1),
                       .rs2(rs2),
                       .rd(rd),
                       .we(we),
                       .wdata(reg_wdata),
                       .rv1(rv1),
                       .rv2(rv2),
                       .clk(clk));

endmodule