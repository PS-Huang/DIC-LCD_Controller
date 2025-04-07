`timescale 1ns/10ps
`define CYCLE    10.0         	        
`include "./mem/IROM.sv"
`include "./mem/IRAM.sv"
`define tb1		// Modify to test different pattern

`ifdef tb1
  `define EXPECT "./dat/tb1_goal.dat"
  `define CMD "./dat/cmd1.dat"
`endif

`ifdef tb2
  `define EXPECT "./dat/tb2_goal.dat"
  `define CMD "./dat/cmd2.dat"
`endif

`ifdef tb3
  `define EXPECT "./dat/tb3_goal.dat"
  `define CMD "./dat/cmd3.dat"
`endif

`ifdef tb4
  `define EXPECT "./dat/tb4_goal.dat"
  `define CMD "./dat/cmd4.dat"
`endif

`ifdef tb5
  `define EXPECT "./dat/tb5_goal.dat"
  `define CMD "./dat/cmd5.dat"
`endif


module testfixture;
parameter IMAGE_N_PAT = 64;
parameter CMD_N_PAT = 46;
parameter t_reset = `CYCLE*2;


logic clk;
logic rst;
logic [6:0] err_IRAM;
logic [3:0] cmd;
logic cmd_valid;
logic [7:0]  out_mem[0:63];


logic IROM_rd;
logic [5:0] IROM_A;
logic IRAM_ceb;
logic IRAM_web;
logic [7:0] IRAM_D;
logic [5:0] IRAM_A;
logic [7:0] IRAM_Q;
logic busy;
logic done;
logic [7:0]  IROM_Q;


integer i, j, k, l, err;

logic over;
logic  [3:0]   cmd_mem   [0:CMD_N_PAT-1];



LCD_CTRL LCD_CTRL(
	.clk		(clk	   ), 
	.rst		(rst	   ), 
	.cmd		(cmd	   ), 
	.cmd_valid	(cmd_valid ), 
	.IROM_rd	(IROM_rd   ), 
	.IROM_A		(IROM_A    ), 
	.IROM_Q		(IROM_Q    ), 
	.IRAM_ceb	(IRAM_ceb  ), 
	.IRAM_web   (IRAM_web  ),
	.IRAM_D		(IRAM_D    ), 
	.IRAM_A		(IRAM_A    ),
	.IRAM_Q		(IRAM_Q	   ),
	.busy		(busy      ), 
	.done		(done      )
);

IROM #(8, 64) IROM_1(
	.clk		(clk	), 
	.rst		(rst	),
	.IROM_rd	(IROM_rd), 
	.IROM_data	(IROM_Q ), 
	.IROM_addr	(IROM_A )
);

IRAM #(8, 64) IRAM_1(
	.clk		(clk 		),
	.IRAM_D		(IRAM_D		), 
	.IRAM_A		(IRAM_A	    ), 
	.IRAM_ceb	(IRAM_ceb   ),
	.IRAM_web	(IRAM_web   ),
	.IRAM_Q		(IRAM_Q		)
);


initial	$readmemh (`CMD,    cmd_mem);
initial	$readmemh (`EXPECT, out_mem);

initial begin
   clk         = 1'b0;
   over	       = 1'b0;
   l	       = 0;
   err         = 0;   
end

always begin #(`CYCLE/2) clk <= ~clk; end

initial begin
   rst = 1'b1;
   #t_reset        rst = 1'b0;                   
end  

            
always @(negedge clk) begin
	if (l < CMD_N_PAT) begin
		if(!busy && !rst) begin
        	cmd <= cmd_mem[l];
        	cmd_valid <= 1'b1;
			l<=l+1;
		end  
		else
		 	cmd_valid <= 1'b0;
	end
	else begin
		l<=l;
		cmd_valid <= 1'b0;
	end
end


initial @(posedge done) begin
   	for(k=0;k<64;k=k+1)begin
		if( IRAM_1.IRAM_M[k] !== out_mem[k]) 
		begin
         	$display("ERROR at %d:output %h !=expect %h ",k, IRAM_1.IRAM_M[k], out_mem[k]);
         	err = err+1 ;
		end
        else 
		if ( out_mem[k] === 8'dx) begin
            $display("ERROR at %d:output %h !=expect %h ",k, IRAM_1.IRAM_M[k], out_mem[k]);
			err = err+1;
        end

 		over=1'b1;
	end
	if (err === 0 &&  over===1'b1) begin
		$display("All data have been generated successfully!\n");
		$display("                   //////////////////////////               ");
		$display("                   /                        /       |\__||  ");
		$display("                   /  Congratulations !!    /      / O.O  | ");
		$display("                   /                        /    /_____   | ");
		$display("                   /  Simulation PASS !!    /   /^ ^ ^ \\  |");
		$display("                   /                        /  |^ ^ ^ ^ |w| ");
		$display("                   //////////////////////////   \\m___m__|_|");
		$display("\n");
				
		#10 $finish;
	end
	else if( over===1'b1) begin 
		$display("There are %d errors!\n", err);
		$display("                   //////////////////////////               ");
		$display("                   /                        /       |\__||  ");
		$display("                   /  OOPS !!               /      / X.X  | ");
		$display("                   /                        /    /_____   | ");
		$display("                   /  Simulation Failed !!  /   /^ ^ ^ \\  |");
		$display("                   /                        /  |^ ^ ^ ^ |w| ");
		$display("                   //////////////////////////   \\m___m__|_|");
		$display("\n");
		#10 $finish;
	end
end

endmodule

