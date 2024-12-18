module pipeline #(
    parameter NB_REG = 32,
    parameter NB_WIDHT=9 , // for widht addr in instruction memory or datamemory
    parameter NB_ADDR= 5  //for addr -> rs ,rt ..
) 
(
    input               i_clk       ,
    input               i_reset     ,

    input               i_dunit_clk_en,
    input               i_dunit_w_en,       //write in instruction memory
    input [NB_REG-1:0]  i_dunit_mem_addr,
    input [NB_REG-1:0]  i_dunit_mem_data



);

// IF MODULE
IF #(
    .NB_REG  (NB_REG),  // Width of registers and PC
    .NB_WIDHT(NB_WIDHT),  // Address width for instruction memory
    .NB_INST (26)   // Instruction width for concatenation
) uu_IF(
    .i_clk          (i_clk),          // Clock signal
    .i_reset        (i_reset),        // Reset signal
    .i_dunit_clk_en (i_dunit_clk_en), // Clock enable signal for data unit
    .i_dunit_w_en   (i_dunit_w_en),   // Write enable signal for data unit
    .i_dunit_addr   (i_dunit_mem_addr),   // Address input for data unit
    .i_PCSrc        (w_PCSrc),        // Selector for PC source
    .i_Jump         (w_signals_from_controlU[19]),         // Jump signal
    .i_JSel         (w_signals_from_controlU[18]),         // Selector for jump address
    .i_PCWrite      (~w_stall),      // Write enable for PC
    .i_inmed        (w_branch_target),        // Immediate value for jump/branch
    .i_inst_to_mxp  (w_intruction_if_id[25:0]),  // Instruction bits for concatenation
    .i_pc_jsel      (w_pc_jsel_id_to_if),      // PC value for jump select
    .i_dunit_data   (i_dunit_mem_data),   // Data for instruction memory write
    .o_pcplus4      (w_pcplus4_if_to_ifid),      // Calculated PC+4
    .o_instruction  (w_intruction_if)   // Instruction fetched from memory
);

// IF/ID
IF_ID #(
    .NB_REG (NB_REG)
) uu_IF_ID(
    .i_clk          (i_clk),
    .i_reset        (i_reset),
    .i_dunit_clk_en (i_dunit_clk_en),
    .i_pc_four      (w_pcplus4_if_to_ifid),
    .i_data_ins_mem (w_intruction_if),
    .i_flush        (w_flush),   // en 1 flush = reset register
    .i_write        (~w_stall),   //TODO:VERS SI FUNCIONA EL ~ EN 0 STALL mantengo valor anteriores esto debo conectarlo al pc tmb T
    .o_pc_four      (w_pc4_ifid_id),
    .o_data_ins_mem (w_intruction_if_id)

);

//WIRES IF
wire w_PCSrc;
wire [NB_REG-1:0] w_branch_target;
wire [NB_REG-1:0] w_intruction_if_id;
wire [NB_REG-1:0] w_pc_jsel_id_to_if;  //mux 3 if
wire [NB_REG-1:0] w_pcplus4_if_to_ifid;
wire [NB_REG-1:0] w_intruction_if;

// ID INSTRUCTION DECODE ----------------------------------------------------------------------------------
ID #(
    .NB_REG   (NB_REG),
    .NB_ADDR  (NB_ADDR)
) uu_ID(
    .i_clk               (i_clk), // Clock signal.
    .i_reset             (i_reset), // Reset signal.
    .i_dunit_clk_en      (i_dunit_clk_en), // Data unit clock enable.
    .i_regWrite_from_WB  (), // Write enable from WB stage.
    .i_forwardA          (w_forwardA_id), // Forwarding control for operand A.
    .i_forwardB          (w_forwardB_id), // Forwarding control for operand B.
    // ->#                                          
    .i_inst_from_IF      (w_intruction_if_id), // Instruction from IF stage.
    .i_pcplus4           (w_pc4_ifid_id), // PC + 4 from IF/ID REG.
    //  #                                          
    //  ^                                          
    .i_WB_addr           (), // Write-back register address.
    .i_WB_data           (), // Write-back data.
    .i_aluResult         (), // ALU result for forwarding. EX/M
    .i_isBeq             (w_signals_from_controlU[16]), // BEQ indicator signal.
    .i_branch            (w_signals_from_controlU[17]), // Branch signal.
    // <-#                                          
    .o_pc_jsel_to_IF     (w_pc_jsel_id_to_if), // PC value for jump/branch.
    .o_PCSrc_to_IF       (w_PCSrc), // Select signal for PC source.
    .o_branch_target     (w_branch_target), // Calculated branch target address.
    // #->                                          
    .o_pcplus8           (w_pc8_id_idex), // PC + 8 (used in some jumps).
    .o_inst_sign_extended(), // Sign-extended immediate value.
    .o_rs_data           (), // Operand data for RS.
    .o_op_r_tipe         (), // Opcode or instruction type.
    .o_rs_addr           (), // RS register address.
    .o_rt_addr           (), // RT register address.
    .o_rd_addr           (), // RD register address.
    .o_rt_data           ()// Operand data for RT.
);
//WIRES ID
wire [NB_REG-1:0] w_pc4_ifid_id;
wire w_forwardA_id;
wire w_forwardB_id;
wire w_flush;
wire w_stall;
wire [NB_REG-1:0] w_pc8_id_idex;


//CONTROL UNIT
control_unit #(
    .NB_SGN    (20),
    .NB_OP     (6 )
) uu_control_unit(
    .i_enable       (~w_flush) , //TODO: VER SI TOMA BIEN EL NEGADO
    .i_inst_opcode  (w_intruction_if_id[31:26]) ,   //instruction [31:26]
    .i_inst_function(w_intruction_if_id[5:0]) ,   //instruction [5:0]
    .o_signals      (w_signals_from_controlU)
);
//hazard unit
hazard_unit u_hazard_unit(
    .i_jump       (w_signals_from_controlU[19]),
    .i_branch     (w_PCSrc), //ojo aca dice branch pero es branch tomado
    .i_rs_id      (w_intruction_if_id[25:21]),
    .i_rt_id      (w_intruction_if_id[20:16]),
    .i_rt_ex      (),
    .i_mem_read_ex(),  
    .o_flush      (w_flush),
    .o_stall      (w_stall)
);
wire [NB_REG-1:0] w_signals_from_controlU;
// FORWARDING UNIT IN ID
forwarding_unit_ID #(
    .NB_ADDR (NB_ADDR) // Default width for register addresses
) u_forwarding_unit_ID(
    .i_rs_id        (w_intruction_if_id[25:21]),          // rs address in ID stage
    .i_rt_id        (w_intruction_if_id[20:16]),          // rt address in ID stage
    .i_rd_ex_m      (),        // Destination register address in EX/MEM stage
    .i_regWrite_ex_m(),  // Write enable signal from EX/MEM stage
    .o_forwardA_ID  (w_forwardA_id),    // Forwarding control for rs in ID stage
    .o_forwardB_ID  (w_forwardB_id)     // Forwarding control for rt in ID stage
);

//----------------------------------------------------------------------------
// ID-EX REG
ID_EX #(
    .NB_REG   (NB_REG),
    .NB_CTRL  (18), //ver bien
    .NB_ADDR  (5 )
) u_ID_EX(
    .i_clk           (i_clk),
    .i_reset         (i_reset),
    .i_dunit_clk_en  (i_dunit_clk_en),
    .i_pc_eight      (w_pc8_id_idex),
    .i_rs_data       (),
    .i_rt_data       (),
    .i_sign_extension(),
    .i_control_unit  (w_signals_from_controlU[15:0]),
    .o_pc_eight      (w_pc8_idex_exm),
    .o_rs_data       (),
    .o_rt_data       (),
    .o_sign_extension(),
    .o_control_unit  ()
);

wire [NB_REG-1:0] w_pc8_idex_exm;

// EX EXECUTE MODULE
EX #(
    .NB_REG   (NB_REG),    // Register and data width
    .NB_ADDR  (NB_ADDR),    // Register address width
    .NB_OP    (6 ),
    .ALU_OP   (4 )     // ALU operation width
) uu_EX(  
    // Control signals
    .i_alu_src_CU        (), // Control signal for ALU source          
    .i_reg_dst_CU        (), // Control signal for register destination
    .i_jal_sel_CU        (), // Control signal for JAL
    .i_alu_op_CU         (), // ALU operation control
    .i_rs_data           (), // Operand RS data
    .i_rt_data           (), // Operand RT data
    .i_rd_from_ID        (), // RD address from ID stage
    .i_rt_from_ID        (), // RT address from ID stage
    .i_inst_sign_extended(), // Sign-extended immediate
    .i_aluResult_WB      (), // Forwarded ALU result from WB
    .i_aluResult_MEM     (), // Forwarded ALU result from MEM
    .i_op_r_tipe         (), // Decoded operation type
    .i_forwardA          (), // Forwarding control for A
    .i_forwardB          (), // Forwarding control for B
    .o_alu_result        (), // ALU operation result
    .o_write_reg         (), // Destination register address
    .o_rd_to_WB          (), // RD data for WB
    .o_alu_condition_zero() // ALU condition zero flag
);
//  FORWARDIN UNIT EX

forwarding_unit_EX #(
    .NB_REG (NB_ADDR) // Register identifier width
) u_forwarding_unit_EX(
    // Inputs
    .i_rs_from_ID      (),       // Source register 1 from ID stage
    .i_rt_from_ID      (),       // Source register 2 from ID stage
    .i_rd_from_M       (),        // Destination register from EX/M stage
    .i_rd_from_WB      (),       // Destination register from M/WB stage
    .i_RegWrite_from_M (), // RegWrite signal from EX/M stage
    .i_RegWrite_from_WB(),// RegWrite signal from M/WB stage

    // Outputs
    .o_forwardA        (),         // Forwarding signal for operand A
    .o_forwardB        ()          // Forwarding signal for operand B
);

// EX/M REGS
EX_M #(
    .NB_REG   (NB_REG),
    .NB_CTRL  (9 ),
    .NB_ADDR  (NB_ADDR )
) u_EX_M(
    .i_clk              (i_clk) ,
    .i_reset            (i_reset) ,
    .i_dunit_clk_en     (i_dunit_clk_en) ,
    .i_pc_eight         (w_pc8_idex_exm) ,
    .i_alu_result       () ,
    .i_w_data           () ,
    .i_data_addr        () ,
    .i_control_from_ex  () ,
    .o_pc_eight         (w_pc8_exm_mwb) ,
    .o_alu_result       () ,
    .o_w_data           () ,
    .o_data_addr        () ,
    .o_control_from_ex  ()
);
wire [NB_REG-1:0] w_pc8_exm_mwb;

// MEM MEMORY MODULE
MEM #(
    .NB_WIDTH  (NB_REG) ,    // Data width
    .NB_ADDR   (9 ) ,     // Address width
    .NB_DATA   (8 )       // Memory element width
) u_MEM(
    .i_clk           (i_clk),        // Clock signal
    .i_reset         (i_reset),     // Reset signal
    .i_mem_addr      (),    // Address for memory access
    .i_mem_data      (),    // Data to write
    .i_mem_read_CU   (),   // Read enable
    .i_mem_write_CU  (),   // Write enable
    .i_BHW_CU        (),         // Byte/halfword/word control signal
    .o_read_data     ()       // Data read
);

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
    .i_read_data      (),     // conectar entrada 1 mux
    .i_alu_res_ex_m   (), // cable conectado a addr conectar entrada 0 mux
    .i_data_addr_ex_m (),
    .i_control_from_m (),
    .o_pc_eight       (w_pc8_mwb_m),
    .o_read_data      (),
    .o_alu_res_ex_m   (),
    .o_data_addr_ex_m (),
    .o_control_from_m ()
);
wire [NB_REG-1:0] w_pc8_mwb_m;

// WB MODULE
WB #(
    .NB_REG   (NB_REG) // Default width of registers and data buses
)u_WB(
    .i_alu_result    (),      // ALU result
    .i_data_from_mem (),   // Data from memory (ReadData)
    .i_pcplus8       (w_pc8_mwb_m),         // PC+8 value (used for JAL)
    .i_MemToReg      (),        // MemToReg control signal
    .i_isJal         (),           // JAL control signal
    .o_data_to_reg   ()     // Data to be written to register file
);
    
endmodule