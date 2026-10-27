module TB;
    logic pclk, presetn, psel, penable, pwrite;
    logic [31:0] paddr, pwdata;
    wire  [31:0] prdata;
    wire  pready, pslverr;

    logic [31:0] data_from_device;
    parameter p_device_offset = 32'h7000_0000;

    apb_slave DUT (
        .pclk(pclk), .presetn(presetn), .paddr(paddr), .pwdata(pwdata),
        .psel(psel), .penable(penable), .pwrite(pwrite),
        .pready(pready), .pslverr(pslverr), .prdata(prdata)
    );

    task apb_write(input [31:0] addr, [31:0] data);
        wait ((penable==0) && (pready == 0));
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

    task apb_read(input [31:0] addr, output logic [31:0] data);
        wait ((penable==0) && (pready == 0));
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

    always #10ns pclk = ~pclk;

    initial begin
        pclk = 0; presetn = 1'b1; psel = '0; penable = '0; pwrite = '0; paddr = '0; pwdata = '0;
        repeat (5) @(posedge pclk);
        presetn = 1'b0;
        repeat (5) @(posedge pclk);
        presetn = 1'b1;
        repeat (5) @(posedge pclk);

        apb_write(p_device_offset + 32'h0, 32'h0000_0000);
        apb_read (p_device_offset + 32'h0, data_from_device);
        $display("[TEST 8] Write 0 -> Read: 0x%h (Expect 0xAAAAAAAA)", data_from_device);

        apb_write(p_device_offset + 32'h0, 32'h0000_0001);
        apb_read (p_device_offset + 32'h0, data_from_device);
        $display("[TEST 8] Write 1 -> Read: 0x%h (Expect 0x55555555)", data_from_device);

        apb_write(p_device_offset + 32'h0, 32'h0000_0007);
        apb_write(p_device_offset + 32'h4, 32'h26102026);
        apb_write(p_device_offset + 32'h8, 32'h53746570);
        apb_write(p_device_offset + 32'hC, 32'h4976616E);

        repeat (10) @(posedge pclk);
        $stop();
    end
endmodule
