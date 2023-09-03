module apb_master (
  input wire clk,
  input wire rst,
  output wire [31:0] paddr,
  output wire pwrite,
  output wire [31:0] pwdata,
  input wire pready,
  output wire [3:0] psel // 4-bit select signal for multiple slaves
);

  reg [31:0] data_to_write;
  reg [31:0] addr;
  reg write_enable;
  reg [3:0] slave_select;
  
  // Clock Generation
  always begin
    #5 clk = ~clk;
  end

  // Reset Logic
  always begin
    if (rst == 0) begin
      addr <= 32'h0;
      write_enable <= 0;
      data_to_write <= 32'h0;
      slave_select <= 4'b0000;
    end
  end

  // Generate Address, Write Data, and Control Signals
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      addr <= 32'h0;
      write_enable <= 0;
      data_to_write <= 32'h0;
    end else if (pready) begin
      if (addr < 32'h1000) begin
        addr <= addr + 1;
        write_enable <= 1;
        data_to_write <= addr;
      end
    end
  end

  // Connect Outputs
  assign paddr = addr;
  assign pwrite = write_enable;
  assign pwdata = data_to_write;
  assign psel = slave_select;

  // Example: Switch the slave select based on the address
  always @(posedge clk) begin
    if (addr[15:12] == 4'b0000) // Check bits [15:12] for slave selection
      slave_select <= 4'b0001; // Select Slave 1
    else if (addr[15:12] == 4'b0001)
      slave_select <= 4'b0010; // Select Slave 2
    // Add more slave selection conditions as needed for additional slaves
  end

endmodule

module apb_slave (
  input wire clk,
  input wire rst,
  input wire [31:0] paddr,
  input wire pwrite,
  input wire [31:0] pwdata,
  output wire pready
);

  reg [31:0] reg_data [0:15]; // Register file for each slave
  reg [3:0] slave_id; // Slave ID
  
  // Clock Generation
  always begin
    #5 clk = ~clk;
  end

  // Reset Logic
  always begin
    if (rst == 0) begin
      for (int i = 0; i < 16; i = i + 1) begin
        reg_data[i] <= 32'h0;
      end
      slave_id <= 4'b0000;
    end
  end

  // APB Slave Logic
  always @(posedge clk or negedge rst) begin
    if (!rst) begin
      // Reset logic
      for (int i = 0; i < 16; i = i + 1) begin
        reg_data[i] <= 32'h0;
      end
    end else if (pwrite && (slave_id == paddr[15:12])) begin
      // Write operation to the selected slave based on address bits [15:12]
      if (paddr[1:0] == 2'b00) begin
        reg_data[paddr[3:2]] <= pwdata;
      end
    end
  end

  // Ready Signal
  assign pready = 1'b1; // Assuming always ready

  // Assign Slave ID based on top-level select signal (psel)
  always @(posedge clk) begin
    case (psel)
      4'b0001: slave_id = 4'b0000; // Slave 1
      4'b0010: slave_id = 4'b0001; // Slave 2
      // Add more cases for additional slaves as needed
      default: slave_id = 4'b0000; // Default to Slave 1
    endcase
  end

endmodule

module tb_apb;
  reg clk;
  reg rst;
  wire [31:0] paddr;
  wire pwrite;
  wire [31:0] pwdata;
  wire pready;
  wire [3:0] psel; // 4-bit select signal for multiple slaves

  apb_master master (
    .clk(clk),
    .rst(rst),
    .paddr(paddr),
    .pwrite(pwrite),
    .pwdata(pwdata),
    .pready(pready),
    .psel(psel)
  );

  apb_slave slave1 (
    .clk(clk),
    .rst(rst),
    .paddr(paddr),
    .pwrite(pwrite),
    .pwdata(pwdata),
    .pready(pready)
  );

  apb_slave slave2 (
    .clk(clk),
    .rst(rst),
    .paddr(paddr),
    .pwrite(pwrite),
    .pwdata(pwdata),
    .pready(pready)
  );

  // Add more slave instances as needed for additional slaves

  initial begin
    clk = 0;
    rst = 1;

    // Reset the design
    #10 rst = 0;

    // Simulate transactions to each slave
    #20;
    rst = 1;

    $finish;
  end

  always begin
    #5;
  end

endmodule
