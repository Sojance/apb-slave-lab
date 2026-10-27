module apb_slave
(
    input  logic        pclk,
    input  logic        presetn,
    input  logic [31:0] paddr,
    input  logic [31:0] pwdata,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    output logic        pready,
    output logic        pslverr,
    output logic [31:0] prdata
);

    logic [31:0] register_with_some_name;
    logic [31:0] reg_number;
    logic [31:0] reg_date;
    logic [31:0] reg_surname;
    logic [31:0] reg_name;

    enum logic [1:0] { APB_SETUP, APB_W_ENABLE, APB_R_ENABLE } apb_st;

    always @(posedge pclk) begin
        if (!presetn) begin
            prdata <= '0;
            pslverr <= 1'b0;
            pready <= 1'b0;
            register_with_some_name <= 32'h0;
            reg_number <= 32'h0;
            reg_date <= 32'h0;
            reg_surname <= 32'h0;
            reg_name <= 32'h0;
            apb_st <= APB_SETUP;
        end else begin
            case (apb_st)
                APB_SETUP: begin
                    prdata <= '0;
                    pslverr <= 1'b0;
                    pready <= 1'b0;
                    if (psel && !penable) begin
                        if (pwrite) apb_st <= APB_W_ENABLE;
                        else        apb_st <= APB_R_ENABLE;
                    end
                end

                APB_W_ENABLE: begin
                    if (psel && penable && pwrite) begin
                        pready <= 1'b1;
                        case (paddr[7:0])
                            8'h0: begin
                                if (pwdata[0] == 1'b0) register_with_some_name <= 32'hAAAA_AAAA;
                                else                   register_with_some_name <= 32'h5555_5555;
                                reg_number <= pwdata;
                            end
                            8'h4: reg_date <= pwdata;
                            8'h8: reg_surname <= pwdata;
                            8'hC: reg_name <= pwdata;
                            default: pslverr <= 1'b1;
                        endcase
                        apb_st <= APB_SETUP;
                    end
                end

                APB_R_ENABLE: begin
                    if (psel && penable && !pwrite) begin
                        pready <= 1'b1;
                        case (paddr[7:0])
                            8'h0: prdata <= register_with_some_name;
                            8'h4: prdata <= reg_date;
                            8'h8: prdata <= reg_surname;
                            8'hC: prdata <= reg_name;
                            default: pslverr <= 1'b1;
                        endcase
                        apb_st <= APB_SETUP;
                    end
                end
                default: pslverr <= 1'b1;
            endcase
        end
    end
endmodule
