//===========================================
// Module: pipeline
// Description:
//    Implements a multi-stage pipeline processor (IF, ID, EX, MEM, WB).
//    Integrates hazard detection, forwarding units, and pipeline registers 
//    to manage data dependencies and control flow. Interfaces with instruction 
//    memory, data memory, and debug units for monitoring internal states.
// Author: Brian Gerard
// Created: 12/02/2025
// Parameters:
// - NB_REG: Bit width for registers and data buses (default: 32).
// - NB_WIDHT: Address width for instruction/data memory (default: 9).
// - NB_OP: Bit width for opcode field (default: 6).
// - NB_ADDR: Bit width for register addresses (e.g., rs, rt) (default: 5).
// - NB_IFID: Width of IF/ID pipeline register (default: 64).
// - NB_IDEX: Width of ID/EX pipeline register (default: 144).
// - NB_EXM: Width of EX/MEM pipeline register (default: 88).
// - NB_MWB: Width of MEM/WB pipeline register (default: 80).
// Inputs:
// - i_clk: System clock signal.
// - i_reset: Global reset signal.
// - i_dunit_clk_en: Debug unit clock enable.
// - i_dunit_reset_pc: Debug signal to reset the program counter.
// - i_dunit_w_mem: Debug signal to write to instruction memory.
// - i_dunit_addr: Debug address for memory/register access.
// - i_dunit_data_if: Debug data input for instruction memory.
// Outputs:
// - o_dunit_reg: Debug output for register file contents.
// - o_dunit_mem_data: Debug output for data memory contents.
// - o_IF_ID: IF/ID pipeline register snapshot for debugging.
// - o_ID_EX: ID/EX pipeline register snapshot for debugging.
// - o_EX_M: EX/MEM pipeline register snapshot for debugging.
// - o_M_WB: MEM/WB pipeline register snapshot for debugging.
// - o_halt: Signal indicating a HALT instruction completion.
//===========================================

module pipeline #(
    parameter NB_REG  =32 ,
    parameter NB_WIDHT=9  , // for widht addr in instruction memory or datamemory
    parameter NB_OP   =6  ,
    parameter NB_ADDR =5  , //for addr -> rs ,rt ..
    parameter NB_IFID =64 ,
    parameter NB_IDEX =144,
    parameter NB_EXM  =88 ,
    parameter NB_MWB  =80   
) 
(
    input               i_clk           ,
    input               i_reset         ,

    input               i_dunit_clk_en  ,
    input               i_dunit_reset_pc,
    input               i_dunit_w_mem   ,       //write in instruction memory
    input [NB_REG-1:0]  i_dunit_addr    ,       //ADDR TO instruction memory, REGISTER MEMORY and datamemory
    input [NB_REG-1:0]  i_dunit_data_if ,       //instruction memory
    
    output[NB_REG-1:0]  o_dunit_reg     ,       //registermemory TO DEBUG UNIT  
    output[NB_REG-1:0]  o_dunit_mem_data,       //datamemory TO DEBUG UNIT
    output[NB_IFID-1:0] o_IF_ID         ,
    output[NB_IDEX-1:0] o_ID_EX         ,
    output[NB_EXM -1:0] o_EX_M          ,
    output[NB_MWB -1:0] o_M_WB          ,
    output              o_halt          


);
//WIRES IF
wire w_PCSrc;
wire [NB_REG-1:0] w_branch_target;
wire [NB_REG-1:0] w_intruction_if_id;
wire [NB_REG-1:0] w_pc_jsel_id_to_if;  //mux 3 if
wire [NB_REG-1:0] w_pcplus4_if_to_ifid;
wire [NB_REG-1:0] w_intruction_if;

//WIRES ID
wire [NB_REG-1:0] w_pc4_ifid_id;
wire w_forwardA_id;
wire w_forwardB_id;
wire w_flush;
wire w_stall;
// #-> 
wire [NB_REG-1:0] w_pc8_id_idex;
wire [NB_REG-1:0] w_sign_ext_id_idex;
wire [NB_REG-1:0] w_rs_data_id_idex;
wire [NB_REG-1:0] w_rt_data_id_idex;
wire [NB_ADDR-1:0]w_rs_addr_id_idex;
wire [NB_ADDR-1:0]w_rt_addr_id_idex;
wire [NB_ADDR-1:0]w_rd_addr_id_idex;
wire [NB_OP-1:0]w_op_id_idex;

//wire id/ex to ex
wire [NB_REG-1:0] w_pc8_idex_exm;
wire [NB_REG-1:0] w_rs_data_idex_ex;
wire [NB_REG-1:0] w_rt_data_idex_ex;
wire [NB_ADDR-1:0]w_rs_addr_idex_ex;
wire [NB_ADDR-1:0]w_rt_addr_idex_ex;
wire [NB_ADDR-1:0]w_rd_addr_idex_ex;
wire [NB_OP-1:0]w_op_idex_ex;

wire [16-1:0] w_controlU_idex_ex;
wire [NB_REG-1:0] w_sign_ext_idex_ex;

wire [20-1:0] w_signals_from_controlU;

//wire FORDWARD EX
wire [2-1:0] w_forwardA_ex;
wire [2-1:0] w_forwardB_ex;
wire [NB_REG-1:0]   w_alu_result_ex_exm;
wire [NB_REG-1:0]   w_write_data_ex_exm;
wire [NB_ADDR-1:0]  w_data_addr_ex_exm;

//wire FORDWARD EX MEM
wire [NB_REG -1:0] w_pc8_exm_mwb;
wire [NB_REG -1:0] w_alu_result_exm_m;
wire [NB_REG -1:0] w_write_data_exm_m;
wire [NB_ADDR-1:0] w_data_addr_exm_mwb;

wire [9-1:0] w_controlU_exm_m;

//wire MEM WB
wire [NB_REG-1:0] w_pc8_mwb_m;
wire [NB_REG-1:0] w_alu_result_mwb_wb;
wire [NB_REG-1:0] w_read_data_mwb_wb;
wire [4-1:0] w_controlU_mwb_wb;
wire [NB_ADDR-1:0] w_data_addr_from_mwb;

wire [NB_REG -1:0] w_read_data_m_mwb;


wire [NB_REG-1:0] w_data_to_reg_wb;

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
// IF MODULE
IF #(
    .NB_REG  (NB_REG),  // Width of registers and PC
    .NB_WIDHT(NB_WIDHT),  // Address width for instruction memory
    .NB_INST (26)   // Instruction width for concatenation
) uu_IF(
    .i_clk          (i_clk),          // Clock signal
    .i_reset        (i_reset),        // Reset signal
    .i_dunit_clk_en (i_dunit_clk_en), // Clock enable signal for data unit
    .i_dunit_w_en   (i_dunit_w_mem),   // Write enable signal for data unit
    .i_dunit_addr   (i_dunit_addr),   // Address input for data unit
    .i_PCSrc        (w_PCSrc),        // Selector for PC source
    .i_Jump         (w_signals_from_controlU[19]),         // Jump signal
    .i_JSel         (w_signals_from_controlU[18]),         // Selector for jump address
    .i_PCWrite      (!w_stall & !w_signals_from_controlU[0] ),//& !w_flush),      // Write enable for PC aca hace un stall pc
    .i_dunit_reset_pc(i_dunit_reset_pc),//TODO SACAR NO LO NECESITE
    .i_inmed        (w_branch_target),        // Immediate value for jump/branch
    .i_inst_to_mxp  (w_intruction_if_id[25:0]),  // Instruction bits for concatenation
    .i_pc_jsel      (w_pc_jsel_id_to_if),      // PC value for jump select
    .i_dunit_data   (i_dunit_data_if),   // Data for instruction memory write
    .o_pcplus4      (w_pcplus4_if_to_ifid),      // Calculated PC+4
    .o_instruction  (w_intruction_if)   // Instruction fetched from memory
);

// IF/ID
IF_ID #(
    .NB_REG (NB_REG)
) uu_IF_ID(
    .i_clk          (i_clk),
    .i_reset        (i_reset  | (w_signals_from_controlU[19] & i_dunit_clk_en)
                    | (w_signals_from_controlU[18] & i_dunit_clk_en)
                    | (w_PCSrc & i_dunit_clk_en & !w_stall)),// | (w_PCSrc & i_dunit_clk_en) flush si el salto es tomado
    .i_dunit_clk_en (i_dunit_clk_en ),
    .i_pc_four      (w_pcplus4_if_to_ifid),
    .i_data_ins_mem (w_intruction_if),
    .i_write        (!w_stall & !w_signals_from_controlU[0]),   //TODO:VERS SI FUNCIONA EL ~ EN 0 STALL mantengo valor anteriores esto debo conectarlo al pc tmb T
    .o_pc_four      (w_pc4_ifid_id),
    .o_data_ins_mem (w_intruction_if_id)

);



// ID INSTRUCTION DECODE ----------------------------------------------------------------------------------
ID #(
    .NB_REG   (NB_REG),
    .NB_ADDR  (NB_ADDR)
) uu_ID(
    .i_clk               (i_clk), // Clock signal.
    .i_reset             (i_reset), // Reset signal.
    .i_dunit_clk_en      (i_dunit_clk_en), // Data unit clock enable.
    .i_regWrite_from_WB  (w_controlU_mwb_wb[2]), // Write enable from WB stage.
    .i_forwardA          (w_forwardA_id), // Forwarding control for operand A.
    .i_forwardB          (w_forwardB_id), // Forwarding control for operand B.
    // ->#                                          
    .i_inst_from_IF      (w_intruction_if_id), // Instruction from IF stage.
    .i_pcplus4           (w_pc4_ifid_id), // PC + 4 from IF/ID REG.
    //  #                                          
    //  ^                                          
    .i_WB_addr           (w_data_addr_from_mwb), // Write-back register address.
    .i_WB_data           (w_data_to_reg_wb), // TODO VER SI ESTA BIEN ESTEWrite-back data.
    .i_aluResult         (w_alu_result_exm_m), // ALU result for forwarding. EX/M
    .i_isBeq             (w_signals_from_controlU[16]), // BEQ indicator signal.
    .i_branch            (w_signals_from_controlU[17]), // Branch signal.
    .i_dunit_addr        (i_dunit_addr[4:0])       ,
    .o_dunit_reg         (o_dunit_reg)        ,
    
    // <-#                                          
    .o_pc_jsel_to_IF     (w_pc_jsel_id_to_if), // PC value for jump/branch.
    .o_PCSrc_to_IF       (w_PCSrc), // Select signal for PC source.
    .o_branch_target     (w_branch_target), // Calculated branch target address.
    // #->                                          
    .o_pcplus8           (w_pc8_id_idex), // PC + 8 (used in some jumps).
    .o_inst_sign_extended(w_sign_ext_id_idex), // Sign-extended immediate value.
    .o_rs_data           (w_rs_data_id_idex), // Operand data for RS.
    .o_op_r_tipe         (w_op_id_idex), // Opcode or instruction type.
    .o_rs_addr           (w_rs_addr_id_idex), // RS register address.
    .o_rt_addr           (w_rt_addr_id_idex), // RT register address.
    .o_rd_addr           (w_rd_addr_id_idex), // RD register address.
    .o_rt_data           (w_rt_data_id_idex)// Operand data for RT.
);


//CONTROL UNIT
control_unit #(
    .NB_SGN    (20),
    .NB_OP     (NB_OP)
) uu_control_unit(
    .i_enable       (1'b1),
    .i_inst_opcode  (w_intruction_if_id[31:26]) ,   //instruction [31:26]
    .i_inst_function(w_intruction_if_id[5:0]) ,   //instruction [5:0]
    .o_signals      (w_signals_from_controlU)
);
//hazard unit
hazard_unit #(
    .NB_ADDR  (NB_ADDR)
)u_hazard_unit(
    .i_branch     (w_signals_from_controlU[17]),
    .i_rs_id      (w_intruction_if_id[25:21]),
    .i_rt_id      (w_intruction_if_id[20:16]),
    .i_rt_ex      (w_rt_addr_idex_ex),
    .i_rd_ex      (w_data_addr_ex_exm),
    .i_rd_mem     (w_data_addr_exm_mwb),
    .i_mem_read_ex(w_controlU_idex_ex[8]),
    .i_regwrite_ex(w_controlU_idex_ex[2]),
    .i_memtoreg_m (w_controlU_exm_m[3]),  
    .o_flush_idex (w_flush),
    .o_stall      (w_stall) //w_signals_from_controlU[0]=halt agregar
);

// FORWARDING UNIT IN ID
forwarding_unit_ID #(
    .NB_ADDR (NB_ADDR) // Default width for register addresses
) u_forwarding_unit_ID(
    .i_rs_id        (w_intruction_if_id[25:21]),          // rs address in ID stage
    .i_rt_id        (w_intruction_if_id[20:16]),          // rt address in ID stage
    .i_rd_ex_m      (w_data_addr_exm_mwb),        // Destination register address in EX/MEM stage
    .i_regWrite_ex_m(w_controlU_exm_m[2]),  // Write enable signal from EX/MEM stage
    .o_forwardA_ID  (w_forwardA_id),    // Forwarding control for rs in ID stage
    .o_forwardB_ID  (w_forwardB_id)     // Forwarding control for rt in ID stage
);

//----------------------------------------------------------------------------
// ID-EX REG
ID_EX #(
    .NB_REG   (NB_REG),
    .NB_CTRL  (16), //ver bien
    .NB_OP    (NB_OP),
    .NB_ADDR  (NB_ADDR)
) u_ID_EX(
    .i_clk           (i_clk),
    .i_reset         (i_reset | (w_flush & i_dunit_clk_en)),//,w_signals_from_controlU[19]),
    .i_dunit_clk_en  (i_dunit_clk_en),
    .i_pc_eight      (w_pc8_id_idex),
    .i_rs_data       (w_rs_data_id_idex),
    .i_rt_data       (w_rt_data_id_idex),
    .i_sign_extension(w_sign_ext_id_idex),
    .i_control_unit  (w_signals_from_controlU[15:0]),
    .i_operation     (w_op_id_idex),
    .i_rs_addr       (w_rs_addr_id_idex),
    .i_rt_addr       (w_rt_addr_id_idex),
    .i_rd_addr       (w_rd_addr_id_idex),

    .o_pc_eight      (w_pc8_idex_exm),
    .o_rs_data       (w_rs_data_idex_ex),
    .o_rt_data       (w_rt_data_idex_ex),
    .o_sign_extension(w_sign_ext_idex_ex),
    .o_control_unit  (w_controlU_idex_ex),
    .o_operation     (w_op_idex_ex),
    .o_rs_addr       (w_rs_addr_idex_ex),
    .o_rt_addr       (w_rt_addr_idex_ex),
    .o_rd_addr       (w_rd_addr_idex_ex)
);


// EX EXECUTE MODULE
EX #(
    .NB_REG   (NB_REG),    // Register and data width
    .NB_ADDR  (NB_ADDR),    // Register address width
    .NB_OP    (NB_OP),
    .ALU_OP   (4 )     // ALU operation width
) uu_EX(  
    // Control signals
    .i_alu_src_CU        (w_controlU_idex_ex[14]), // Control signal for ALU source          
    .i_reg_dst_CU        (w_controlU_idex_ex[15]), // Control signal for register destination
    .i_jal_sel_CU        (w_controlU_idex_ex[9]), // Control signal for JAL
    .i_alu_op_CU         (w_controlU_idex_ex[13:10]), // ALU operation control
    .i_rs_data           (w_rs_data_idex_ex), // Operand RS data
    .i_rt_data           (w_rt_data_idex_ex), // Operand RT data
    .i_rd_from_ID        (w_rd_addr_idex_ex), // RD address from ID stage
    .i_rt_from_ID        (w_rt_addr_idex_ex), // RT address from ID stage
    .i_inst_sign_extended(w_sign_ext_idex_ex), // Sign-extended immediate
    .i_aluResult_WB      (w_data_to_reg_wb), // Forwarded ALU result from WB
    .i_aluResult_MEM     (w_alu_result_exm_m), // Forwarded ALU result from MEM
    .i_op_r_tipe         (w_op_idex_ex), // Decoded operation type
    .i_forwardA          (w_forwardA_ex), // Forwarding control for A
    .i_forwardB          (w_forwardB_ex), // Forwarding control for B
    .o_alu_result        (w_alu_result_ex_exm), // ALU operation result
    .o_write_reg         (w_write_data_ex_exm), // Destination register address
    .o_rd_to_WB          (w_data_addr_ex_exm) // RD data for WB
);


//  FORWARDIN UNIT EX

forwarding_unit_EX #(
    .NB_REG (NB_ADDR) // Register identifier width
) u_forwarding_unit_EX(
    // Inputs
    .i_rs_from_ID      (w_rs_addr_idex_ex),       // Source register 1 from ID stage
    .i_rt_from_ID      (w_rt_addr_idex_ex),       // Source register 2 from ID stage
    .i_rd_from_M       (w_data_addr_exm_mwb),        // Destination register from EX/M stage
    .i_rd_from_WB      (w_data_addr_from_mwb),       // Destination register from M/WB stage
    .i_RegWrite_from_M (w_controlU_exm_m[2]), // RegWrite signal from EX/M stage
    .i_RegWrite_from_WB(w_controlU_mwb_wb[2]),// RegWrite signal from M/WB stage

    // Outputs
    .o_forwardA        (w_forwardA_ex),         // Forwarding signal for operand A
    .o_forwardB        (w_forwardB_ex)          // Forwarding signal for operand B
);

//----------------------------------------------------------------------------
// EX/M REGS
EX_M #(
    .NB_REG   (NB_REG),
    .NB_ADDR  (NB_ADDR),
    .NB_CTRL  (9 )
) u_EX_M(
    .i_clk              (i_clk) ,
    .i_reset            (i_reset) ,
    .i_dunit_clk_en     (i_dunit_clk_en) ,
    .i_pc_eight         (w_pc8_idex_exm) ,
    .i_alu_result       (w_alu_result_ex_exm) ,
    .i_w_data           (w_write_data_ex_exm) ,
    .i_data_addr        (w_data_addr_ex_exm) ,
    .i_control_from_ex  (w_controlU_idex_ex[8:0]) ,
    .o_pc_eight         (w_pc8_exm_mwb) ,
    .o_alu_result       (w_alu_result_exm_m) ,
    .o_w_data           (w_write_data_exm_m) ,
    .o_data_addr        (w_data_addr_exm_mwb) ,
    .o_control_from_ex  (w_controlU_exm_m)
);

// MEM MEMORY MODULE
MEM #(
    .NB_WIDTH  (NB_REG) ,    // Data width
    .NB_ADDR   (7 ) ,     // Address width
    .NB_DATA   (8 )       // Memory element width
) u_MEM(
    .i_clk           (i_clk),        // Clock signal
    .i_reset         (i_reset),     // Reset signal
    .i_mem_addr      (w_alu_result_exm_m),    // Address for memory access
    .i_mem_data      (w_write_data_exm_m),    // Data to write
    .i_mem_read_CU   (w_controlU_exm_m[8]),   // Read enable
    .i_mem_write_CU  (w_controlU_exm_m[7]),   // Write enable
    .i_BHW_CU        (w_controlU_exm_m[6:4]),         // Byte/halfword/word control signal
    .i_dunit_addr_data(i_dunit_addr),
    .o_read_data     (w_read_data_m_mwb),       // Data read
    .o_dunit_mem_data(o_dunit_mem_data)

);
//----------------------------------------------------------------------------

// MEM/WB REG
M_WB #(
    .NB_REG  (NB_REG),
    .NB_CTRL (4 ),
    .NB_ADDR (NB_ADDR )
) u_M_WB(
    .i_clk            (i_clk),
    .i_reset          (i_reset),
    .i_dunit_clk_en   (i_dunit_clk_en),
    .i_pc_eight       (w_pc8_exm_mwb),
    .i_read_data      (w_read_data_m_mwb),     // conectar entrada 1 mux
    .i_alu_res_ex_m   (w_alu_result_exm_m), // cable conectado a addr conectar entrada 0 mux
    .i_data_addr_ex_m (w_data_addr_exm_mwb),
    .i_control_from_m (w_controlU_exm_m[3:0]),
    .o_pc_eight       (w_pc8_mwb_m),
    .o_read_data      (w_read_data_mwb_wb),
    .o_alu_res_ex_m   (w_alu_result_mwb_wb),
    .o_data_addr_ex_m (w_data_addr_from_mwb),
    .o_control_from_m (w_controlU_mwb_wb)
);

assign o_halt = w_controlU_mwb_wb[0];
// WB MODULE
WB #(
    .NB_REG   (NB_REG) // Default width of registers and data buses
)u_WB(
    .i_alu_result    (w_alu_result_mwb_wb),      // ALU result
    .i_data_from_mem (w_read_data_mwb_wb),   // Data from memory (ReadData)
    .i_pcplus8       (w_pc8_mwb_m),         // PC+8 value (used for JAL)
    .i_MemToReg      (w_controlU_mwb_wb[3]),        // MemToReg control signal
    .i_isJal         (w_controlU_mwb_wb[1]),           // JAL control signal
    .o_data_to_reg   (w_data_to_reg_wb)     // Data to be written to register file
);

//ASSIGN intermediate reg
assign o_IF_ID = {w_intruction_if_id, w_pc4_ifid_id}; //32 ,32 = 64

assign o_ID_EX = {w_rs_data_idex_ex, 
                  w_rt_data_idex_ex, 
                  w_sign_ext_idex_ex, 
                  2'b00  ,w_op_idex_ex,
                  3'b000 ,w_rs_addr_idex_ex, 
                  3'b000 , w_rt_addr_idex_ex, 
                  3'b000 , w_rd_addr_idex_ex,
                  w_controlU_idex_ex         }; //32, 32, 32, 8, 8, 8, 8, 16 = 144

assign o_EX_M = {w_alu_result_exm_m, 
                 w_write_data_exm_m, 
                 3'b000, w_data_addr_exm_mwb, 
                 7'b000, w_controlU_exm_m}; //32, 32, 8, 16 = 88

assign o_M_WB = {w_read_data_mwb_wb,
                 w_alu_result_mwb_wb, 
                 3'b000 ,w_data_addr_from_mwb, 
                 4'b0000,w_controlU_mwb_wb}; //32, 32, 8, 8 = 80


endmodule
