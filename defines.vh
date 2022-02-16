//////////////////////////////////////////////////////////////////////////////////
// Defines
//////////////////////////////////////////////////////////////////////////////////

`ifndef HEADER_H
`define HEADER_H

`define SRC_CLK 100_000_000 
`define VGA_CLK 50_000_000 

`define X_WIDTH 800

`define X_POL 1

`define X_FRONT_PORCH 56
`define X_SYNC_PULSE 128
`define X_BACK_PORCH 64



`define Y_WIDTH 600

`define Y_POL 1

`define Y_FRONT_PORCH 37
`define Y_SYNC_PULSE 6
`define Y_BACK_PORCH 23


`define R_RANGE_VGA 7:4
`define G_RANGE_VGA 15:12
`define B_RANGE_VGA 23:20

`define R_RANGE_DIT 3:0
`define G_RANGE_DIT 11:8
`define B_RANGE_DIT 19:16

`define R_RANGE_FB 7:0
`define G_RANGE_FB 15:8
`define B_RANGE_FB 23:16



`define VGA_COLOR_DEPTH 4
`define FB_COLOR_DEPTH 24
`define FB_SINGLE_COLOR_DEPTH 8

`define VEC_WIDTH 24

`define FB_DEPTH 2

`define X_COORD_WIDTH $clog2(`X_WIDTH)
`define Y_COORD_WIDTH $clog2(`Y_WIDTH)

`define FB_ADDR_WIDTH $clog2(`X_WIDTH)

`define LOC_WIDTH 32

`define QCBRT_2 82570

`define FP_FRACT 16
`define QONE 1 << `FP_FRACT


`define MULT_WIDTH_OUT 48
`define MULT_WIDTH_IN 18

`define SQRT_WIDTH `MULT_WIDTH_OUT/2


interface vga_if ;

	logic		[`VGA_COLOR_DEPTH-1 : 0]			r;
	logic		[`VGA_COLOR_DEPTH-1 : 0]			g;
	logic		[`VGA_COLOR_DEPTH-1 : 0]			b;
	
	logic											vsync;
	logic											hsync;
	
	logic											display;
	
endinterface

interface fb_if ;

    logic    							 			vld;
    logic    							 			row_done;
    logic    							 			frame_done;
    logic    	[`X_COORD_WIDTH - 1 : 0]			x_coord;
	
    logic    	[`FB_COLOR_DEPTH - 1 : 0] 			val;
	
endinterface

typedef struct {
	logic signed	[`VEC_WIDTH - 1 : 0]			x;
	logic signed	[`VEC_WIDTH - 1 : 0]			z;
	logic signed	[`VEC_WIDTH - 1 : 0]			y;
}vec3;

`endif // HEADER_H