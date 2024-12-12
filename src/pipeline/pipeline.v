module pipeline #(
    parameter NB_REG = 32
) 
(
    input           i_clk       ,
    input           i_reset     ,
    input           i_clk_valid 


);

// IF MODULE
IF #(
    .NB_REG  (32),  // Width of registers and PC
    .NB_WIDHT( 9),  // Address width for instruction memory
    .NB_INST (26)   // Instruction width for concatenation
) uu_IF(
    .i_clk(),          // Clock signal
    .i_reset(),        // Reset signal
    .i_dunit_clk_en(), // Clock enable signal for data unit
    .i_dunit_w_en(),   // Write enable signal for data unit
    .i_dunit_addr(),   // Address input for data unit
    .i_PCSrc(),        // Selector for PC source
    .i_Jump(),         // Jump signal
    .i_JSel(),         // Selector for jump address
    .i_PCWrite(),      // Write enable for PC
    .i_inmed(),        // Immediate value for jump/branch
    .i_inst_to_mxp(),  // Instruction bits for concatenation
    .i_pc_jsel(),      // PC value for jump select
    .i_dunit_data(),   // Data for instruction memory write
    .o_pcplus4(),      // Calculated PC+4
    .o_instruction()   // Instruction fetched from memory
);

// IF/ID


    
endmodule