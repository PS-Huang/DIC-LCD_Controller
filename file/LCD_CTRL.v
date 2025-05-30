module LCD_CTRL(
    input clk,
    input rst,
    input [3:0] cmd,
    input cmd_valid,
    output reg IROM_rd,
    output reg [5:0] IROM_A,
    input [7:0] IROM_Q,
    output reg IRAM_ceb,      // chip enable signal, indicates the IRAM is available for R/W
    output reg [5:0] IRAM_A,
    output reg [7:0] IRAM_D,
    output reg IRAM_web,      // R/W select signal, 0 -> write; 1 -> read
    input [7:0] IRAM_Q,
    output reg busy,
    output reg done
);

    // Finite State Machine States
    parameter IDLE = 3'd0;
    parameter LOAD_IMAGE = 3'd1;
    parameter PROCESSING = 3'd2;
    parameter WRITE_IMAGE = 3'd3;
    parameter DONE = 3'd4;

    reg [2:0] state, next_state;

    // Image buffer (8x8 image) and Point coordinates
    reg [7:0] image [0:7][0:7];
    reg [2:0] op_x, op_y;

    // Load and Write counter
    reg [6:0] load_cnt;
    reg [6:0] write_cnt;

    // Processing state 會使用到的變數
    integer i, j;
    reg [7:0] temp_value;
    reg [15:0] sum;

    // Sequential logic -> control processing state
    always @(posedge clk or posedge rst) begin
        state <= IDLE;
        next_state <= IDLE;
        // testbench 一開始設 rst 為 high，因此會先進來 LOAD_IMAGE
        if (rst) begin
            state <= LOAD_IMAGE;
            op_x <= 3'd4;
            op_y <= 3'd4;
            load_cnt <= 7'd0;
            write_cnt <= 7'd0;
            busy <= 1'b1;
            done <= 1'b0;
            IROM_A <= 6'd0;
        end else begin
            state <= next_state;

            if (state == LOAD_IMAGE && IROM_rd) begin
                image[load_cnt / 8][load_cnt % 8] <= IROM_Q;
                load_cnt <= load_cnt + 1;
                IROM_A <= load_cnt + 1;
            end

            if (state == PROCESSING)  begin
                case (cmd)
                    /* 因為要到 WRITE_IMAGE state 才會使用到 write_cnt
                     * 所以在 Processing state 就做初始化就好 主要是為了把條件寫滿
                     */ 
					4'd0: write_cnt <= 0;
                    // Shift Up
                    4'd1: if (op_y > 3'd2) op_y <= op_y - 1;
                    // Shift Down
                    4'd2: if (op_y < 3'd6) op_y <= op_y + 1;
                    // Shift Left
                    4'd3: if (op_x > 3'd2) op_x <= op_x - 1;
                    // Shift Right
                    4'd4: if (op_x < 3'd6) op_x <= op_x + 1;
                    // Max
                    4'd5: begin 
                        temp_value = image[op_y][op_x]; // 一開始隨意設4*4矩陣內的某個值
                        for (i = op_y-2; i <= op_y+1; i = i + 1)
                            for (j = op_x-2; j <= op_x+1; j = j + 1)
                                if (image[i][j] > temp_value)
                                    temp_value = image[i][j];
                        for (i = op_y-2; i <= op_y+1; i = i + 1)
                            for (j = op_x-2; j <= op_x+1; j = j + 1)
                                image[i][j] <= temp_value;
                    end
                    // Min
                    4'd6: begin 
                        temp_value = image[op_y][op_x];
                        for (i = op_y-2; i <= op_y+1; i = i + 1)
                            for (j = op_x-2; j <= op_x+1; j = j + 1)
                                if (image[i][j] < temp_value)
                                    temp_value = image[i][j];
                        for (i = op_y-2; i <= op_y+1; i = i + 1)
                            for (j = op_x-2; j <= op_x+1; j = j + 1)
                                image[i][j] <= temp_value;
                    end
                    // Average
                    4'd7: begin 
                        sum = 16'd0;
                        for (i = op_y-2; i <= op_y+1; i = i + 1)
                            for (j = op_x-2; j <= op_x+1; j = j + 1)
                                sum = sum + image[i][j];
                        temp_value = sum >> 4;
                        for (i = op_y-2; i <= op_y+1; i = i + 1)
                            for (j = op_x-2; j <= op_x+1; j = j + 1)
                                image[i][j] <= temp_value;
                    end
                    default: ;
                endcase
            end

            if (state == WRITE_IMAGE) begin
                IRAM_A <= write_cnt;
                IRAM_D <= image[write_cnt / 8][write_cnt % 8];
                IRAM_web <= 0; 
                IRAM_ceb <= 1; 
                write_cnt <= write_cnt + 1;
            end
        end
    end

    // Combinational logic -> control FSM
    always @(*) begin
        // Default values to prevent latches
        IROM_rd = 1'b0;
        IRAM_ceb = 1'b0;
        IRAM_web = 1'b1;
        busy = 1'b1;
        done = 1'b0;
        next_state = state;

        case (state)
            IDLE: begin
                busy = 1'b0;
                if (cmd_valid) begin
                    if (cmd == 4'd0)
                        next_state = WRITE_IMAGE;
                    else
                        next_state = PROCESSING; 
                end
            end

            LOAD_IMAGE: begin
                IROM_rd = 1'b1;
                next_state = (load_cnt == 7'd64) ? IDLE : LOAD_IMAGE;
            end

            PROCESSING:  begin
                next_state = IDLE; 
            end

            WRITE_IMAGE: begin
                IRAM_web = 0;
                IRAM_ceb = 1;
                next_state = (write_cnt == 7'd64) ? DONE : WRITE_IMAGE;
            end

            DONE: begin
                done = 1'b1;
                next_state = IDLE;
            end

            default: ; 
        endcase
    end

endmodule
