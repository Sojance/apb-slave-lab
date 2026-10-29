`timescale 1ns/1ps

module TB;
    logic pclk, presetn;
    logic psel, penable, pwrite;
    logic [31:0] paddr, pwdata;
    wire  [31:0] prdata;
    wire  pready, pslverr;

    logic [31:0] data_from_device;
    parameter p_device_offset = 32'h7000_0000;

    // Подключаем слейв
    apb_slave DUT (
        .pclk(pclk), .presetn(presetn), .paddr(paddr), .pwdata(pwdata),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .pready(pready), .pslverr(pslverr), .prdata(prdata)
    );

    // Подключаем мастер
    apb_master MASTER (
        .pclk(pclk), .presetn(presetn),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .paddr(paddr), .pwdata(pwdata),
        .pready(pready), .pslverr(pslverr), .prdata(prdata)
    );

    // Генератор тактового сигнала
    always #10ns pclk = ~pclk;

    initial begin
        pclk = 0; presetn = 1'b1;
        // Сброс
        repeat (5) @(posedge pclk);
        presetn = 1'b0;
        repeat (5) @(posedge pclk);
        presetn = 1'b1;
        repeat (5) @(posedge pclk);

        $display("\n--- TEST 8 (Logic AAAA/5555) ---");
        MASTER.apb_write(p_device_offset + 32'h0, 32'h0000_0000);
        MASTER.apb_read (p_device_offset + 32'h0, data_from_device);
        $display("[TEST 8] Write 0 -> Read: 0x%h (Expect 0xAAAAAAAA)", data_from_device);

        MASTER.apb_write(p_device_offset + 32'h0, 32'h0000_0001);
        MASTER.apb_read (p_device_offset + 32'h0, data_from_device);
        $display("[TEST 8] Write 1 -> Read: 0x%h (Expect 0x55555555)", data_from_device);

        $display("\n--- TEST 9 (Student Data) ---");
        // Запись данных
        MASTER.apb_write(p_device_offset + 32'h0, 32'h0000_0007); // Group number 7
        MASTER.apb_write(p_device_offset + 32'h4, 32'h26102026);  // Date 26.10.2026
        MASTER.apb_write(p_device_offset + 32'h8, 32'h53746570);  // "Step"
        MASTER.apb_write(p_device_offset + 32'hC, 32'h4976616E);  // "Ivan"

        // Чтение и проверка
        MASTER.apb_read(p_device_offset + 32'h4, data_from_device);
        $display("[TEST 9] Write/Read Date:    0x%h (26.10.2026)", data_from_device);
        
        MASTER.apb_read(p_device_offset + 32'h8, data_from_device);
        $display("[TEST 9] Write/Read Surname: 0x%h (Step)", data_from_device);
        
        MASTER.apb_read(p_device_offset + 32'hC, data_from_device);
        $display("[TEST 9] Write/Read Name:    0x%h (Ivan)", data_from_device);
        $display("[TEST 9] Group number written: 7 (0x0 is used by AAAA/5555 logic)");

        repeat (10) @(posedge pclk);
        $display("\nSimulation finished successfully.\n");
        $stop();
    end
endmodule
