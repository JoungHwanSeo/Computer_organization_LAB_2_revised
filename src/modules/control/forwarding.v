// forwarding.v

// This module determines if the values need to be forwarded to the EX stage.

// TODO: declare propoer input and output ports and implement the
// forwarding unit

module forwarding (
    input [4:0] ex_rs1,
    input [4:0] ex_rs2,
    input [4:0] mem_rd,
    input [4:0] wb_rd,
    input [6:0] mem_opcode,//opcode도 계속 pipeline해야하나...
    input [6:0] wb_opcode,

    //추가/////////////////////
    input [6:0] ex_opcode,
    ///////////////////////////

    ///////SW, Load stall 필요 없는 경우 추가
    //mem이 SW이고 WB가 Load이고
    input [4:0] mem_rs2, 
    // input [4:0] wb_rd, //이 두개가 같으면 Memory의 wirte_data를 mux처리해주면 됨
    //////////////////////////////////

    output reg [1:0] forwardA,
    output reg [1:0] forwardB,

    //SW에서 Write data 선택 logic....
    //5.6 19시 48분 추가
    output reg [1:0] forwardS,

    ///////SW, Load stall 필요 없는 경우 추가
    output reg forwardmem // 
);

/////////////Load의 경우????????

always@(*) begin
    ///////////////////MEM에 store, WB에 Load인 경우 그리고 wb rd가 mem rs2와 같은 경우
    if(mem_rs2 == wb_rd && mem_opcode == 7'b0100011 && wb_opcode == 7'b0000011) begin
        forwardmem = 1;
    end
    else begin
        forwardmem = 0;
    end
    ////////////////////////////////////////////////////////////////////////////////


    ///////////////////////@ rs1 @///////////////////////
    if(ex_rs1 == mem_rd && ex_rs1 != 0 && mem_opcode != 7'b1100011 && mem_opcode !=7'b0100011 && mem_opcode != 7'b0000011) begin
        //ALU에 들어갈 rs1이 뒤의 rd와 같고, rs1이 x0가 아니고, mem이 Store, Branch아니면(No Write), 그리고 Load아니면 [거리 1]
        forwardA = 2'b01; //Mem에서 Hazard..
    end
    else if(ex_rs1 == wb_rd && ex_rs1 != 0 && wb_opcode != 7'b1100011 && wb_opcode !=7'b0100011) begin
        //이 경우 거리가 2로 load아니라는 조건 필요 없음
        forwardA = 2'b10; //WB에서 hazard 
    end 
    else begin
        forwardA = 2'b00;
    end

    ////////////////////////@ rs2 @////////////////////////////
    if(ex_rs2 == mem_rd && ex_rs2 != 0 && mem_opcode != 7'b1100011 && mem_opcode !=7'b0100011 && mem_opcode != 7'b0000011 && ex_opcode != 7'b0010011 && ex_opcode != 7'b0000011 && ex_opcode != 7'b1100111 /*&& ex_opcode != 7'b0100011 SW..*/) begin
        //ALU에 들어갈 rs2가 뒤의 rd와 같고, rs1이 x0가 아니고, mem이 Store, Branch아니면(No Write), 그리고 Load아니면 [거리 1]
        //EX가 I-type 아니라는 조건 추가!!!!!!!! 5/6
        //EX가 JALR, Load아니라는 조건 추가 ALU에는 그냥 imm이 들어가니까... 즉 rs2를 사용하지 않는 명령어.. ex에서

        //rs2를 사용하지 않는 명령어는 SW도 있음 이거 19시 35분에 추가!!
        //근데 SW의 rs2는 memory의 address로 들어감 다른 얘들은 ALU in으로 들어가는데... 이거 고려해줘야함!!!
        //SW도 일단 imm이 들어가는 명령어임!!!!!!!! I종류임
        // forwardB = 2'b01; //Mem에서 Hazard..

        //추가!!!!!!!!!!!!!!
        if(ex_opcode != 7'b0100011) begin //SW가 아니면 alu에는 forwarded data가 들어가야함
            forwardS = 2'b00;
            forwardB = 2'b01;
        end
        else begin //SW이면 alu에는 imm이 들어가야함
            forwardS = 2'b01;
            forwardB = 2'b00;
        end
        //////////////////
    end
    else if(ex_rs2 == wb_rd && ex_rs2 != 0 && wb_opcode != 7'b1100011 && wb_opcode !=7'b0100011   && ex_opcode != 7'b0010011 && ex_opcode != 7'b0000011 && ex_opcode != 1100111) begin
        //EX_opcode가 I-type JALR Load아니라는 조건이 또 추가됨
        // forwardB = 2'b10; //WB에서 hazard

        //추가!!!!!!!!!!!!!///////////////////////////////
        if(ex_opcode != 7'b0100011) begin //SW가 아니면 alu에는 forwarded data가 들어가야함
            forwardS = 2'b00;
            forwardB = 2'b10;
        end
        else begin //SW이면 alu에는 imm이 들어가야함
            forwardS = 2'b10;
            forwardB = 2'b00;
        end
        /////////////////////////////////////////

    end
    else begin
        forwardB = 2'b00;

        //////////////////////추가
        forwardS = 2'b00;
        //////////////////////추가
    end

end

endmodule
