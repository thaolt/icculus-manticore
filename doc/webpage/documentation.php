<html>
<head>
<title>Manticore - Open Source 3D Graphics Accelerator</title>
<link rel="stylesheet" href="style.css" type="text/css">
<body>


<!-- --------------- Left column ------------- -->
<?php include("left_col.inc"); ?>

<!-- -------------- Right column -------------- -->
<?php include("right_col.inc"); ?>

<!-- -------------- Center column -------------- -->
<div id="centercontent">
<!--<image class="top_left" src="images/top_left.gif">
<image class="top_right" src="images/top_right.gif">
<image class="bottom_left" src="images/bottom_left.gif">
<image class="bottom_right" src="images/bottom_right.gif">-->

<a name="top"></a>
<div id="title_bar"><image alt="Manticore"  src="images/manticore_title.gif"></div>

<h1>Documentation</h1>
<div class="text_submenu"> - 
<a href="documentation.php#description">description</a> - 
<a href="datasheet.php">datasheet</a> - 
<a href="faq.php">FAQ</a> - 
<a href="howto.php">HOW-TOs</a> - 
</div>

<h2><a name="description">Description</a></h2>
<ul>
<li><a href="#overview">Overview</a></li>
<li><a href="#vga">VGA output</a></li>
<li><a href="#sdram">SDRAM controller</a></li>
<li><a href="#perspect">Perspective transformation and slope calculation</a></li>
<li><a href="#rasterizer">Rasterizer</a></li>
<!-- <li><a href="#z_buf">Z-Buffer</a></li> -->
</ul>

<a name="overview"><h3>Overview</h3></a>

<p>The Manticore processes a triangle and displays it on screen.
Triangle information is currently hard-coded, but it will eventually
be received over a PCI bus.  Triangles are expressed as three
&lt;x,y,z&gt; world coordinates.  Currently each value is expressed in as
16 bit numbers using a 10.6 fixed point format.</p>

<p>The triangle is <a href="#perspect">transformed</a> for perspective
and projected onto the imaging plane, yielding 2D screen coordinates.
The slopes of each edge of the triangle are calculated and passed to
the rasterizer.</p>

<p>The <a href="#rasterizer">rasterizer</a> sorts the triangle
vertices and calculates which pixels are within the triangle and which
are not.  For every pixel within the triangle, it writes the
triangle's colour to the frame buffer and masks (ignores) all pixels
outside of the triangle.  It also calculates the z-values of each
pixel within the triangle, which will eventually be written to the
z-buffer.</p>

<p>The frame buffer is stored in SDRAM.  This requires a fully functional 
<a href="#sdram">SDRAM controller</a>.  The frame buffer is read from
by the <a href="#vga">VGA</a> unit, which generates horizontal and vertical
sync signals and displays the image on the screen.</p>

<p><a href="block_diagram.gif">Figure 1</a> shows these steps.</p>

<p>All units are synchronous and have an active low asynchronous
reset. The entire design currently operates at 50MHz on an Altera
APEX20K200E.  The VGA output unit uses a 33MHz pixel clock.  The
design was originally implemented on a Nios development board, which
had a 33MHz clock on board.  The built-in PLL on the APEX20KE
generates both clocks.  If the design is ported to other FPGAs a
PLL will be required.</p>

<p><a href="#top">Back to top</a></p>

<a name="vga"><h3>VGA output</h3></a>

<p> The VGA output module is responsible for displaying the pixels
stored in the frame buffer on the screen as well as generating
blanking signals.  Standard VGA timing for a 640x480 display uses a
25.175MHz pixel clock.  Since the Nios board used had a system clock
frequency of 33 MHz, non-standard blanking timings were required.  For
simplicity, the pixel clock frequency is identical to the system clock
frequency.  The standard 640x480 VGA resolution is also used.  A
Matrox G400 video card was used to test accurate front porch, sync and
back porch timings. The following settings were determined to work
with Samsung 900NF, Panasonic E771 and Daytek (unknown model) 17&quot;
monitors, although any multisync monitor should tolerate the timings:</p>

<center><table class="timings">
<tr><td>Horizontal refresh:</td><td>40.8 kHz</td><td></td></tr>
<tr><td>Active</td><td>640 pixels</td><td>19.17 us</td></tr>
<tr><td>Front Porch</td><td>43 pixels</td><td>1.29 us</td></tr>
<tr><td>Sync</td><td>46 pixels</td><td>1.38 us</td></tr>
<tr><td>Back Porch</td><td>87 pixels</td><td>2.61 us</td></tr>
<tr><td>Entire Line</td><td>816 pixels</td><td>24.48 us</td></tr>
</table></center>

<center><table class="timings">
<tr><td>Vertical refresh:</td><td>76 Hz</td><td></td></tr>
<tr><td>Active</td><td>480 lines</td><td>11.75 ms</td></tr>
<tr><td>Front Porch</td><td>9 lines</td><td>0.223 ms</td></tr>
<tr><td>Sync</td><td>3 lines</td><td>73.44 us</td></tr>
<tr><td>Back Porch</td><td>30 lines</td><td>0.734 ms</td></tr>
<tr><td>Entire Line</td><td>522 lines</td><td>12.8 ms</td></tr>
</table></center>

<p>The VGA unit uses 8 bits-per-pixel for colour information, in a
3-3-2 distribution.  The VGA unit reads pixel information from a
FIFO that buffers an entire line of pixels during the blanking
interval.  The FIFO begins reading from the frame buffer when
the VGA pixel count reaches 640. It continues reading until it
buffers an entire line.  Since the data width of the SDRAM is 
64 bits, the FIFO grabs 8 pixels at a time.  The FIFO is emptied
as the VGA pixel count increases from 0-639.</p>

<p><a href="#top">Back to top</a></p>

<a name="sdram"><h3>SDRAM Controller</h3></a>
<p>The SDRAM controller handles low level SDRAM commands and
interfaces with the graphics core. </p> 

<p>The SODIMM has a 144-pin interface, which breaks down into clock, clock enable, row
address strobe (RAS), column address strobe (CAS), write enable (WE), chip select (CS), a
64-bit data path, a 12-bit address path, and an 8-bit data mask. </p>

<p>RAS, CAS, WE, and CS are all active low signals which specify the RAM command. These
commands break down into a row address activation (RAS) followed by one or multiple column
address activations (CAS).  WE low specifies a write, and WE high specifies a read.  Chip
select is used to turn on and off the specific chip on the DIMM. </p>

<p>The CAS delay and burst mode of the controller are not generic at this point, but both
will be further into development.</p>

<p>The high level interface of the controller consists of a read and write request, and some
acknowledge signals. At the moment the acknowledgement signals are being rewritten, so more documentation will be available upon finalization.</p>

<p>A separate module entitled vga_fifo_ctrl handles requests between the
graphics core and the SDRAM controller.</p>

<p>The core clock frequency has been reduced to 50MHz because of setup
and hold violations with the SDRAM itself.  We suspect wiring delays
cause this, but the internal controller design could be optimized
further.</p>

<p><a href="#top">Back to top</a></p>

<a name="perspect"><h3>Perspective Transformation and Slope Calculation</h3></a>
<p>In order to map 3D triangles onto the display, the perspective transformation
is used:</p>
<div class="eqn"><img width="180" src="images/perspect_eqn1.gif"></div>
<p>Where &lambda; is the focal length of the imaging system.  Since this
equation involves two divisions &lambda; was arbitrarily chosen
<p>Once the 2D coordinates are obtained, the slopes of each edge of the triangle
are calculated.  This operation is performed by the slope calculation engine,
which is simply two ALUs and a divider.  It is able to calculate arbitrary
equations of the form (A +/- B) / (C +/- D).  It is also used by the rasterizer
to perform slope calculations for each edge of the triangle.  The slope of each
edge is required by the rasterizer in order to draw arbitrary triangles.</p>

<p><a href="#top">Back to top</a></p>

<a name="rasterizer"><h3>Rasterizer</h3></a>
<p>The rasterizer takes the three perspective-corrected vertices and the three
slopes and uses an edge-walking algorithm to determine which pixels are within
the triangle and which are outside.  The algorithm begins at the top of the
triangle (i.e. the vertex with the lowest y value) and keeps track of each edge
as the y value is increased (towards the bottom of the screen).  Since the frame
buffer is accessed in bursts of 4 words each and since each word is 8 pixels, every
read operation must be aligned to a 4x8 = 32 pixel boundary.  Therefore, the
rasterization algorithm begins scanning at the nearest 32 pixel boundary to the
left of the triangle.  As the x value increases, the algorithm checks whether the 
current pixel is within the triangle or outside.  This continues for until the largest
y value in the triangle.  (Note that the slopes are re-determined when the vertex with
the second largest y value is reached.)</p>
<p>Write operations are buffered through a write FIFO.  Pixels inside get written to the
colour of the triangle and pixels outside have their mask bit set.  This permits
the overlapping of triangles and other graphics.  The write FIFO is emptied during the
interval when the memory is idle between read operations.</p>

<p><a href="#top">Back to top</a></p>

<!-- <a name="z_buf"><h3>Z-Buffer</h3></a> -->


<?php include("footer.inc"); ?>

</body></html>
