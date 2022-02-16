`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Ray tracer
//////////////////////////////////////////////////////////////////////////////////
`include "defines.vh"

module ray_tracer
(
	input               					clk,				//Clock input
	input               					rst,				//Global reset
	
	input    [`LOC_WIDTH - 1 : 0]			l_loc_x_i,			//Light position x
	input    [`LOC_WIDTH - 1 : 0]			l_loc_y_i,			//Light position y
	input    [`LOC_WIDTH - 1 : 0]			l_loc_z_i,			//Light position z
	fb_if									fb_o				//Framebuffer output
);
    /*
	This is the main part of the GPU.
	
	We use the Phong reflection model to light a sphere.
	https://en.wikipedia.org/wiki/Phong_reflection_model
	
	There are three contriburions:
	Ambient: a minimal amount of light always present (even if not lit by our light source)
	Diffuse: The surface of the object is hit by the light
	Specular: The surface bounces the light into our camera
	
	Ambient is easy to calculate (simply add some light when we are drawing the sphere)
	Diffuse needs the dot product between the light direction and the normal for every point on the object
	Specular needs the dot product between our camera direction and the reflected light ray from the surface (plus an exponent)
	
	We will only use the ambient and diffuse components.
	
	CALCULATIONS:
	Ambient:
	To know when we hit our sphere we simlpy calculate (x^2 + y^2) < 1. We keep the radius at 1 to simplyfy later calculations.

	Diffuse:
	A bit more tricky, we need the normal on our sphere.
	We know that the normal of a sphere of radius 1 is simply its position on the sphere. So we have the x and y components, all we need is z.
	Since we need a normalized normal, the formula for the z component is sqrt(1-X^2-Y^2).
	
	To get the light direction we subtract the normal/position vector from the light position. We dont normalize this vector because in general,
	when the dot product is > 0, its length is almost 1(as long as we keep our light on a constant distance from the sphere) 
	
	Software version:
	
	
	
	*/
	
	
	
	// Two consecutive pipelines
	localparam DOT_PIPELINE_LEN = 17;
	localparam Z_PIPELINE_LEN = 7;
	localparam PIPELINE_LEN = DOT_PIPELINE_LEN + Z_PIPELINE_LEN - 1;
	
	logic run [PIPELINE_LEN-1 : 0];
	
	logic [`X_COORD_WIDTH - 1 : 0] x_coord;
	logic [`Y_COORD_WIDTH - 1 : 0] y_coord;
	
	// Center coords so 0,0 is in the middle of the screen
	logic signed [`X_COORD_WIDTH - 1 : 0] x_coord_center;
	assign x_coord_center = - x_coord + `X_WIDTH/2;
	logic signed [`Y_COORD_WIDTH - 1 : 0] y_coord_center;
	assign y_coord_center = - y_coord + `Y_WIDTH/2;
	

	logic signed [`X_COORD_WIDTH - 1 : 0] x_coord_center_pipe[PIPELINE_LEN-1 : 0];
	logic signed [`Y_COORD_WIDTH - 1 : 0] y_coord_center_pipe[PIPELINE_LEN-1 : 0];
	
	logic [`X_COORD_WIDTH - 1 : 0] x_coord_pipe[PIPELINE_LEN-1 : 0];
	logic [`Y_COORD_WIDTH - 1 : 0] y_coord_pipe[PIPELINE_LEN-1 : 0];
	
	
	assign fb_o.x_coord = x_coord_pipe[PIPELINE_LEN-1];
	
	assign fb_o.vld = run[PIPELINE_LEN-1];
	
	genvar pipe_idx;
	
	//Feed input data into pipeline
	assign x_coord_center_pipe[0] = x_coord_center;
	assign y_coord_center_pipe[0] = y_coord_center;
	
	assign x_coord_pipe[0] = x_coord;
	assign y_coord_pipe[0] = y_coord;
	
	
	//Run pipeline only when data is in the pipeline
	generate
		for(pipe_idx = 1; pipe_idx < PIPELINE_LEN; pipe_idx++)
		begin
			always @ (posedge clk)
			begin
				if(rst)
				begin
					x_coord_center_pipe[pipe_idx] <= 0;
					y_coord_center_pipe[pipe_idx] <= 0;
					x_coord_pipe[pipe_idx] <= 0;
					run[pipe_idx] <= 0;
				end
				else
				begin
					if(run[0] || run[PIPELINE_LEN-1])
					begin
						x_coord_center_pipe[pipe_idx] <= x_coord_center_pipe[pipe_idx-1];
						y_coord_center_pipe[pipe_idx] <= y_coord_center_pipe[pipe_idx-1];
						x_coord_pipe[pipe_idx] <= x_coord_pipe[pipe_idx-1];
						run[pipe_idx] <= run[pipe_idx-1];
					end
				end
			end
		end
	endgenerate
	
	
	
	//Extend coords for multiplier
	logic [`MULT_WIDTH_IN - 1 : 0] x_pin;
	assign x_pin = x_coord_center_pipe[0];
	
	logic [`MULT_WIDTH_IN - 1 : 0] y_pin;
	assign y_pin = y_coord_center_pipe[1];
	
	logic [`MULT_WIDTH_OUT - 1 : 0] 	x2_y2;
	logic [`MULT_WIDTH_OUT - 1 : 0] 	x2;
	logic [`SQRT_WIDTH - 1 : 0]		 	z;
	
	//Determine when we are drawing the sphere
	logic in_sphere;
	logic in_sphere_vld [DOT_PIPELINE_LEN - 1 : 0];
	assign in_sphere = x2_y2 < `QONE;
	
	//Calculate z component of normal vector on sphere
	//A*B+PCIN
	dsp_macro_0 mult_x
	(
		.CLK    					(clk),
		.PCIN        				(0),
		.A        					(x_pin),
		.B        					(x_pin),
		.PCOUT        				(x2),
		.P	        				()
	);
	
	
	dsp_macro_0 mult_y
	(
		.CLK    					(clk),
		.PCIN        				(x2),
		.A        					(y_pin),
		.B        					(y_pin),
		.PCOUT        				(),
		.P	        				(x2_y2)
	);
	

	sqrt sqrt_z
	(
		.aclk    					(clk),
		.s_axis_cartesian_tdata    	((`QONE)-(x2_y2)),
		.s_axis_cartesian_tvalid    (in_sphere),
		
		.m_axis_dout_tvalid    		(in_sphere_vld[0]),
		.m_axis_dout_tdata     		(z)

	);
	
	
	//Second pipeline for dot product between normal and light position
	vec3 p[DOT_PIPELINE_LEN - 1 : 0];
	
	vec3 Lp_async;
	vec3 Lp;
	vec3 L;
	
	logic signed [`MULT_WIDTH_OUT - 1 : 0]	dotNL;
	logic signed [`MULT_WIDTH_OUT - 1 : 0]	dotNLCALC;
	logic signed [`MULT_WIDTH_OUT - 1 : 0]	dotx;
	logic signed [`MULT_WIDTH_OUT - 1 : 0]	doty;
	logic signed [`MULT_WIDTH_OUT - 1 : 0]	dotz;
	logic 		 [`MULT_WIDTH_OUT - 1 : 0]	clampDotNL;
	
	
	//Inputs to second pipeline shifred to 32-bits (light position is 32 bits)
	assign p[0] = '{
	x_coord_center_pipe[Z_PIPELINE_LEN] << (`LOC_WIDTH - `VEC_WIDTH),
	y_coord_center_pipe[Z_PIPELINE_LEN] << (`LOC_WIDTH - `VEC_WIDTH),
	z << (`LOC_WIDTH - `VEC_WIDTH)
	};
	
	
	//Sync Light position to frame
	assign Lp_async = '{l_loc_x_i,l_loc_y_i,l_loc_z_i};
	
	always @ (posedge clk)
	begin
		if(rst)
		begin
			Lp <= '{`QCBRT_2, `QCBRT_2, `QCBRT_2};
		end
		else
		begin
			if(fb_o.frame_done)
			begin
				Lp <= Lp_async;
			end
		end
	end
	
	
	//Calculate dot product
	
	//(A+D)*B+PCIN
	dsp_macro_dot dot_x
	(
		.CLK    					(clk),
		.PCIN        				(0),
		.A        					(-p[0].x),
		.B        					(p[0].x),
		.D        					(Lp.x),
		.PCOUT        				(dotx),
		.P	        				()
	);
	
	dsp_macro_dot dot_y
	(
		.CLK    					(clk),
		.PCIN        				(dotx),
		.A        					(-p[1].y),
		.B        					(p[1].y),
		.D        					(Lp.y),
		.PCOUT        				(doty),
		.P	        				()
	);
	
	dsp_macro_dot dot_z
	(
		.CLK    					(clk),
		.PCIN        				(doty),
		.A        					(-p[2].z),
		.B        					(p[2].z),
		.D        					(Lp.z),
		.PCOUT        				(),
		.P	        				(dotNL)
	);
	
	//Secomd pipeline
	generate
		for(pipe_idx = 1; pipe_idx < DOT_PIPELINE_LEN; pipe_idx++)
		begin
			always @ (posedge clk)
			begin
				if(rst)
				begin
					p[pipe_idx] <= '{default:0};
					in_sphere_vld[pipe_idx] <= 0;
				end
				else
				begin
					if(run[0] || run[PIPELINE_LEN-1])
					begin
						p[pipe_idx] <= p[pipe_idx - 1];
						in_sphere_vld[pipe_idx] <= in_sphere_vld[pipe_idx - 1];
					end
				end
			end
		end
	endgenerate
	
	//Light direction at point on surface of sphere
	assign L.x = Lp.x - p[DOT_PIPELINE_LEN - 1].x;
	assign L.y = Lp.y - p[DOT_PIPELINE_LEN - 1].y;
	assign L.z = Lp.z - p[DOT_PIPELINE_LEN - 1].z;

	//Used for simulation
	assign dotNLCALC = 
	p[DOT_PIPELINE_LEN - 1].x*L.x + 
	p[DOT_PIPELINE_LEN - 1].y*L.y + 
	p[DOT_PIPELINE_LEN - 1].z*L.z;
	
	//Clamp output to a minimum of one bit so we get ambient light on the sphere
	assign clampDotNL = 
	dotNL > 1 << (`LOC_WIDTH - (`VGA_COLOR_DEPTH - 1)) ? 
	dotNL : 
			1 << (`LOC_WIDTH - (`VGA_COLOR_DEPTH - 1));
	
	//Down convert from 32-bit to 8-bit
	assign fb_o.val[`R_RANGE_FB] = in_sphere_vld[DOT_PIPELINE_LEN - 1] ? clampDotNL >> (`LOC_WIDTH - (`FB_SINGLE_COLOR_DEPTH - 1)) : 0;
	assign fb_o.val[`G_RANGE_FB] = in_sphere_vld[DOT_PIPELINE_LEN - 1] ? clampDotNL >> (`LOC_WIDTH - (`FB_SINGLE_COLOR_DEPTH - 1)) : 0;
	assign fb_o.val[`B_RANGE_FB] = in_sphere_vld[DOT_PIPELINE_LEN - 1] ? clampDotNL >> (`LOC_WIDTH - (`FB_SINGLE_COLOR_DEPTH - 1)) : 0;
	
	
	logic x_end;
	logic y_end;
	
	assign x_end = x_coord == (`X_WIDTH-1);
	assign y_end = y_coord == (`Y_WIDTH-1);
	
	//Keep track of when pipelines should run
	always @ (posedge clk)
	begin
		if(rst)
		begin
			run[0] <= 0;
		end
		else
		begin
			if(fb_o.row_done)
			begin
				run[0] <= 1;
			end
			else if(x_end)
			begin
				run[0] <= 0;
			end
		end
	end
	
	//Keep track of X and Y coordinates
	always @ (posedge clk)
	begin
		if(rst)
		begin
			x_coord <= 0;
		end
		else
		begin
			if (x_end)
			begin
				x_coord <= 0;
			end
			else
			begin
				if(run[0])
				begin
					x_coord <= x_coord + 1;
				end
			end

		end
	end
    
	always @ (posedge clk)
	begin
		if(rst)
		begin
			y_coord <= 0;
		end
		else
		begin
			if(x_end)
			begin
				if (y_end)
				begin
					y_coord <= 0;
				end
				else
				begin
					if(run[0])
					begin
						y_coord <= y_coord + 1;
					end
				end
			end
		end
	end
	
    
    
    
    endmodule
