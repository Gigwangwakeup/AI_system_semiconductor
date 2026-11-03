`timescale 1ns / 1ps

module rv32i_top (
    input logic clk,
    input logic rst,
    input logic [15:0] sw,
    output logic [15:0] led
);

    logic rst_n;
    assign rst_n = ~rst;


    logic [7:0] wGPIO_IN;
    logic [7:0] wGPIO_OUT;

    assign wGPIO_IN = sw[15:8];
    assign led[15:8] = wGPIO_OUT;

    logic [31:0] wInstrCode;
    logic [31:0] wInstrAddr;
    logic [31:0] wBusAddr;
    logic [31:0] wBusWData;
    logic [31:0] wBusRData;
    logic [ 2:0] wIType;
    logic        wBusWe;
    logic        wReady;
    logic        wTransfer;

    logic        wPReady0;
    logic        wPReady1;
    logic        wPReady2;
    logic        wPReady3;
    logic        wPReady4;
    logic        wPReady5;
    logic        wPReady6;
    logic [31:0] wPRData0;
    logic [31:0] wPRData1;
    logic [31:0] wPRData2;
    logic [31:0] wPRData3;
    logic [31:0] wPRData4;
    logic [31:0] wPRData5;
    logic [31:0] wPRData6;
    logic [31:0] wPAddr;
    logic [31:0] wPWData;
    logic        wPWrite;
    logic        wPEnable;
    logic        wPSel0;
    logic        wPSel1;
    logic        wPSel2;
    logic        wPSel3;
    logic        wPSel4;
    logic        wPSel5;
    logic        wPSel6;

    instruction_rom u_instruction_rom (
        .instr_addr(wInstrAddr),
        .instr_code(wInstrCode)
    );

    rv32i_cpu u_rv32i_cpu (
        .clk       (clk),
        .rst_n     (rst_n),
        .instr_code(wInstrCode),
        .bus_rdata (wBusRData),
        .ready     (wReady),
        .instr_addr(wInstrAddr),
        .itype     (wIType),
        .bus_we    (wBusWe),
        .transfer  (wTransfer),
        .bus_addr  (wBusAddr),
        .bus_wdata (wBusWData)
    );

    apb_requester u_apb_requester (
        .clk      (clk),
        .rst_n    (rst_n),
        .bus_addr (wBusAddr),
        .bus_wdata(wBusWData),
        .transfer (wTransfer),
        .bus_we   (wBusWe),
        .ready    (wReady),
        .bus_rdata(wBusRData),
        .PREADY0  (wPReady0),
        .PREADY1  (wPReady1),
        .PREADY2  (wPReady2),
        .PREADY3  (wPReady3),
        .PREADY4  (wPReady4),
        .PREADY5  (wPReady5),
        .PREADY6  (wPReady6),
        .PRDATA0  (wPRData0),
        .PRDATA1  (wPRData1),
        .PRDATA2  (wPRData2),
        .PRDATA3  (wPRData3),
        .PRDATA4  (wPRData4),
        .PRDATA5  (wPRData5),
        .PRDATA6  (wPRData6),
        .PADDR    (wPAddr),
        .PWDATA   (wPWData),
        .PWRITE   (wPWrite),
        .PENABLE  (wPEnable),
        .PSEL0    (wPSel0),
        .PSEL1    (wPSel1),
        .PSEL2    (wPSel2),
        .PSEL3    (wPSel3),
        .PSEL4    (wPSel4),
        .PSEL5    (wPSel5),
        .PSEL6    (wPSel6)
    );

    // [FIX-8] 슬레이브가 없는 슬롯(PSEL4~6, FND/UART 예약)은 기본 응답으로 묶음
    //         이전에는 PREADY4~6이 구동되지 않아(값 X/0) 0x2000_03xx~05xx 접근 시 CPU가 멈췄음
    //         나중에 FND, UART를 붙이면 해당 줄을 실제 슬레이브 출력으로 바꾸면 됨
    assign wPReady4 = wPSel4 & wPEnable;
    assign wPReady5 = wPSel5 & wPEnable;
    assign wPReady6 = wPSel6 & wPEnable;
    assign wPRData4 = 32'h0000_0000;
    assign wPRData5 = 32'h0000_0000;
    assign wPRData6 = 32'h0000_0000;

    apb_ram u_apb_ram (
        .clk    (clk),
        .itype  (wIType),
        .PSEL   (wPSel0),
        .PENABLE(wPEnable),
        .PADDR  (wPAddr),
        .PWDATA (wPWData),
        .PWRITE (wPWrite),
        .PREADY (wPReady0),
        .PRDATA (wPRData0)
    );

    apb_gpi u_apb_gpi (
        .clk(clk),
        .rst_n(rst_n),
        .PSEL(wPSel1),
        .PWRITE(wPWrite),
        .GPI_IN(sw[7:0]),
        .PREADY(wPReady1),
        .PRDATA(wPRData1),
        .PWDATA(wPWData),
        .PADDR(wPAddr),
        .PENABLE(wPEnable)
    );

    apb_gpo u_apb_gpo (
        .clk(clk),
        .rst_n(rst_n),
        .PSEL(wPSel2),
        .PENABLE(wPEnable),
        .PADDR(wPAddr),
        .PWDATA(wPWData),
        .PWRITE(wPWrite),
        .GPO_OUT(led[7:0]),
        .PREADY(wPReady2),
        .PRDATA(wPRData2)
    );

    apb_gpio u_apb_gpio (
        .clk(clk),
        .rst_n(rst_n),
        .PSEL(wPSel3),
        .PENABLE(wPEnable),
        .PADDR(wPAddr),
        .PWDATA(wPWData),
        .PWRITE(wPWrite),
        .GPIO_IN(wGPIO_IN),
        .GPIO_OUT(wGPIO_OUT),
        .PREADY(wPReady3),
        .PRDATA(wPRData3)
    );

endmodule

module rv32i_cpu
    import rv32_pkg::*;
(
    input logic clk,
    input logic rst_n,

    // Instruction interface
    input  logic [31:0] instr_code,
    output logic [31:0] instr_addr,

    // Bus interface
    input  logic [31:0] bus_rdata,
    input  logic        ready,
    output logic [ 2:0] itype,
    output logic        bus_we,
    output logic        transfer,
    output logic [31:0] bus_addr,
    output logic [31:0] bus_wdata
);
    logic              wPcEn;
    logic              wRfWe;
    logic              wBranch;
    logic              wJal;
    logic              wJalr;
    logic              wAluSrcSel;
    logic              wExMemEn;     // [FIX-7]
    alu_control_e      wAluCtrl;
    writeback_select_e wWbSel;

    control_unit u_control_unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .ready      (ready),
        .instr_code (instr_code),
        .pc_en      (wPcEn),
        .branch     (wBranch),
        .jal        (wJal),
        .jalr       (wJalr),
        .rf_we      (wRfWe),
        .alusrc_sel (wAluSrcSel),
        .exmem_en   (wExMemEn),
        .alu_control(wAluCtrl),
        .rf_srcsel  (wWbSel),
        .bus_we     (bus_we),
        .transfer   (transfer),
        .itype      (itype)
    );

    datapath u_datapath (
        .clk        (clk),
        .rst_n      (rst_n),
        .pc_en      (wPcEn),
        .rf_we      (wRfWe),
        .alusrc_sel (wAluSrcSel),
        .branch     (wBranch),
        .jal        (wJal),
        .jalr       (wJalr),
        .exmem_en   (wExMemEn),
        .alu_control(wAluCtrl),
        .rf_srcsel  (wWbSel),
        .instr_code (instr_code),
        .bus_rdata  (bus_rdata),
        .instr_addr (instr_addr),
        .bus_addr   (bus_addr),
        .bus_wdata  (bus_wdata)
    );
endmodule
