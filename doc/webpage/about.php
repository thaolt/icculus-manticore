<php>
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

<a href="top"></a>
<div id="title_bar"><image alt="Manticore" src="images/manticore_title.gif"></div>
<h1>About Manticore</h1>
<div class="text_submenu"> - 
<a href="#abstract">abstract</a> - 
<a href="#goals">goals</a> - 
<a href="#status">status</a> - 
<a href="#license">license</a> - 
<a href="authors.php">about the authors</a> - 
</div>

<h2><a name="abstract">Abstract</a></h2>
<p>Manticore is an open source hardware design for a 3D graphics
accelerator.  It is written entirely in VHDL.  It is currently capable
of rendering triangles on a VGA display.  The design includes a VGA
output module, an open source (written entirely by the authors) SDRAM
controller and a triangle rasterizer.</p>

<p>Eventually it will incorporate standard 2D graphics primitives,
multiple resolutions and colour depths, hardware lighting support and
a PCI or perhaps AGP interface.  Please see the <a href="#goals">goals</a>
section for the development roadmap.</p>

<p>The design was originally developed on an Altera APEX20K200E FPGA
and Nios development board.  The design was able to operate at 50MHz
with this hardware.  Ultimately, an open board design will be
developed, creating an entirely open source PC graphics
accelerator.</p>

<p>Further information about Altera hardware can be found on their
<a href="http://www.altera.com">website</a>.</p>
<p><a href="#top">Back to top</a></p>


<h2><a name="goals">Goals</a></h2>
<p>Below is a list of the current project goals:</p>
<ol>
<li>fix rasterizer for all triangle orientations</li>
<li>add z-buffer</li>
<li>generalize SDRAM controller, VGA output unit, and all supporting
modules for different resolutions and colour depths</li>
<li>develop PCI interface</li>
<li>add normal support to the rasterizer (facing/backfacing information
+ basic lighting)</li>
<li>implement vertex lighting</li>
<li>implement texture mapping</li>
<li>add 2D support (lines, basic polygons, hardware cursor)</li>
<li>develop board design</li>
</ol>

<p>If you are at all knowledgeable about any of these topics and would
like to contribute, by all means please send us an email: 
(<a href="mailto:benjcarson@digitaljunkies.ca">Benj</a> or 
<a href="mailto:jm@icculus.org">Jeff</a>).</p>
<p><a href="#top">Back to top</a></p>

<h2><a name="status">Status / Progress</a></h2>
<p>Below are the current achievements of the project:</p>
<ul>
<li>VGA display module is stable at 640x480x8bpp (3-3-2)</li>
<li>SDRAM controller functions with no known bugs in 4-burst mode<br>
    <ul>
	<li>Read, write, NOP, MRS, ACTIV and refresh commands have been implemented</li>
	<li>DQM (masking) is implemented</li>
    <li>Most timing parameters have been generalized except burst length</li>
	</ul>
<li>Two frame buffers have been implemented</li>
<li>Rasterizer is capable of rendering triangles in most orientations 
and of calculating the z-value of points inside the triangle</li>
<li>Rasterizer can draw 100% of the time without disrupting the display</li>
</ul>
<p><a href="#top">Back to top</a></p>


<h2><a name="license">License</a></h2>
<p>Manticore is available under the 
<a href="http://www.dsl.org/copyleft/dsl.txt">Design Science License</a>.
From the preamble of the license:</p>
<div class="quote"><p>The intent of this license is to be a general
&quot;copyleft&quot; that can be applied to any kind of work that has
protection under copyright. This license states those certain
conditions under which a work published under its terms may be copied,
distributed, and modified.</p>

<p>Whereas &quot;design science&quot; is a strategy for the development of
artifacts as a way to reform the environment (not people) and
subsequently improve the universal standard of living, this Design
Science License was written and deployed as a strategy for promoting
the progress of science and art through reform of the environment.</p>
</div>

<p>Manticore is &copy; 2002 Jeff Mrochuk and Benj Carson.  Under the
DSL, however, its source may be distributed, published or copied in
its entirety provided the license is clearly published with all copies.</p>

<p>Please read the entire <a href="dsl.txt">license</a> before using or working
on any portions of the project.  For more information about the DSL, see 
<a href="http://www.dsl.org/copyleft">www.dsl.org/copyleft</a> and
<a href="http://linux.oreillynet.com/pub/a/linux/2000/08/01/LivingLinux.html">Open
Source Beyond Software</a> on the O'Reilly Network.</p>

<p><a href="#top">Back to top</a></p>

<?php include("footer.inc") ?>

</body></html>
