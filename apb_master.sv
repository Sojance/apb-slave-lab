module apb_master (
    input  logic        pclk,
    input  logic        presetn,
    output logic        psel,
    output logic        penable,
    output logic        pwrite,
    output logic [31:0] paddr,
    output logic [31:0] pwdata,
    input  logic        pready,
    input  logic        pslverr,
    input  logic [31:0] prdata
);

    // Инициализация выходных сигналов (чтобы не было X)
    initial begin
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = '0;
        pwdata  = '0;
    end

    // Задача записи по шине APB
    task apb_write(input [31:0] addr, input [31:0] data);
        wait ((penable == 0) && (pready == 0));
        @(posedge pclk);
        psel <= 1'b1; paddr <= addr; pwdata <= data; pwrite <= 1'b1;
        @(posedge pclk);
        penable <= 1'b1;
        @(posedge pclk);
        wait (pready == 1'b1);
        @(posedge pclk);
        psel <= 1'b0; penable <= 1'b0; pwrite <= 1'b0;
        @(posedge pclk);
    endtask

    // Задача чтения по шине APB
    task apb_read(input [31:0] addr, output logic [31:0] data);
        wait ((penable == 0) && (pready == 0));
        @(posedge pclk);
        psel <= 1'b1; pwrite <= 1'b0; paddr <= addr;
        @(posedge pclk);
        penable <= 1'b1;
        @(posedge pclk);
        wait (pready == 1'b1);
        @(posedge pclk);
        data <= prdata;
        psel <= 1'b0; penable <= 1'b0;
        @(posedge pclk);
    endtask

endmodule