`timescale 1ns / 1ps

module tb_ALU_control;

    // Parámetros
    parameter NB_FUNCT = 6;
    parameter NB_ALU_OP = 4;

    // Entradas
    reg [NB_FUNCT-1:0] i_op_r_tipe;
    reg [NB_ALU_OP-1:0] i_alu_op_CU;

    // Salidas
    wire [NB_FUNCT-1:0] o_alu_control_signals;
    

    // Instancia del módulo ALU_Control
    ALU_Control #(
        .NB_FUNCT(NB_FUNCT),
        .NB_ALU_OP(NB_ALU_OP)
    ) u_ALU_Control (
        .i_op_r_tipe(i_op_r_tipe),
        .i_alu_op_CU(i_alu_op_CU),
        .o_alu_control_signals(o_alu_control_signals)
    );

    // Estímulos
    initial begin
        $display("Time\tALUOp\t\tFunction Code\t\tOutput");
        $display("----------------------------------------------------------");

        // Caso 1: R_TYPE
        i_alu_op_CU = 4'b0010; // R-type
        i_op_r_tipe = 6'b100000; // ADD
        #10;
        $display("%0dns\t%b\t%b\t%b", $time, i_alu_op_CU, i_op_r_tipe, o_alu_control_signals);

        // Caso 2: LOAD_STORE
        i_alu_op_CU = 4'b0000; // Load/Store
        i_op_r_tipe = 6'bxxxxxx; // Ignorado
        #10;
        $display("%0dns\t%b\t%b\t%b", $time, i_alu_op_CU, i_op_r_tipe, o_alu_control_signals);

        // Caso 3: I_TYPE_ADDI
        i_alu_op_CU = 4'b0001; // ADDI
        i_op_r_tipe = 6'bxxxxxx; // Ignorado
        #10;
        $display("%0dns\t%b\t%b\t%b", $time, i_alu_op_CU, i_op_r_tipe, o_alu_control_signals);

        // Caso 4: I_TYPE_ANDI
        i_alu_op_CU = 4'b0100; // ANDI
        i_op_r_tipe = 6'bxxxxxx; // Ignorado
        #10;
        $display("%0dns\t%b\t%b\t%b", $time, i_alu_op_CU, i_op_r_tipe, o_alu_control_signals);

        // Caso 5: I_TYPE_ORI
        i_alu_op_CU = 4'b0101; // ORI
        i_op_r_tipe = 6'bxxxxxx; // Ignorado
        #10;
        $display("%0dns\t%b\t%b\t%b", $time, i_alu_op_CU, i_op_r_tipe, o_alu_control_signals);

        // Caso 6: I_TYPE_XORI
        i_alu_op_CU = 4'b1000; // XORI
        i_op_r_tipe = 6'bxxxxxx; // Ignorado
        #10;
        $display("%0dns\t%b\t%b\t%b", $time, i_alu_op_CU, i_op_r_tipe, o_alu_control_signals);

        // Caso 7: I_TYPE_LUI
        i_alu_op_CU = 4'b1001; // LUI
        i_op_r_tipe = 6'bxxxxxx; // Ignorado
        #10;
        $display("%0dns\t%b\t%b\t%b", $time, i_alu_op_CU, i_op_r_tipe, o_alu_control_signals);

        // Caso 8: I_TYPE_SLTI
        i_alu_op_CU = 4'b1100; // SLTI
        i_op_r_tipe = 6'bxxxxxx; // Ignorado
        #10;
        $display("%0dns\t%b\t%b\t%b", $time, i_alu_op_CU, i_op_r_tipe, o_alu_control_signals);

        // Caso 9: BRANCH
        i_alu_op_CU = 4'b0111; // Branch
        i_op_r_tipe = 6'bxxxxxx; // Ignorado
        #10;
        $display("%0dns\t%b\t%b\t%b", $time, i_alu_op_CU, i_op_r_tipe, o_alu_control_signals);

        // Fin de la simulación
        $stop;
    end

endmodule
