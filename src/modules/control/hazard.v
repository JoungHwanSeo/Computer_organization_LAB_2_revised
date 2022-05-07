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

    // input [6:0] ex_opcode,
    // input [6:0] mem_opcode,
    // input [4:0] ex_rs1,
    // input [4:0] ex_rs2,
    // input [4:0] mem_rd,

    input [6:0] id_opcode,
    input [6:0] ex_opcode,
    input [4:0] id_rs1,
    input [4:0] id_rs2,
    input [4:0] ex_rd,

    //SW stall안하면서 생긴 추가 구현

    // input [6:0] mem_opcode, //이게 store이고
    // input [6:0] wb_opcode, //이게 load이고
    // input [4:0] mem_rs2, 
    // input [4:0] wb_rd, //이 두개가 같으면 Memory의 wirte_data를 mux처리해주면 됨

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

    
    //SW stall안하면서 생긴 추가 구현
    // output forward_Mem;
);

reg if_flush_tmp;


////////////////////////////////////////Load Dependence... Stall
reg Load_dep_1; // Load의 Data dependence있는지
reg Load_dep_2;

always@(*) begin

    //이 경우는 forwarding과 다르게 rs1,2를 실제 사용하는지 여부도 중요함... cycle을 낭비할 수 있기 때문임
        //rs1을 사용하지 않는 경우는 JAL인 경우! =>rs2의 경우 I-type와 JALR도 사용하지 않음
        ///MEM 단계가 load이고, EX의 rs1이 rd와 같고, x0가 아니면 stall해야함
        //MEM은 계속 진행되어 한 사이클 뒤에 Data forwarding 모듈이 EX-WB관계를 캐치해서 ALU에 해당 데이터 forwarding 해줄것

        //근데 진짜 만약에 ex_rs1이랑 ex_rd가 같고 ex_opcode가 Load이면 무한 stall이 되는 것 아닌가??????????
        //ex가 control signal만 0이 되어 MEM으로 들어가는거니까... 이건 나중에 생각해!!!!!!

        ///////////ex_rs1을 0으로 보내버리면 되지 않을까????? EX_MEM_flush받으면

    //rs1
    if(id_rs1 == ex_rd && ex_opcode == 7'b0000011 && id_rs1 != 0 && id_opcode != 7'b1101111) begin
        //EX가 Load이고 id의 rs1 == ex의 rd이고 rs1이 x0아니고 rs1이 사용되는 명령어일시 (JAL아닐시)
        Load_dep_1 = 1;

        //이건 id가 store 여부 상관없이 그냥 stall해야함

        // if(id_opcode != 7'b0100011) begin //id가 store 아닌경우
        //     Load_dep_1 = 1;
        // end
        // else begin //id가 store인 경우에는 굳이 stall해줄 필요 없음! 
        //     Load_dep_1 = 0;
        // end
    end
    else begin
        Load_dep_1 = 0;
    end
    //rs2
    if(id_rs2 == ex_rd && ex_opcode == 7'b0000011 && id_rs2 != 0 && id_opcode != 7'b1101111 /*&& id_opcode != 7'b1100011*/ && id_opcode != 7'b0010011 && id_opcode != 7'b1100111 && id_opcode != 7'b0000011) begin
        //EX가 Load이고 id의 rs2 == ex의 rd이고 rs2가 x0아니고 rs2가 사용되는 명령어일시 (JAL / Branch이건 rs2사용함..ㅋㅋㅋ실수! / I-type아닐시)
        //id의 rs2가 사용되지 않는 명령어 JALR , Load아니라는 조건 추가
        // Load_dep_2 = 1;
        if(id_opcode != 7'b0100011) begin  //id가 store 아니면 stall해야함
            Load_dep_2 = 1;
        end
        else begin  //id가 store인 경우에는 stall해줄 필요 없다.
            Load_dep_2 = 0;
        end
    end
    else begin
        Load_dep_2 = 0;
    end

end

always@(*) begin
    stall = Load_dep_1 | Load_dep_2;
    // ex_mem_flush = Load_dep_1 | Load_dep_2;
end






/////////////////////////////////////Contorl Hazard... Flush

always@(*) begin
    // if_instruction_real = if_instruction;  // 일단 주먹구구식으로 고쳐보자..
    
    // if(rstn == 0) begin
    //     if_flush = 0;
    // end
    
    case(ex_jump)
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
        2'b10:begin  //JALR
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