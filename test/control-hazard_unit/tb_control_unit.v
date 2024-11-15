`timescale 1ns/1ps

module control_unit_tb;

    // Parameters
    parameter NB_SGN = 20;
    parameter NB_OP = 6;

    // Inputs
    reg i_enable;
    reg [NB_OP-1:0] i_inst_opcode;
    reg [NB_OP-1:0] i_inst_function;

    // Outputs
    wire [NB_SGN-1:0] o_signals;

    // Expected signals for comparison
    reg [NB_SGN-1:0] expected_signals;

    // Instantiate the control_unit module
    control_unit #(
        .NB_SGN(NB_SGN),
        .NB_OP(NB_OP)
    ) uut (
        .i_enable(i_enable),
        .i_inst_opcode(i_inst_opcode),
        .i_inst_function(i_inst_function),
        .o_signals(o_signals)
    );

    // Test procedure
    initial begin
        // Enable the module
        i_enable = 1'b0;

        // Test case 1: ADDU (R-type)
        i_inst_opcode = 6'b000000;
        i_inst_function =  6'b100001; // ADDU
        expected_signals = 20'b0000000100000000100;
        #10; // wait 10 ns
        i_enable = 1'b1;
        #10;
        $display("Test ADDU: o_signals = %b, Expected = %b, Result: %s", 
                 o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");

        // Test case 2: BEQ
        i_inst_opcode = 6'b000100;
        i_inst_function = 6'bxxxxxx; // Don't care
        expected_signals = 20'b00110001110000000000;  
        #10;
        $display("Test BEQ: o_signals = %b, Expected = %b, Result: %s", 
                 o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");

        // Test case 2: BNE
        i_inst_opcode = 6'b000101;
        i_inst_function = 6'b000000; // Don't care
        expected_signals = 20'b00100001110000000000;  
        #10;
        $display("Test BNE: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");

        // Test case 3: J (Jump)
        i_inst_opcode = 6'b000010;
        i_inst_function = 6'b000000; // Don't care
        expected_signals = 20'b10000000000000000000;  
        #10;
        $display("Test J: o_signals = %b, Expected = %b, Result: %s", 
                 o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");

        // Test case 3: JAL 
        i_inst_opcode = 6'b000011;
        i_inst_function = 6'b000000; // Don't care
        expected_signals = 20'b10000000001000000110;  
        #10;
        $display("Test JAL: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        /////////////
        // Test case 4: Load Byte (LB)
        i_inst_opcode = 6'b100000; // LOAD
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100000100001100;  
        #10;
        $display("Test LB (Load Byte): o_signals = %b, Expected = %b, Result: %s", 
                 o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");

       // Test case 4: Load HALF (LH)
        i_inst_opcode = 6'b100001; // LOAD
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100000100011100;  
        #10;
        $display("Test Load HALFByte (LH) o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");

        // Test case 4: Load WORD (LW)
        i_inst_opcode = 6'b100011; 
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100000100111100;  
        #10;
        $display("Test Load WORD (LW): o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");

        // Test case 4: Load WORD Unsigned (LWU)
        i_inst_opcode = 6'b100111; // LOAD
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100000101111100;  
        #10;
        $display("Test Load WORD Unsigned (LWU): o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        // Test case 4: Load Byte Unsigned (LBU)
        i_inst_opcode = 6'b100100; // LOAD
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100000101001100;  
        #10;
        $display("Test Load Byte Unsigned (LBU) o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        
        // Test case 4: Load Half Unsigned (LHU)
        i_inst_opcode = 6'b100101; // LOAD
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100000101011100;  
        #10;
        $display("Test Load Half Unsigned (LHU) o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
    

        // Test case 5: Store Byte (SB)
        i_inst_opcode = 6'b101000; // STORE
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100000010000000;  
        #10;
        $display("Test SB (Store Byte): o_signals = %b, Expected = %b, Result: %s", 
                 o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        // Test case 5: Store Half (SH)
        i_inst_opcode = 6'b101001; // STORE
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100000010010000;  
        #10;
        $display("Test Store Half (SH): o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");

        // Test case 5: Store Word (SW)
        i_inst_opcode = 6'b101011; // STORE
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100000010110000;  
        #10;
        $display("Test Store Word (SW): o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");

        //tb inmediately
        // Test 
        i_inst_opcode = 6'b001000; //ADDI
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100000000000100;  
        #10;
        $display("Test ADDI: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        
        i_inst_opcode = 6'b001001; //ADDIU
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001100010000000100;  
        #10;
        $display("Test ADDIU: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        
        i_inst_opcode = 6'b001100; //ANDI
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001101000000000100;  
        #10;
        $display("Test ANDI: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        
        i_inst_opcode = 6'b001101; //ORI
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001101010000000100;  
        #10;
        $display("Test ORI: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
         
        i_inst_opcode = 6'b001110; //XORI
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001110000000000100;  
        #10;
        $display("Test XORI: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        
        i_inst_opcode = 6'b001111; //LUI
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001110010000000100;  
        #10;
        $display("Test LUI: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        
        i_inst_opcode = 6'b001010; //SLTI
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001111000000000100;  
        #10;
        $display("Test SLTI: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
                
        i_inst_opcode = 6'b001011; //SLTIU
        i_inst_function = 6'b111111; // Don't care
        expected_signals = 20'b00001111010000000100;  
        #10;
        $display("Test SLTIU: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        
                
        i_inst_opcode = 6'b000000; //JR
        i_inst_function = 6'b001000; 
        expected_signals = 20'b01000000000000000000;  
        #10;
        $display("Test JR: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
        
                
        i_inst_opcode = 6'b000000; //JALR
        i_inst_function = 6'b001001; 
        expected_signals = 20'b01000000000000000110;  
        #10;
        $display("Test JALR: o_signals = %b, Expected = %b, Result: %s", 
                o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");
                            
                // Test case 6: HALT
        i_inst_opcode = 6'b000000;
        i_inst_function = 6'b111111; // HALT
        expected_signals = 20'b00000000000000000001;  
        #10;
        $display("Test HALT: o_signals = %b, Expected = %b, Result: %s", 
                 o_signals, expected_signals, (o_signals == expected_signals) ? "PASS" : "FAIL");


        // Finish simulation
        $finish;
    end

endmodule
