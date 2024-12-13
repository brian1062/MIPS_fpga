`timescale 1ns / 1ps

module tb_forwarding_unit_EX;

    // Parámetros
    parameter NB_REG = 5;

    // Entradas
    reg [NB_REG-1:0] i_rs_from_ID;       // Source register 1 from ID stage
    reg [NB_REG-1:0] i_rt_from_ID;       // Source register 2 from ID stage
    reg [NB_REG-1:0] i_rd_from_M;        // Destination register from EX/M stage
    reg [NB_REG-1:0] i_rd_from_WB;       // Destination register from M/WB stage
    reg              i_RegWrite_from_M;  // RegWrite signal from EX/M stage
    reg              i_RegWrite_from_WB; // RegWrite signal from M/WB stage

    // Salidas
    wire [1:0] o_forwardA;               // Forwarding signal for operand A
    wire [1:0] o_forwardB;               // Forwarding signal for operand B

    // Instancia del módulo
    forwarding_unit_EX #(
        .NB_REG(NB_REG)
    ) u_forwarding_unit_EX (
        .i_rs_from_ID(i_rs_from_ID),
        .i_rt_from_ID(i_rt_from_ID),
        .i_rd_from_M(i_rd_from_M),
        .i_rd_from_WB(i_rd_from_WB),
        .i_RegWrite_from_M(i_RegWrite_from_M),
        .i_RegWrite_from_WB(i_RegWrite_from_WB),
        .o_forwardA(o_forwardA),
        .o_forwardB(o_forwardB)
    );

    // Estímulos
    initial begin
        $display("Time\tRegWrite_M\tRegWrite_WB\tRD_M\tRD_WB\tRS\tRT\tForwardA\tForwardB");
        $display("-----------------------------------------------------------------------------");

        // Caso 1: No hay forwarding
        i_rs_from_ID = 5'b00001;
        i_rt_from_ID = 5'b00010;
        i_rd_from_M = 5'b00011;
        i_rd_from_WB = 5'b00100;
        i_RegWrite_from_M = 0;
        i_RegWrite_from_WB = 0;
        #10;
        $display("%0dns\t%b\t\t%b\t\t%b\t%b\t%b\t%b\t%b\t\t%b",
                  $time, i_RegWrite_from_M, i_RegWrite_from_WB, i_rd_from_M, i_rd_from_WB, 
                  i_rs_from_ID, i_rt_from_ID, o_forwardA, o_forwardB);

        // Caso 2: Forwarding desde EX/M para RS
        i_rs_from_ID = 5'b00011;
        i_rt_from_ID = 5'b00010;
        i_rd_from_M = 5'b00011;
        i_rd_from_WB = 5'b00100;
        i_RegWrite_from_M = 1;
        i_RegWrite_from_WB = 0;
        #10;
        $display("%0dns\t%b\t\t%b\t\t%b\t%b\t%b\t%b\t%b\t\t%b",
                  $time, i_RegWrite_from_M, i_RegWrite_from_WB, i_rd_from_M, i_rd_from_WB, 
                  i_rs_from_ID, i_rt_from_ID, o_forwardA, o_forwardB);

        // Caso 3: Forwarding desde M/WB para RT
        i_rs_from_ID = 5'b00001;
        i_rt_from_ID = 5'b00100;
        i_rd_from_M = 5'b00011;
        i_rd_from_WB = 5'b00100;
        i_RegWrite_from_M = 0;
        i_RegWrite_from_WB = 1;
        #10;
        $display("%0dns\t%b\t\t%b\t\t%b\t%b\t%b\t%b\t%b\t\t%b",
                  $time, i_RegWrite_from_M, i_RegWrite_from_WB, i_rd_from_M, i_rd_from_WB, 
                  i_rs_from_ID, i_rt_from_ID, o_forwardA, o_forwardB);

        // Caso 4: Forwarding para ambos RS y RT
        i_rs_from_ID = 5'b00100;
        i_rt_from_ID = 5'b00100;
        i_rd_from_M = 5'b00100;
        i_rd_from_WB = 5'b00100;
        i_RegWrite_from_M = 1;
        i_RegWrite_from_WB = 1;
        #10;
        $display("%0dns\t%b\t\t%b\t\t%b\t%b\t%b\t%b\t%b\t\t%b",
                  $time, i_RegWrite_from_M, i_RegWrite_from_WB, i_rd_from_M, i_rd_from_WB, 
                  i_rs_from_ID, i_rt_from_ID, o_forwardA, o_forwardB);

        // Caso 5: Sin coincidencias pero RegWrite activado
        i_rs_from_ID = 5'b00001;
        i_rt_from_ID = 5'b00010;
        i_rd_from_M = 5'b00101;
        i_rd_from_WB = 5'b00110;
        i_RegWrite_from_M = 1;
        i_RegWrite_from_WB = 1;
        #10;
        $display("%0dns\t%b\t\t%b\t\t%b\t%b\t%b\t%b\t%b\t\t%b",
                  $time, i_RegWrite_from_M, i_RegWrite_from_WB, i_rd_from_M, i_rd_from_WB, 
                  i_rs_from_ID, i_rt_from_ID, o_forwardA, o_forwardB);

        $stop;
    end

endmodule
