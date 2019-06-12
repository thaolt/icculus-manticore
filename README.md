[](top)

# About Manticore

## <a name="abstract">Abstract</a>

Manticore is an open source hardware design for a 3D graphics accelerator. It is written entirely in VHDL. It is currently capable of rendering triangles on a VGA display. The design includes a VGA output module, an open source (written entirely by the authors) SDRAM controller and a triangle rasterizer.

Eventually it will incorporate standard 2D graphics primitives, multiple resolutions and colour depths, hardware lighting support and a PCI or perhaps AGP interface. Please see the [goals](#goals) section for the development roadmap.

The design was originally developed on an Altera APEX20K200E FPGA and Nios development board. The design was able to operate at 50MHz with this hardware. Ultimately, an open board design will be developed, creating an entirely open source PC graphics accelerator.

Further information about Altera hardware can be found on their [website](http://www.altera.com).

[Back to top](#top)

## <a name="goals">Goals</a>

Below is a list of the current project goals:

1.  fix rasterizer for all triangle orientations
2.  add z-buffer
3.  generalize SDRAM controller, VGA output unit, and all supporting modules for different resolutions and colour depths
4.  develop PCI interface
5.  add normal support to the rasterizer (facing/backfacing information + basic lighting)
6.  implement vertex lighting
7.  implement texture mapping
8.  add 2D support (lines, basic polygons, hardware cursor)
9.  develop board design

If you are at all knowledgeable about any of these topics and would like to contribute, by all means please send us an email: ([Benj](mailto:benjcarson@digitaljunkies.ca) or [Jeff](mailto:jm@icculus.org)).

[Back to top](#top)

## <a name="status">Status / Progress</a>

Below are the current achievements of the project:

*   VGA display module is stable at 640x480x8bpp (3-3-2)
*   SDRAM controller functions with no known bugs in 4-burst mode  

    *   Read, write, NOP, MRS, ACTIV and refresh commands have been implemented
    *   DQM (masking) is implemented
    *   Most timing parameters have been generalized except burst length
*   Two frame buffers have been implemented
*   Rasterizer is capable of rendering triangles in most orientations and of calculating the z-value of points inside the triangle
*   Rasterizer can draw 100% of the time without disrupting the display

[Back to top](#top)

## <a name="license">License</a>

Manticore is available under the [Design Science License](http://www.dsl.org/copyleft/dsl.txt). From the preamble of the license:

<div class="quote">

The intent of this license is to be a general "copyleft" that can be applied to any kind of work that has protection under copyright. This license states those certain conditions under which a work published under its terms may be copied, distributed, and modified.

Whereas "design science" is a strategy for the development of artifacts as a way to reform the environment (not people) and subsequently improve the universal standard of living, this Design Science License was written and deployed as a strategy for promoting the progress of science and art through reform of the environment.

</div>

Manticore is © 2002 Jeff Mrochuk and Benj Carson. Under the DSL, however, its source may be distributed, published or copied in its entirety provided the license is clearly published with all copies.

Please read the entire [license](dsl.txt) before using or working on any portions of the project. For more information about the DSL, see [www.dsl.org/copyleft](http://www.dsl.org/copyleft) and [Open Source Beyond Software](http://linux.oreillynet.com/pub/a/linux/2000/08/01/LivingLinux.html) on the O'Reilly Network.

[Back to top](#top)

<div class="footer">All content © 2002 Jeff Mrochuk and Benj Carson  
Last modified: June 01, 2002</div>
