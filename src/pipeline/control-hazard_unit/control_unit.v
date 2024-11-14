module control_unit #(
    parameter NB_SGN  =  20,
    parameter NB_OP   =  6
) (
    input                      i_enable        ,

    input        [NB_OP-1:0]   i_inst_opcode   ,   //instruction [31:26]
    input        [NB_OP-1:0]   i_inst_function ,   //instruction [5:0]

    //control signals
    output       [NB_SGN-1:0]  o_signals


);


//type R ---------------------------------------------------------
localparam  ADDU = 6'b100001; 
localparam  SUBU = 6'b100011;
localparam  AND  = 6'b100100;
localparam  OR   = 6'b100101;
localparam  XOR  = 6'b100110;
localparam  NOR  = 6'b100111;
localparam  SLT  = 6'b101010;
localparam  SLTU = 6'b101011;
//SHIFTS
localparam  SLL  = 6'b000000;
localparam  SRL  = 6'b000010;
localparam  SRA  = 6'b000011;
localparam  SLLV = 6'b000100; //shift left logical variable
localparam  SRLV = 6'b000110;
localparam  SRAV = 6'b000111;
localparam  HALT = 6'b111111;
// BHW VAL
localparam  BYTE   = 3'b000;
localparam  HLF    = 3'b001;
localparam  WORD   = 3'b011;
localparam  U_BYTE = 3'b100;
localparam  U_HLF  = 3'b101;
localparam  U_WORD = 3'b111;
// opcode[5:3]
localparam  LOAD  = 3'b100;
localparam  STORE = 3'b101;
localparam  IMMED = 3'b001;
// opcode[2:0]
localparam  BEQ   = 3'b100;
localparam  BNE   = 3'b101;
localparam  J     = 3'b010;
localparam  JAL   = 3'b011;
//func code for jr jalr
localparam  JR    = 6'b001000;
localparam  JALR  = 6'b001001;
//opcode for inmmediate         //ALUop code  el codigo 0010 esta reservado para R
localparam   ADDI = 6'b001000;  // 0000
localparam   ADDIU= 6'b001001;  // 0001
localparam   ANDI = 6'b001100;  // 0100
localparam   ORI  = 6'b001101;  // 0101
localparam   XORI = 6'b001110;  // 1000
localparam   LUI  = 6'b001111;  // 1001
localparam   SLTI = 6'b001010;  // 1100
localparam   SLTIU= 6'b001011;  // 1101



// 19  |18  | 17   | 16  |  15  |  14  | 13   | 12   |11    |10    |9     |8    | 7   |6   | 5  | 4  |3       | 2    | 1    | 0     |
// Jump|JSel|Branch|IsBeq|RegDst|AluSrc|AluOp3|AluOp2|AluOp1|AluOp0|JalSel|MemRd|MemWr|BHW2|BHW1|BHW0|MemToReg| RegWr| IsJal| halt_e|
reg [NB_OP-1:0] reg_signals;

always @(*) begin
    if (i_enable) begin
        case (i_inst_opcode[5:3])
            3'b000: //espaciales
            begin
                case (i_inst_opcode[2:0])
                    3'b000: //R type
                        begin
                            case (i_inst_function)
                            ADDU, SUBU, AND, OR, XOR, NOR, SLT, SLTU:
                                reg_signals = {7'b0,1'b1,8'b0,1'b1,2'b0};//aluop2, regwrite
                            SLL, SRL, SRA, SLLV, SRLV, SRAV:
                                reg_signals = {7'b0,1'b1,8'b0,1'b1,2'b0};//aluop2, regwrite
                            JR://JSel
                                reg_signals = {1'b0,1'b1,18'b0};
                            JALR://JSel RegWr IsJal
                                reg_signals = {1'b0,1'b1,15'b0,2'b11,1'b0};
                            HALT://halt_e
                                reg_signals = {19'b0,1'b1};
                            default: 
                                reg_signals = {20'b0}; 
                            endcase 
                        end
                    BEQ: //branch IsBeq aluOP_0011
                        reg_signals = {2'b0,2'b11,2'b0,4'b0011,10'b0};
                    BNE: //branch aluOP_0011
                        reg_signals = {2'b0,2'b10,2'b0,4'b0011,10'b0};
                    J: //jump JSel
                        reg_signals = {1'b1,19'b0};
                    JAL: //jump JSel RegWr IsJal
                        reg_signals = {1'b1,9'b0,1'b1,6'b0,2'b11,1'b0};
                    default: 
                        reg_signals = {20'b0};
                endcase

            end
            IMMED: //I type
                case (i_inst_opcode[2:0])
                    ADDI: //regDst AluSrc RegWrite
                        reg_signals = {4'b0,2'b11,4'b0000,7'b0,1'b1,2'b0};
                    ADDIU: //regDst AluSrc aluOp0 RegWrite
                        reg_signals = {4'b0,2'b11,4'b0001,7'b0,1'b1,2'b0};
                    ANDI: //regDst AluSrc aluOp2 RegWrite
                        reg_signals = {4'b0,2'b11,4'b0100,7'b0,1'b1,2'b0};
                    ORI: //regDst AluSrc aluOp2 aluOp0 RegWrite
                        reg_signals = {4'b0,2'b11,4'b0101,7'b0,1'b1,2'b0};
                    XORI: //regDst AluSrc aluOp3 RegWrite
                        reg_signals = {4'b0,2'b11,4'b1000,7'b0,1'b1,2'b0};
                    LUI: //regDst AluSrc aluOp3 aluOp0 RegWrite
                        reg_signals = {4'b0,2'b11,4'b1001,7'b0,1'b1,2'b0};
                    SLTI: //regDst AluSrc aluOp1 RegWrite
                        reg_signals = {4'b0,2'b11,4'b1100,7'b0,1'b1,2'b0};
                    SLTIU: //regDst AluSrc aluOp1 aluOp0 RegWrite
                        reg_signals = {4'b0,2'b11,4'b1101,7'b0,1'b1,2'b0};
                    default:
                        reg_signals = {20'b0};
                endcase
            LOAD: //I type
                case (i_inst_opcode[2:0])
                    BYTE: //regDst AluSrc MemRd MemToReg RegWrite
                        reg_signals = {4'b0,2'b11,5'b0,1'b1,1'b0,BYTE,2'b11,2'b0};
                    HLF:
                        reg_signals = {4'b0,2'b11,5'b0,1'b1,1'b0,HLF,2'b11,2'b0}; 
                    WORD:
                        reg_signals = {4'b0,2'b11,5'b0,1'b1,1'b0,WORD,2'b11,2'b0};
                    U_BYTE:
                        reg_signals = {4'b0,2'b11,5'b0,1'b1,1'b0,U_BYTE,2'b11,2'b0};
                    U_HLF:
                        reg_signals = {4'b0,2'b11,5'b0,1'b1,1'b0,U_HLF,2'b11,2'b0};
                    U_WORD:
                        reg_signals = {4'b0,2'b11,5'b0,1'b1,1'b0,U_WORD,2'b11,2'b0};

                    default: 
                        reg_signals = {4'b0,2'b11,5'b0,1'b1,1'b0,BYTE,2'b11,2'b0};
                endcase
            STORE: //I type
                case (i_inst_opcode[2:0])
                    BYTE: //regDst AluSrc MemWr
                        reg_signals = {4'b0,2'b11,5'b0,1'b0,1'b1,BYTE,4'b0};
                    HLF:
                        reg_signals = {4'b0,2'b11,5'b0,1'b0,1'b1,HLF,4'b0}; 
                    WORD:
                        reg_signals = {4'b0,2'b11,5'b0,1'b0,1'b1,WORD,4'b0};
                    default: 
                        reg_signals = {4'b0,2'b11,5'b0,1'b0,1'b1,BYTE,4'b0};
                endcase   

            default: 
                reg_signals = 20'b0; //change
        endcase
        
    end
    else begin
        reg_signals = 20'b0;
    end
end

assign o_signals = reg_signals;
    
endmodule