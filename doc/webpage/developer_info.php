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
<h1>Contributing</h1>
<div class="text_submenu"> - 
<a href="contributing.php#mailing_lists">mailing lists</a> - 
<a href="contributing.php#bug_reports">bug reports</a> - 
<a href="developer_info.php">developer info</a> - 
<a href="contributing.php#cvs.php">cvs</a> - 
</div>

<h2>Developer Information</h2>
<h3>Tools you'll need:</h3>
<h4>Quartus II</h4>
<p>The code is still fairly vendor-dependent, since the only hardware we've had the 
opportunity to try is Altera's APEX20K200E.  Quartus II is the EDA tool required to
compile designs for the APEX20K family of FPGAs.  A limited version is available
for free from Altera's <a href="http://www.altera.com/products/software/free/quartus2/sof-quarwebmain.html"
>web site</a>.  The web edition can not target chips larger than the APEX20K160, so
if you are interested in actually testing the design in hardware, you will have to purchase
or have access to a full edition.  You can still compile the design and simulate it using the
web edition, however.</p>

<p>Please note that Quartus II is incredibly memory intensive and you will require <strong>at 
least</strong> 256MB of memory to compile the entire design, and more if you want to do so
in a reasonable amount of time.  Last time we checked it took 30 minutes to compile
the entire design on a PIII 666 with 384MB of SDRAM running Windows 2000.  Quartus' 
performance also seems to be best under Windows 2000, and worse under Windows 98.</p>

<h4>Hardware</h4>
<p>The design was initially tested on Altera's
<a href="http://www.altera.com/products/devkits/altera/kit-nios.html">Excalibur Development
Kit</a>.  The board has a built-in SODIMM connector and uses the APEX20K200E (EPF20K200EFC484).  
The design is guaranteed to work with this board and FPGA.  Other boards and FPGAs may or may not work.
If you manage to port the design to different hardware please let us know and we will add
your hardware to this list.</p>

<p>You will also need a 144-pin SODIMM (commonly found in laptops).  32MB PC66 memory should suffice.</p>

<p>You will need a DAC of some sort as well.  We used a simple resistor network (see 
<a href="8bpp.php">here</a> for details), although a VDAC should work equally well.</p>

<?php include("footer.inc"); ?>

</body></html>
