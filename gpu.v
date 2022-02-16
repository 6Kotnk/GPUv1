`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Top level wrapper
//////////////////////////////////////////////////////////////////////////////////
//`include "defines.vh"

module gpu
(
    input           					clk,
    input           					rst,
	
    input   [`L_LOC_WIDTH - 1:0]  		L_LOC_X,
    input   [`L_LOC_WIDTH - 1:0]  		L_LOC_Y,
    input   [`L_LOC_WIDTH - 1:0]  		L_LOC_Z,
    input   	  						L_LOC_vld,
	
    output          					VGA_HS,
    output          					VGA_VS,
    output  [`VGA_COLOR_DEPTH-1 : 0]   	VGA_R,
    output  [`VGA_COLOR_DEPTH-1 : 0]   	VGA_G,
    output  [`VGA_COLOR_DEPTH-1 : 0]   	VGA_B
);

  dims_rtx gpu_i
       (
	    .GCLK(clk),
	    .BTNC(!rst),
		
		.L_LOC_X(L_LOC_X),
		.L_LOC_Y(L_LOC_Y),
		.L_LOC_Z(L_LOC_Z),
		.L_LOC_vld(L_LOC_vld),
		
        .VGA_B(VGA_B),
        .VGA_G(VGA_G),
        .VGA_HS(VGA_HS),
        .VGA_R(VGA_R),
        .VGA_VS(VGA_VS)
		);



endmodule