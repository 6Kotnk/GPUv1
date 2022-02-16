`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Top level
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"

module dims_rtx
(
    input           					GCLK,
    input   	    					BTNC,
		
    input   [`LOC_WIDTH - 1:0]  		L_LOC_X,
    input   [`LOC_WIDTH - 1:0]  		L_LOC_Y,
    input   [`LOC_WIDTH - 1:0]  		L_LOC_Z,
    input   	  						L_LOC_vld,
	
    output          					VGA_HS,
    output          					VGA_VS,
    output  [`VGA_COLOR_DEPTH-1 : 0]   	VGA_R,
    output  [`VGA_COLOR_DEPTH-1 : 0]   	VGA_G,
    output  [`VGA_COLOR_DEPTH-1 : 0]   	VGA_B
);
    
    logic [`LOC_WIDTH - 1:0] l_loc_x_sync = 0;
    logic [`LOC_WIDTH - 1:0] l_loc_y_sync = 0;
    logic [`LOC_WIDTH - 1:0] l_loc_z_sync = 0;
    
	logic rst = 0;
	
	//Sync light position to framerate (each frame has consistent light position)
	always @ (posedge GCLK) 
    begin
        if(rst)
        begin
            l_loc_x_sync <= 0;
            l_loc_y_sync <= 0;
            l_loc_z_sync <= 0;
        end
        else if (L_LOC_vld)
        begin
            l_loc_x_sync <= L_LOC_X;
            l_loc_y_sync <= L_LOC_Y;
            l_loc_z_sync <= L_LOC_Z;
        end
    end
	
    //Sync reset
    always @ (posedge GCLK) 
    begin
        if(BTNC)
        begin
            rst <= 1;
        end
        else
        begin
        	rst <= 0;
        end
    end
    
	fb_if 				rtx_fb();
	fb_if 				fb_drv();
	vga_if 				drv_vga();
	
	
	
	
	assign VGA_HS = drv_vga.hsync;
	assign VGA_VS = drv_vga.vsync;
	
	
	assign VGA_R = drv_vga.display ? drv_vga.r : 0;
	assign VGA_G = drv_vga.display ? drv_vga.g : 0;
	assign VGA_B = drv_vga.display ? drv_vga.b : 0;
	
	ray_tracer
    rtx_inst
    (
        .clk		(GCLK),
        .rst		(rst),
        
        .l_loc_x_i	(l_loc_x_sync),
        .l_loc_y_i	(l_loc_y_sync),
        .l_loc_z_i	(l_loc_z_sync),

		.fb_o		(rtx_fb)

    );
	
	
	framebuffer
    fb_inst
    (
        .clk		(GCLK),
        .rst		(rst),
		
		.fb_i		(rtx_fb),
		.fb_o		(fb_drv)

    );
	
	vga_driver
    drv_inst
    (
        .clk		(GCLK),
        .rst		(rst),
		
		.fb_i		(fb_drv),
		.vga_o		(drv_vga)

    );
	
	
	

endmodule