module hazard
#(parameter DATA_WIDTH = 32) (



    /////////////////input//////////////////
    input [DATA_WIDTH-1:0] ex_alu_result, //JALR의 경우...
    input [DATA_WIDTH-1:0] ex_branch_target, // PC + sext(imm)으로 branch/JAL커버가능
    input ex_branch_taken,
    input [1:0] ex_jump,
    input [DATA_WIDTH-1:0] if_pc_plus_4,

    //id에 있는 명령어 flush하기 위함
    input id_mem_write,
    input id_reg_write,
    
    

    // input [DATA_WIDTH-1:0] if_instruction,

    ////////////////Stall 위한 input
    input [6:0] ex_opcode,
    input [6:0] mem_opcode,
    input [4:0] ex_rs1,
    input [4:0] ex_rs2,
    input [4:0] mem_rd,

    ////////////////////output///////////////////////
    output reg [DATA_WIDTH-1:0] NEXT_PC,
    //branch나 jump일어나는 경우 이 contorl signal을 0으로
    output reg id_mem_write_real,
    output reg id_reg_write_real,
    // output reg [DATA_WIDTH-1:0] if_instruction_real, //add x0 x0 x0넣음
    // 32'b0000000_00000_00000_000_00000_0110011

    //////////////////Stall 위한 output
    output reg stall,
    output reg ex_mem_flush, //현재 EX에 있는 명령어는 의미없이 지나가도록... 앞의 reg stall해서 똑같은 명령어 한번 더 볼거임

    output if_flush
);

reg if_flush_tmp;

////////////////////////////////////////Load Dependence... Stall
reg Load_dep_1; // Load의 Data dependence있는지
reg Load_dep_2;

always@(*) begin

    //rs1
    if(ex_rs1 == mem_rd && mem_opcode == 7'b0000011 && ex_rs1 != 0 && ex_opcode != 7'b1101111) begin
        //MEM이 Load이고 ex의 rs1 == mem의 rd이고 rs1이 x0아니고 rs1이 사용되는 명령어일시 (JAL아닐시)
        Load_dep_1 = 1;
    end
    else begin
        Load_dep_1 = 0;
    end
    //rs2
    if(ex_rs2 == mem_rd && mem_opcode == 7'b0000011 && ex_rs2 != 0 && ex_opcode != 7'b1101111 && ex_opcode != 7'b1100011 && ex_opcode != 7'b0010011) begin
        //MEM이 Load이고 ex의 rs2 == mem의 rd이고 rs2가 x0아니고 rs2가 사용되는 명령어일시 (JAL / Branch / I-type아닐시)
        Load_dep_2 = 1;
    end
    else begin
        Load_dep_2 = 0;
    end

end

always@(*) begin
    stall = Load_dep_1 | Load_dep_2;
    ex_mem_flush = Load_dep_1 | Load_dep_2;
end






/////////////////////////////////////Contorl Hazard... Flush

always@(*) begin
    // if_instruction_real = if_instruction;  // 일단 주먹구구식으로 고쳐보자..
    
    // if(rstn == 0) begin
    //     if_flush = 0;
    // end
    
    casex(ex_jump)
        2'b01: begin //branch
            if(ex_branch_taken == 1) begin
                NEXT_PC = ex_branch_target;
                id_mem_write_real = 0;
                id_reg_write_real = 0;
                // if_instruction_real = 32'b0000000_00000_00000_000_00000_0000000;
                if_flush_tmp = 1;
            end
            else begin
                NEXT_PC = if_pc_plus_4;  //branch가 taken이 아닌경우
                id_mem_write_real = id_mem_write;
                id_reg_write_real = id_reg_write;
                // if_instruction_real = if_instruction;
                if_flush_tmp = 0;
            end
        end 
        2'b11:begin //JAL
            NEXT_PC = ex_branch_target;
            id_mem_write_real = 0;
            id_reg_write_real = 0;
            // if_instruction_real = 32'b0000000_00000_00000_000_00000_0000000;
            if_flush_tmp = 1;
        end
        2'b10:begin
            NEXT_PC = ex_alu_result;
            id_mem_write_real = 0;
            id_reg_write_real = 0;
            // if_instruction_real = 32'b0000000_00000_00000_000_00000_0000000;
            if_flush_tmp = 1;
        end
        default: begin
            NEXT_PC = if_pc_plus_4; // branch, jump아닌경우
            id_mem_write_real = id_mem_write;
            id_reg_write_real = id_reg_write;
            // if_instruction_real = if_instruction;
            if_flush_tmp = 0;
        end
    endcase
    
   
end
assign if_flush = if_flush_tmp;

endmodule