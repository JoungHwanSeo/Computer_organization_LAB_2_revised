// control.v

// The main control module takes as input the opcode field of an instruction
// (i.e., instruction[6:0]) and generates a set of control signals.

module control(
  input [6:0] opcode,

  input id_flush,

  output [1:0] jump,
  output branch,
  output mem_read,
  output mem_to_reg,
  output [1:0] alu_op,
  output mem_write,
  output alu_src,
  output reg_write
);

reg [9:0] controls;

// combinational logic
always @(*) begin
  if(id_flush) begin
    controls = 10'b00_000_00_000;
  end
  else begin
    case (opcode)
    
      7'b0110011: controls = 10'b00_000_10_001; // R-type

      //////////////////////////////////////////////////////////////////////////
       // TODO : Implement signals for other instruction types
      7'b0010011: controls = 10'b00_000_11_011;  //arithmetic연산 I-type ALUop는 2'b11
      7'b0000011: controls = 10'b00_011_00_011; //I-type , Load
      7'b0100011: controls = 10'b00_000_00_110; //S-type , Store

      //branch다시보기 ALU를 공유해야하는경우...!!!!!!!!!!!!!
      7'b1100011: controls = 10'b01_100_01_000; //branch 인경우 jump가 [01]
      7'b1101111: controls = 10'b11_000_00_001; //JAL[11] 이건 좀 다른 부분에서 추가구현이 필요할듯 + register는 update되어야 함 
      7'b1100111: controls = 10'b10_000_00_011; //JALR[10] result를 target address로 보내야함 + register는 update되어야 함
      //JUMP의 경우 모두 ALU는 덧셈연산!!!
      //////////////////////////////////////////////////////////////////////////
      
    // 7'b0110011: controls = 10'b00_000_10_001; // R-type

    // //////////////////////////////////////////////////////////////////////////
    // // TODO : Implement signals for other instruction types
    // 7'b0010011: controls = 10'b00_000_11_011;  //arithmetic연산 I-type ALUop는 2'b11
    // 7'b0000011: controls = 10'b00_011_00_011; //I-type , Load
    // 7'b0100011: controls = 10'b00_000_00_110; //S-type , Store

    // //branch다시보기 ALU를 공유해야하는경우...!!!!!!!!!!!!!
    // 7'b1100011: controls = 10'b01_100_01_000; //branch 인경우 jump가 [01]
    // 7'b1101111: controls = 10'b11_000_00_001; //JAL[11] 이건 좀 다른 부분에서 추가구현이 필요할듯 + register는 update되어야 함 
    // 7'b1100111: controls = 10'b10_000_00_011; //JALR[10] result를 target address로 보내야함 + register는 update되어야 함
    // //JUMP의 경우 모두 ALU는 덧셈연산!!!
    // //////////////////////////////////////////////////////////////////////////

    default:    controls = 10'b00_000_00_000;
  endcase
  end
end

assign {jump, branch, mem_read, mem_to_reg, alu_op, mem_write, alu_src, reg_write} = controls;

endmodule
