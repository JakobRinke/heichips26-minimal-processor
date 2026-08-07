

module register_file(
  
  input wire clk,
  input wire rst_n,

  
  input wire [2:0] addr1,
  input wire [2:0] addr2,

  input wire [7:0] wb_data,
  
  input wire done_mem,
  input wire done_decoding,

  input wire current_pc,

  output reg [7:0] data_1,
  output reg [7:0] data_2,

  output reg done_reading,
  output reg done_writing
);

reg [0:7] registers [6:1];

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
    if (addr1 == 0) begin
      data_1 <= 0;
    end else if (addr1 == 7) begin 
      data_1 <= current_pc;
    end else if (addr1 == 6) begin 
      data_1 <= ~registers[1];
    end else begin
      data_1 <= registers[addr1];
    end

    if (addr2 == 0) begin
      data_2 <= 0;
    end else if (addr2 == 7) begin 
      data_2 <= current_pc;
    end else  if (addr2 == 6) begin 
      data_2 <= ~registers[1];
    end else begin
      data_2 <= registers[addr2];
    end

    done_reading <= 1;
  end else if (done_mem == 1) begin
    if (addr2 != 0 && addr2 != 7 && addr2 != 6) registers[addr2] <= wb_data;
    done_writing <= 1;
  end

end;


endmodule;
 