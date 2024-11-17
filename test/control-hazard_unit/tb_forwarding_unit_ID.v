`timescale 1ns / 1ps

module tb_forwarding_unit_ID;

    // Parámetros
    parameter NB_ADDR = 5;

    // Entradas
    reg [NB_ADDR-1:0] i_rs_id;
    reg [NB_ADDR-1:0] i_rt_id;
    reg [NB_ADDR-1:0] i_rd_ex_m;
    reg               i_regWrite_ex_m;

    // Salidas
    wire              o_forwardA_ID;
    wire              o_forwardB_ID;

    // Instancia del módulo
    forwarding_unit_ID #(
        .NB_ADDR(NB_ADDR)
    ) u_forwarding_unit_ID (
        .i_rs_id(i_rs_id),
        .i_rt_id(i_rt_id),
        .i_rd_ex_m(i_rd_ex_m),
        .i_regWrite_ex_m(i_regWrite_ex_m),
        .o_forwardA_ID(o_forwardA_ID),
        .o_forwardB_ID(o_forwardB_ID)
    );

    // Estímulos
    initial begin
        $display("Time\tRegWrite\tRS\tRT\tRD\tForwardA\tForwardB");
        $display("-----------------------------------------------------");

        // Caso 1: No hay forwarding (RegWrite = 0)
        i_rs_id = 5'b00001;
        i_rt_id = 5'b00010;
        i_rd_ex_m = 5'b00011;
        i_regWrite_ex_m = 0;
        #10;
        $display("%0dns\t%b\t\t%b\t%b\t%b\t%b\t\t%b", 
                  $time, i_regWrite_ex_m, i_rs_id, i_rt_id, i_rd_ex_m, o_forwardA_ID, o_forwardB_ID);

        // Caso 2: Forwarding para rs (RegWrite = 1 y rs = rd)
        i_rs_id = 5'b00011;
        i_rt_id = 5'b00010;
        i_rd_ex_m = 5'b00011;
        i_regWrite_ex_m = 1;
        #10;
        $display("%0dns\t%b\t\t%b\t%b\t%b\t%b\t\t%b", 
                  $time, i_regWrite_ex_m, i_rs_id, i_rt_id, i_rd_ex_m, o_forwardA_ID, o_forwardB_ID);

        // Caso 3: Forwarding para rt (RegWrite = 1 y rt = rd)
        i_rs_id = 5'b00001;
        i_rt_id = 5'b00011;
        i_rd_ex_m = 5'b00011;
        i_regWrite_ex_m = 1;
        #10;
        $display("%0dns\t%b\t\t%b\t%b\t%b\t%b\t\t%b", 
                  $time, i_regWrite_ex_m, i_rs_id, i_rt_id, i_rd_ex_m, o_forwardA_ID, o_forwardB_ID);

        // Caso 4: Forwarding para ambos (rs = rd y rt = rd)
        i_rs_id = 5'b00100;
        i_rt_id = 5'b00100;
        i_rd_ex_m = 5'b00100;
        i_regWrite_ex_m = 1;
        #10;
        $display("%0dns\t%b\t\t%b\t%b\t%b\t%b\t\t%b", 
                  $time, i_regWrite_ex_m, i_rs_id, i_rt_id, i_rd_ex_m, o_forwardA_ID, o_forwardB_ID);

        // Caso 5: Sin coincidencias (RegWrite = 1, rs y rt diferentes de rd)
        i_rs_id = 5'b00001;
        i_rt_id = 5'b00010;
        i_rd_ex_m = 5'b00100;
        i_regWrite_ex_m = 1;
        #10;
        $display("%0dns\t%b\t\t%b\t%b\t%b\t%b\t\t%b", 
                  $time, i_regWrite_ex_m, i_rs_id, i_rt_id, i_rd_ex_m, o_forwardA_ID, o_forwardB_ID);

        $stop;
    end

endmodule
