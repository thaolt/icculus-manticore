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
<a href="contributing#cvs.php">cvs</a> - 
</div>
<h2>8-bit Resistive Video DAC</h2>

<h3>Description</h3>
<p>VGA monitors accept three analog colour signals in the range of 0 to 0.7V.  While Altera's UP1
boards have a built-in VGA connection, the Excalibur development boards do not.  Using a few more pins and a couple
of resistors 8bpp (256 color) VGA output can be easily produced.</p>

<h3>Design</h3>
<p>Typical 8bpp systems use a 3-3-2 bit distribution: 3 bits for red, 3 for green and 2 for blue.  Other
breakdowns are possible.  This design is based on a 3.3V VDD which is available from the expansion headers
on the Nios board.  The schematic is shown below:</p>
<center><span class="figure"><img src="images/vga_out_schematic.gif"></span></center>
<p>Each of the outputs, RED0-2, GREEN0-2 and BLUE0-1 originate from the chip and must pass through a 3.3V 
buffer before reaching this circuit.</p>
<p>For a single 3 bit colour the required digital to analog conversion should be:</p>

<center>
<table>
<thead><th>Binary Value</th><th>Analog Value</th></thead>
<tr><td>000</td><td>0.0V</td></tr>
<tr><td>001</td><td>0.1V</td></tr>
<tr><td>010</td><td>0.2V</td></tr>
<tr><td>011</td><td>0.3V</td></tr>
<tr><td>100</td><td>0.4V</td></tr>
<tr><td>101</td><td>0.5V</td></tr>
<tr><td>110</td><td>0.6V</td></tr>
<tr><td>111</td><td>0.7V</td></tr>
</table>
</center>

<p>The 100&Omega; resistor was chosen somewhat arbitrarily.  It is half of the voltage divider formed 
by the other three resistors.  If it is too small currents in the may exceed maximum ratings, and if it is 
too large the current may become disturbed by noise.  Using the three cases when only one pin is active, the 
value of each resistor is determined using the following equations:</p>
<p>In general, given a 3.3V supply the output voltage of the voltage divider is:</p>
<div class="eqn"><img src="images/eqn1.gif"></div>
<p>Where V<sub>o</sub> is the analog voltage desired for the given binary value.</p>
<p>For the most significant bit:</p>
<div class="eqn"><img src="images/eqn2.gif"></div>
<p>And for the next bit:</p>
<div class="eqn"><img src="images/eqn3.gif"></div>
<p>And for the last bit:</p>
<div class="eqn"><img src="images/eqn4.gif"></div>

<p>For 2 bit colour, the desired conversion is:</p>
<center>
<table>
<thead><th>Binary Value</th><th>Analog Value</th></thead>
<tr><td>00</td><td>0.0V</td></tr>
<tr><td>01</td><td>0.233V</td></tr>
<tr><td>10</td><td>0.466V</td></tr>
<tr><td>11</td><td>0.7V</td></tr>
</table>
</center>

<p>The following two equations were used.  For the MSB:</p>
<div class="eqn"><img src="images/eqn5.gif"></div>
<p>And for the last bit:</p>
<div class="eqn"><img src="images/eqn6.gif"></div>
<p>This method can be adapted to a 5V output expansion slot as well.</p>
<h3>References</h3>
<p><a href="http://www.xess.com/appnotes/vga.pdf">VGA Signal Generation with the XS Board</a></p>

<?php include("footer.inc"); ?>

</body></html>