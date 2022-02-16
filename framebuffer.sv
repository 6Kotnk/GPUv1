`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Display framebuffer - synchronizes writing and reading using two lines of memory
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"

module framebuffer
(
	input               					clk,				//Clock input
	input               					rst,				//Global reset
	
	fb_if									fb_i,				//Framebuffer input
	fb_if									fb_o				//Framebuffer output
);
	
	//Passthrough
	assign fb_i.frame_done = fb_o.frame_done;
	assign fb_i.row_done = fb_o.row_done;
	
	// 1 = A in, 	B out
	// 0 = B out, 	A in
	
	//Keeps track of which BRAM is used for writing and which for reading
	logic switch;
	

	//MUX to switch lines
	logic [`FB_ADDR_WIDTH-1 : 0] wr_addr;
	assign wr_addr = fb_i.x_coord;
	
	logic [`FB_ADDR_WIDTH-1 : 0] rd_addr;
    assign rd_addr = fb_o.x_coord;
    
	logic [`FB_ADDR_WIDTH-1 : 0] a_addr;
	logic [`FB_ADDR_WIDTH-1 : 0] b_addr;
	
	logic [`FB_ADDR_WIDTH-1 : 0] a_addr_dit;
	logic [`FB_ADDR_WIDTH-1 : 0] b_addr_dit;
	
	logic [`FB_COLOR_DEPTH-1 : 0] a_dina;
	logic [`FB_COLOR_DEPTH-1 : 0] b_dina;
	
	logic [`FB_COLOR_DEPTH-1 : 0] a_dina_dit;
	logic [`FB_COLOR_DEPTH-1 : 0] b_dina_dit;
	
	logic [`FB_COLOR_DEPTH-1 : 0] a_douta;
	logic [`FB_COLOR_DEPTH-1 : 0] b_douta;
	
	logic [`FB_COLOR_DEPTH-1 : 0] a_douta_dit;
	logic [`FB_COLOR_DEPTH-1 : 0] b_douta_dit;
	
	logic 						  a_wea;
	logic 						  b_wea;
	
	assign a_addr = switch ? wr_addr : rd_addr;
	assign b_addr = switch ? rd_addr : wr_addr;
	
	assign a_addr_dit = switch ? rd_addr : rd_addr + 1;
	assign b_addr_dit = switch ? rd_addr + 1 : rd_addr;
	
	assign a_dina = switch ? fb_i.val : 0;
	
	assign b_dina = switch ? 0 : fb_i.val;

	assign a_wea = switch ? fb_i.vld : 0;
	assign b_wea = switch ? 0 : fb_i.vld;
	
	assign fb_o.val = switch ? b_douta : a_douta;

	
	//Dithering
	/*
	4-bit VGA gives us only 16 color intesities in order to avoid color banding we use error difusion dithering
	https://en.wikipedia.org/wiki/Error_diffusion
	In essence we store an 8 bit color value, but only display 4 bits. The difference (when rounding) gets
	added to the neighbouring pixels
	
	Used kernel: # -> current pixel 
	
	[ #   0.5 ]
	[         ]
	[ 0.5   0 ]
	
	*/
	assign a_dina_dit[`R_RANGE_FB] = (fb_o.val[`R_RANGE_DIT] >> 1) + a_douta_dit[`R_RANGE_FB];
	assign a_dina_dit[`G_RANGE_FB] = (fb_o.val[`G_RANGE_DIT] >> 1) + a_douta_dit[`G_RANGE_FB];
	assign a_dina_dit[`B_RANGE_FB] = (fb_o.val[`B_RANGE_DIT] >> 1) + a_douta_dit[`B_RANGE_FB];

	assign b_dina_dit[`R_RANGE_FB] = (fb_o.val[`R_RANGE_DIT] >> 1) + b_douta_dit[`R_RANGE_FB];
	assign b_dina_dit[`G_RANGE_FB] = (fb_o.val[`G_RANGE_DIT] >> 1) + b_douta_dit[`G_RANGE_FB];
	assign b_dina_dit[`B_RANGE_FB] = (fb_o.val[`B_RANGE_DIT] >> 1) + b_douta_dit[`B_RANGE_FB];
	
	
	
	//Switch lines when a row is done being displayed
	always @ (posedge clk)
	begin
		if(rst)
        begin
            switch <= 0;
        end
        else
		begin
			if(fb_i.row_done)
			begin
				switch <= !switch;
			end
		end
	end
	
	
	
	//Two rows (lines) of pixels 800*24bits (8bits per color)
	framebuffer_mem fb_a
	(
	//RW port
		.clka    					(clk),
		.wea        				(a_wea),
		.addra        				(a_addr),
		.dina        				(a_dina),
		.douta        				(a_douta),
		
	//Dither port
		.clkb    					(clk),
		.web        				(fb_o.vld),
		.addrb        				(a_addr_dit),
		.dinb        				(a_dina_dit),
		.doutb        				(a_douta_dit)
		
		
	);
    
	framebuffer_mem fb_b
	(
	//RW port
		.clka    					(clk),
		.wea        				(b_wea),
		.addra        				(b_addr),
		.dina        				(b_dina),
		.douta        				(b_douta),
		
	//Dither port
		.clkb    					(clk),
		.web        				(fb_o.vld),
		.addrb        				(b_addr_dit),
		.dinb        				(b_dina_dit),
		.doutb        				(b_douta_dit)
		
		
		
	);
	
    endmodule
