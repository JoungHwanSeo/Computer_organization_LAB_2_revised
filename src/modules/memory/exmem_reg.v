//exmem_reg.v


module exmem_reg #(
  parameter DATA_WIDTH = 32
)(
  // TODO: Add flush or stall signal if it is needed

  //////////////////////////////////////
  // Inputs
  //////////////////////////////////////
  input clk,

  input [DATA_WIDTH-1:0] ex_pc_plus_4,
  input [DATA_WIDTH-1:0] ex_pc_target,
  input ex_taken,

  // mem control
  input ex_memread,
  input ex_memwrite,

  // wb control
  input [1:0] ex_jump,
  input ex_memtoreg,
  input ex_regwrite,
  
  input [DATA_WIDTH-1:0] ex_alu_result,
  input [DATA_WIDTH-1:0] ex_writedata,
  input [2:0] ex_funct3,
  input [4:0] ex_rd,

  //////내가 추가!!!///////
  input [6:0] ex_opcode,

  // input ex_mem_flush,
  ////////////////////////

  //////stall logic 위해 이거 추가
  input [4:0] ex_rs2,
  ////////////////////////
  
  //////////////////////////////////////
  // Outputs
  //////////////////////////////////////
  output reg [DATA_WIDTH-1:0] mem_pc_plus_4,
  output reg [DATA_WIDTH-1:0] mem_pc_target,
  output reg mem_taken,

  // mem control
  output reg mem_memread,
  output reg mem_memwrite,

  // wb control
  output reg [1:0] mem_jump,
  //jump가 필요한 이유는 jump signal에 따라 register에 PC+4넣어줘야함
  output reg mem_memtoreg,
  output reg mem_regwrite,
  
  output reg [DATA_WIDTH-1:0] mem_alu_result,
  output reg [DATA_WIDTH-1:0] mem_writedata,
  output reg [2:0] mem_funct3,
  output reg [4:0] mem_rd,

  //////내가 추가!!!!!!!!!!!!
  output reg [6:0] mem_opcode,
  //////////////////

  output reg [4:0] mem_rs2
);

// TODO: Implement EX / MEM pipeline register module
  always@(posedge clk) begin
    mem_pc_plus_4 <= ex_pc_plus_4;
    mem_pc_target <= ex_pc_target;
    mem_taken <= ex_taken;
    mem_memread <= ex_memread;
    // mem_memwrite <= ex_memwrite;
    mem_jump <= ex_jump;
    mem_memtoreg <= ex_memtoreg;
    // mem_regwrite <= ex_regwrite;
    mem_alu_result <= ex_alu_result;
    mem_writedata <= ex_writedata;
    mem_funct3 <= ex_funct3;

    //stall되어 rs1과 rd가 똑같은 명령어인 경우 신셩 안써야 할 명령어에서 forwarding이 생길 수 있음
    // mem_rd <= ex_rd;
    /////////////////////////

    // mem_opcode <= ex_opcode;//추가됨

    mem_memwrite <= ex_memwrite;
    mem_regwrite <= ex_regwrite;

    mem_opcode <= ex_opcode;  // LW 연속 case 방지

    mem_rd <= ex_rd;

    mem_rs2 <= ex_rs2;

    // if(ex_mem_flush == 1) begin
    //   mem_memwrite <= 0;
    //   mem_regwrite <= 0;

    //   mem_opcode <= 7'b0000000;  //LW 연속 case 방지

    //   mem_rd <= 0; ///stall되어 rs1과 rd가 똑같은 명령어인 경우 신셩 안써야 할 명령어에서 forwarding이 생길 수 있음
    // end
    // else begin
    //   mem_memwrite <= ex_memwrite;
    //   mem_regwrite <= ex_regwrite;

    //   mem_opcode <= ex_opcode;  // LW 연속 case 방지

    //   mem_rd <= ex_rd;
    // end

  end

endmodule
