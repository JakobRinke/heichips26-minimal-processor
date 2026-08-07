

module register_file(
  
  input wire clk,
  input wire rst_n,

  
  input wire [2:0] addr1,
  input wire [2:0] addr2,

  input wire [7:0] wb_data,
  
  input wire done_mem,
  input wire done_decoding,

  output reg [7:0] data_1,
  output reg [7:0] data_2,

  output reg done_reading,
  output reg done_writing
);

reg [0:7] registers [4:7];

always @(posedge clk) begin
  done_reading <= 0;
  done_writing <= 0;
  
  if (rst_n == 0) begin
    done_reading <= 0;
    done_writing <= 0;
    data_1 <= 0;
    data_2 <= 0;
  end else if (done_decoding== 1) begin
    // Do reading
    case (addr1)
      0: data_1 <= 0;
      1: data_1 <= registers[4] & registers[5];
      2: data_1 <= ~registers[4];
      3: data_1 <= registers[4] | registers[5];
      default:  data_1 <= registers[addr1];
    endcase

    case (addr2)
      0: data_2 <= 0;
      1: data_2 <= 0;
      2: data_2 <= 0;
      3: data_2 <=  0;
      default:  data_2 <= registers[addr2];
    endcase

    done_reading <= 1;
  end else if (done_mem == 1) begin
    if (addr2[2]) registers[addr2] <= wb_data;
    done_writing <= 1;
  end

end;


endmodule;
 
