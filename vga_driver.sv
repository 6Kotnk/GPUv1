`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA display driver
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"

module vga_driver
(
	input               					clk,				//Clock input
	input               					rst,				//Global reset
	
	fb_if									fb_i,				//Framebuffer input
	vga_if									vga_o				//VGA output
);
    
	logic vga_cnt_en;
	logic h_done;
	logic v_done;
	
	logic h_display;
	logic h_display_done;
	logic v_display;
	logic display;

	assign vga_o.display = h_display && v_display;
	assign fb_i.vld = vga_cnt_en;
	
	// VGA has 50MHz pixel clock
	clk_div#
	(
		.DIV		         		(`SRC_CLK/`VGA_CLK)
	)
	vga_clk_div
	(
		.clk    					(clk),
		.rst        				(rst),
		
		
		.clk_div_o      			(vga_cnt_en)
		
	);



	// X coord driver (rows)
	sync_cnt#
	(
		.DISLAY_LEN          		(`X_WIDTH),

		.PORCH_POL	        		(`X_POL),

		.FRONT_PORCH				(`X_FRONT_PORCH),
		.SYNC_PULSE 				(`X_SYNC_PULSE),
		.BACK_PORCH 				(`X_BACK_PORCH)
	)
	H_SYNC
	(
		.clk    					(clk),
		.rst        				(rst),
		
		
		.inc_i      				(vga_cnt_en),
		.sync_o     				(vga_o.hsync),
		.display_o  				(h_display),
		.disp_done_o  				(h_display_done),
		.pos_o      				(fb_i.x_coord),
		.done_o      				(h_done)
		
	);



	// Y coord driver
	sync_cnt#
	(
		.DISLAY_LEN          		(`Y_WIDTH),

		.PORCH_POL	        		(`Y_POL),

		.FRONT_PORCH				(`Y_FRONT_PORCH),
		.SYNC_PULSE 				(`Y_SYNC_PULSE),
		.BACK_PORCH 				(`Y_BACK_PORCH)
	)
	V_SYNC
	(
		.clk    					(clk),
		.rst        				(rst),
		
		.inc_i      				(h_done),
		.sync_o     				(vga_o.vsync),
		.display_o  				(v_display),
		.pos_o      				(),
		.done_o      				(v_done)
		
	);
		
		
	assign fb_i.row_done = h_display_done && v_display;
	assign fb_i.frame_done = v_done;
	
	assign vga_o.r = fb_i.val[`R_RANGE_VGA];
	assign vga_o.g = fb_i.val[`G_RANGE_VGA];
	assign vga_o.b = fb_i.val[`B_RANGE_VGA];
	
    
    endmodule
