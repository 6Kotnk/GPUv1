`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench
//////////////////////////////////////////////////////////////////////////////////


module rtx_tb;
  
logic clk;
logic vga_clk;
logic reset;

logic hsync;
logic vsync;

logic [`VGA_COLOR_DEPTH-1 : 0] 	vga_r;
logic [`VGA_COLOR_DEPTH-1 : 0] 	vga_g;
logic [`VGA_COLOR_DEPTH-1 : 0] 	vga_b;

logic [`LOC_WIDTH - 1:0]  		Lx = 0;
logic [`LOC_WIDTH - 1:0]  		Ly = 0;
logic [`LOC_WIDTH - 1:0]  		Lz = 0;
logic 		 					Lv = 0;
  
localparam DBG_LEN = 64;
  
string dbg_str;
reg [DBG_LEN*8-1 : 0] dbg;
  
initial
begin
    clk = 1'b0;
    forever #5 clk = ~clk; // generate a clock 100 MHz
end
  
initial
begin
    vga_clk = 1'b0;
    forever #10 vga_clk = ~vga_clk; // generate a clock 50 MHz
end
  
task rst;
	begin
		reset = 1'b1;
		repeat(10)@(clk);
		reset = 1'b0;
	end
endtask


integer i,j,f;




initial
begin 
	// file located at $proj$\$proj$.sim\sim_1\behav\xsim
	f = $fopen("output1.ppm","w");
	
	//Create ppm file, read with http://paulcuth.me.uk/netpbm-viewer/
	$fwrite(f, "P3\n%d%d\n16\n", `X_WIDTH, `Y_WIDTH );
	dbg_str = "RESET";
	rst();
	Lx <= `QCBRT_2;
	Ly <= `QCBRT_2;
	Lz <= `QCBRT_2;
	Lv <= 1;
	
	//Save displayed frame
	dbg_str = "BEGIN DISPLAY";
    for (i = 0; i<`Y_WIDTH; i=i+1) 
	begin
		dbg_str={$sformatf("ROW %0d",i)};
		for (j = 0; j<`X_WIDTH; j=j+1) 
		begin
			@(posedge vga_clk);
			$fwrite(f,"%d %d %d ", vga_r,vga_g,vga_b);
		end
		@(negedge hsync);
		repeat(`X_BACK_PORCH)@(posedge vga_clk);
	end
    $fclose(f);
	

	$finish;
end

  dims_rtx DUT
       (
	    .GCLK(clk),
	    .BTNC(reset),
		
		.L_LOC_X(Lx),
		.L_LOC_Y(Ly),
		.L_LOC_Z(Lz),
		.L_LOC_vld(Lv),
		
        .VGA_B(vga_b),
        .VGA_G(vga_g),
        .VGA_HS(hsync),
        .VGA_R(vga_r),
        .VGA_VS(vsync)
		);

//Convert string to reg, view dbg with radix ASCII to view debug info
always @ (dbg_str)
begin
	for(int idx = 0; idx < DBG_LEN; idx++)
		dbg[(DBG_LEN-1-idx)*8 +: 8] <= idx < dbg_str.len() ? dbg_str.getc(idx) : 0;
end

endmodule