//////////////////////////////////////////////////////////////////////////
// Name: Rasterizer 
//
// Files:
// Bugs:
// See Also:
// Type: C++-Source
//////////////////////////////////////////////////////////////////////////
// Authors: Jeff Mrochuk
// Date:   March 23, 2004
//////////////////////////////////////////////////////////////////////////
// Modifications:
//
/////////////////////////////////////////////////////////////////////////
#include "Rasterizer.h"                                // class implemented
#include <math.h>

#define XPIXELSPERCU 640
#define YPIXELSPERCU 480
/////////////////////////////// Public ///////////////////////////////////////

//============================= Lifecycle ====================================

Rasterizer::Rasterizer(SDL_Surface *InScreen, PixelRAM  *InPixelData)
{
  PixelData = InPixelData;
  Screen = InScreen;
}// Rasterizer

Rasterizer::Rasterizer(const Rasterizer&)
{
}// Rasterizer

Rasterizer::~Rasterizer()
{
}// ~Rasterizer


//============================= Operators ====================================

Rasterizer& 
Rasterizer::operator=(const Rasterizer &rhs)
{
   if ( this==&rhs ) {
        return *this;
    }
    //superclass::operator =(rhs);

    //add local assignments

    return *this;

}// =

//============================= Operations ===================================

void
Rasterizer::Rasterize(Triangle3D &tri){
  
  degenerate = false;    
  short *colors = new short[9];

  P3D1 = tri.GetP3D1();  // Grab the 3 points from the triangle object
  P3D2 = tri.GetP3D2();
  P3D3 = tri.GetP3D3();
  P1X = P3D1.GetX();     //  Grab the points' x,y,z values;
  P1Y = P3D1.GetY();   P1Z = P3D1.GetZ();
  P2X = P3D2.GetX();  
  P2Y = P3D2.GetY();   P2Z = P3D2.GetZ();
  P3X = P3D3.GetX();  
  P3Y = P3D3.GetY();   P3Z = P3D3.GetZ();
  
  // 3D to screen projections
  P1screenX = P1X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P1Z) +MCORE_WIDTH/2;
  P1screenY = P1Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P1Z) +MCORE_HEIGHT/2;
  P2screenX = P2X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P2Z) +MCORE_WIDTH/2;
  P2screenY = P2Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P2Z) +MCORE_HEIGHT/2;
  P3screenX = P3X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P3Z) +MCORE_WIDTH/2;
  P3screenY = P3Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P3Z) +MCORE_HEIGHT/2;

  Point2D P1(P1screenX, P1screenY, 0, 255, 0);  // create some 2d points, (still need to impliment z)
  Point2D P2(P2screenX, P2screenY, 0, 0, 255);
  Point2D P3(P3screenX, P3screenY, 255, 0, 0);

  s3dGetColorDeltas(P1,P2,P3, colors); 

  Uint32 col1 = 255<<8;               // green
  Uint32 col2 = 255;                 // blue
  Uint32 col3 = 255<<16;              // red
  Uint32 col4 = col3 - (63<<16);      // dark red


  int i,j;
  // Slope Calculations & Triangle Sorting
  
  // Handle degenerate cases first
  // This means two points are on the same line,
  // or very close

  //  P1 and P2 on the same line, P3 above or below
  if(fabs(P1screenY-P2screenY) < 2){
      degenerate=true;
      if(P3screenY > P1screenY){  // 3rd point below others
          // define the relative location of each point
          // the naming is strange in the degenerate cases
          top=P1;  middle=P3; bottom=P3; left=P3; right=P3;
          if(P1screenX < P2screenX){   /// Which one is on the left
            l=P2screenX;          // l is where the left edge starts
            r=P1screenX;          // r is where the right edge starts
          }else{                  
            r=P2screenX; 
            l=P1screenX;
          }
          dxleft = l - left.GetX();    // find the difference between
          dxright = r - right.GetX();  // start of the edge and desinatiob
      }else{                       // 3rd point above the others
          top=P3; middle=P1; bottom=P1;
          l = P3.GetX();
          r = P3.GetX();
          if(P1screenX < P2screenX){
             left=P2; right=P1;
          }else{
             left=P1; right=P2;
          }
          dxleft = l - left.GetX();
          dxright = r - right.GetX();  
      }
  }

 //  P1 and P3 on the same line, P2 above or below
  else if(fabs(P1screenY-P3screenY) < 2){
      degenerate=true;
      if(P2screenY > P1screenY){  // 3rd point below
          top=P1;  middle=P2; bottom=P2; left=P2; right=P2;
          if(P1screenX < P3screenX){
            l=P3screenX; 
            r=P1screenX;
          }else{
            r=P3screenX; 
            l=P1screenX;
          }
          dxleft = l - left.GetX();
          dxright = r - right.GetX();
      }else{   // 3rd point above
          top=P2; middle=P1; bottom=P1;
          l = P2.GetX();
          r = P2.GetX();
          if(P1screenX < P3screenX){
             left=P3; right=P1;
          }else{
             left=P1; right=P3;
          }
          dxleft = l - left.GetX();
          dxright = r - right.GetX();  
      }
  }

  //  P2 and P3 on the same line, P1 above or below
  else if(fabs(P2screenY-P3screenY) < 2){ 
      degenerate=true;
      if(P1screenY > P3screenY){  // 3rd point below
          top=P2;  middle=P1; bottom=P1; left=P1; right=P1;
          if(P2screenX < P3screenX){
            l=P3screenX; 
            r=P2screenX;
          }else{
            r=P3screenX; 
            l=P2screenX;
          }
          dxleft = l - left.GetX();
          dxright = r - right.GetX();
      }else{   // 3rd point above
          top=P1; middle=P2; bottom=P2;
          l = P1.GetX();
          r = P1.GetX();
          if(P2screenX < P3screenX){
             left=P3; right=P2;
          }else{
             left=P2; right=P3;
          }
          dxleft = l - left.GetX();
          dxright = r - right.GetX();  
      }
  }

  // Normal cases, where the triangle has to be broken into two
  // requires a left slope, a right slope, and a closing slope

  // P1 on top, P2 or P3 in either order
  else if((P1screenY < P2screenY) && (P1screenY < P3screenY)){
    top = P1;
    if(P2screenY < P3screenY){
        bottom = P3;
        middle = P2;
    }else{
        bottom = P2;
        middle = P3;
    }
    if(P2screenX < P3screenX){
        right=P2;
        left=P3;
    }else{
        right=P3;
        left=P2;
    }
  }

  // P2 on top, P1 or P3 in either order
  else if((P2screenY < P1screenY) && (P2screenY < P3screenY)){
    top = P2;
    if(P1screenY < P3screenY){
        bottom = P3;
        middle = P1;
    }else{
        bottom = P1;
        middle = P3;
    }
    if(P1screenX < P3screenX){
        right=P1;
        left=P3;
    }else{
        right=P3;
        left=P1;
    }
  }

  // P3 on top, P2 or P1 in either order
  else if((P3screenY < P2screenY) && (P3screenY < P1screenY)) {
    top = P3;
    if(P2screenY < P1screenY){
        bottom = P1;
        middle = P2;
    }else{
        bottom = P2;
        middle = P1;
    }
    if((P2screenX < P1screenX)){
        right=P2;  
        left=P1;
    }else{
        right=P1;
        left=P2;
    }
  }

  // slopes down the top left edge, top right edge, and the line that closes the triangle

  if(!degenerate){ // some operations that we've done in the degenerate cases
    dxleft = top.GetX() - left.GetX();
    dxright = top.GetX() - right.GetX();
    dxclose = middle.GetX() - bottom.GetX();
    l=top.GetX();
    r=top.GetX();

    // calculate the closing edge slope
    dy = middle.GetY()-bottom.GetY();
    slopeclose = dxclose/dy;
  }

    // calcule the left edge slope
  dy = top.GetY()-left.GetY();
  slopeleft = dxleft/dy;

  // calculate the right edge slope
  dy = top.GetY()-right.GetY();
  sloperight = dxright/dy;


  float temp;
  // definitions of l and r are not really accurate
  // in the case where all 3 points are increasing in x
  // this will catch that
  if(!degenerate){
    if(slopeleft < sloperight){  
         temp=slopeleft;
         slopeleft=sloperight;
         sloperight=temp;
     }
  }

  short red = colors[6];
  short green = colors[7];
  short blue = colors[8];
  int color=0;
  // Draw the top half of the triangle
  for( i=top.GetY(); i < middle.GetY(); i++){

      red = colors[6];
      green = colors[7];
      blue = colors[8];

      red += (i-top.GetY()) * colors[1];
      red += colors[0] *  ((float)(i-top.GetY()) / slopeleft) ;

      green += (i-top.GetY()) * colors[3];
      green += colors[2] * ((float)(i-top.GetY()) / slopeleft);

      blue += (i-top.GetY()) * colors[5];
    //  blue -= colors[4] * ((float)(i-top.GetY()) / slopeleft);

      l+=slopeleft;
      r+=sloperight;

      for( j=(int)r; j<(int)l; j++){

          red   += colors[0];
          green += colors[2];
          blue  += colors[4];
          color = 0;
        //  color = ((red & 0x0000ff00)<<8);
        //  color = color | (green & 0x0000ff00);
          color = color | ((blue & 0x0000ff00)>>8);
          PixelData->WriteData((Uint32)j,i, color);
      }    
  }

  // decide which edge is going to close the triangle
   if(fabs(r - middle.GetX()) < fabs(l - middle.GetX())){
       r=middle.GetX();
       sloperight=slopeclose;
   }else{
       l=middle.GetX();
       slopeleft=slopeclose;
   }

   // Draw the bottom half of the triangle
  for(i=middle.GetY(); i < bottom.GetY(); i++){
      l+=slopeleft;
      r+=sloperight;
      for(Uint32 j=(Uint32)r; j<(Uint32)l; j++){
         PixelData->WriteData((Uint32)j,i, col4);
      }     
  }

  // draw the vertices, for reference
  for( i=-1; i < 1; i++){
    for( j=-1; j <1; j++){
      PixelData->WriteData((Uint32)P1.GetX()+i,(Uint32)P1.GetY()+j, col1);
      PixelData->WriteData((Uint32)P2.GetX()+i,(Uint32)P2.GetY()+j, col2);
      PixelData->WriteData((Uint32)P3.GetX()+i,(Uint32)P3.GetY()+j, col3);
    }
  }
}


void 
Rasterizer::s3dGetColorDeltas(Point2D& P1, Point2D& P2, Point2D& P3, short* colors){
   int drdx, drdy, dgdx, dgdy, dbdx, dbdy, area;
   int rstart, gstart, bstart;

      area = ((P2.GetX() - P1.GetX()) * (P3.GetY() - P1.GetY()) - (P2.GetY() - P1.GetY()) * (P3.GetX() - P1.GetX()));
      // Find the red slopes, 8 binary places after point
	  drdx = (((P2.GetR() - P1.GetR()) * (P3.GetY() - P1.GetY()) - (P3.GetR() - P1.GetR()) * (P2.GetY() - P1.GetY())) << 8) / area;
	  drdy = (((P3.GetR() - P1.GetR()) * (P2.GetX() - P1.GetX()) - (P2.GetR() - P1.GetR()) * (P3.GetX() - P1.GetX())) << 8) / area;

	  dgdx = (((P2.GetG() - P1.GetG()) * (P3.GetY() - P1.GetY()) - (P3.GetG() - P1.GetG()) * (P2.GetY() - P1.GetY())) << 8) / area;
	  dgdy = (((P3.GetG() - P1.GetG()) * (P2.GetX() - P1.GetX()) - (P2.GetG() - P1.GetG()) * (P3.GetX() - P1.GetX())) << 8) / area;

	  dbdx = (((P2.GetB() - P1.GetB()) * (P3.GetY() - P1.GetY()) - (P3.GetB() - P1.GetB()) * (P2.GetY() - P1.GetY())) << 8) / area;
	  dbdy = (((P3.GetB() - P1.GetB()) * (P2.GetX() - P1.GetX()) - (P2.GetB() - P1.GetB()) * (P3.GetX() - P1.GetX())) << 8) / area;


      rstart = (P1.GetR()<<8);
      gstart = (P1.GetG()<<8);
      bstart = (P1.GetB()<<8);


      //rstart += (XPIXELSPERCU-P1.GetX())*drdx;
      //rstart += (YPIXELSPERCU-P1.GetY())*drdy;

      //gstart += (XPIXELSPERCU-P1.GetX())*dgdx;
      //gstart += (YPIXELSPERCU-P1.GetY())*dgdy;

      //bstart += (XPIXELSPERCU-P1.GetX())*dbdx;
      //bstart += (YPIXELSPERCU-P1.GetY())*dbdy;

      colors[0]=(short)drdx;
      colors[1]=(short)drdy;
      colors[2]=(short)dgdx;
      colors[3]=(short)dgdy;
      colors[4]=(short)dbdx;
      colors[5]=(short)dbdy;
      colors[6]=(short)rstart;
      colors[7]=(short)gstart;
      colors[8]=(short)bstart;

   }

void
Rasterizer::s3dGetLineEq(Point2D& P1, Point2D& P2, short* eq){

       float dx,dy, m, i;

       dx = (float)(P2.GetX()-P1.GetX());
       dy = (float)(P2.GetY()-P1.GetY());
       m = dy/dx;
       i = (float)P1.GetY()-m*(float)P1.GetX();

       eq[0] = (short)(-m*dx);  // A
       eq[1] = (short)(dx);     // B
       eq[2] = (short)(i*dx);   // C

   }
#ifndef _MSC_VER

int max(int x, int y)
{
    if (x >= y)
    {
        return x;
    }
    return y;
}

int min(int x, int y)
{
    if (x <= y)
    {
        return x;
    }
    return y;
}

#endif
void
Rasterizer::Rasterize2(Triangle3D &tri){
    
  short *colors = new short[9];
  short *eq = new short[9];

  P3D1 = tri.GetP3D1();  // Grab the 3 points from the triangle object
  P3D2 = tri.GetP3D2();
  P3D3 = tri.GetP3D3();
  P1X = P3D1.GetX();     //  Grab the points' x,y,z values;
  P1Y = P3D1.GetY();   P1Z = P3D1.GetZ();
  P2X = P3D2.GetX();  
  P2Y = P3D2.GetY();   P2Z = P3D2.GetZ();
  P3X = P3D3.GetX();  
  P3Y = P3D3.GetY();   P3Z = P3D3.GetZ();
  
  // 3D to screen projections
  P1screenX = P1X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P1Z) +MCORE_WIDTH/2;
  P1screenY = P1Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P1Z) +MCORE_HEIGHT/2;
  P2screenX = P2X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P2Z) +MCORE_WIDTH/2;
  P2screenY = P2Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P2Z) +MCORE_HEIGHT/2;
  P3screenX = P3X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P3Z) +MCORE_WIDTH/2;
  P3screenY = P3Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P3Z) +MCORE_HEIGHT/2;

  Point2D P1(P1screenX, P1screenY, 0, 255, 0);  // create some 2d points, (still need to impliment z)
  Point2D P2(P2screenX, P2screenY, 0, 0, 255);
  Point2D P3(P3screenX, P3screenY, 255, 0, 0);

  s3dGetColorDeltas(P1,P2,P3, colors);   // Short array pointers are used to load the SIMD array
                                         // kept here for consistency
  s3dGetLineEq( P2, P1, eq); 
  s3dGetLineEq( P3, P2, eq+3);
  s3dGetLineEq( P1, P3, eq+6);

  short red,green,blue;
  short yrstart, ybstart, ygstart;
  int color;

  short miny, minx, maxy, maxx;
#ifdef _MSC_VER
  miny = __min(P1.GetY(),P2.GetY());
  miny = __min(miny,     P3.GetY());
  minx = __min(P1.GetX(),P2.GetX());
  minx = __min(minx,     P3.GetX());

  maxy = __max(P1.GetY(),P2.GetY());
  maxy = __max(maxy,     P3.GetY());
  maxx = __max(P1.GetX(),P2.GetX());
  maxx = __max(maxx,     P3.GetX());
#else
  miny = min(P1.GetY(),P2.GetY());
  miny = min(miny,     P3.GetY());
  minx = min(P1.GetX(),P2.GetX());
  minx = min(minx,     P3.GetX());

  maxy = max(P1.GetY(),P2.GetY());
  maxy = max(maxy,     P3.GetY());
  maxx = max(P1.GetX(),P2.GetX());
  maxx = max(maxx,     P3.GetX());
#endif

  red   =  (P1.GetR()<<8) + (maxx-P1.GetX())*colors[0] + (maxy-P1.GetY())*colors[1];
  green =  (P1.GetG()<<8) + (maxx-P1.GetX())*colors[2] + (maxy-P1.GetY())*colors[3];
  blue  =  (P1.GetB()<<8) + (maxx-P1.GetX())*colors[4] + (maxy-P1.GetY())*colors[5];

  yrstart = red;
  ygstart = green;
  ybstart = blue;

  short eq1result, eq1temp;
  short eq2result, eq2temp;
  short eq3result, eq3temp;

  eq1temp = eq[0]*maxx + eq[1]*maxy - eq[2];
  eq2temp = eq[3]*maxx + eq[4]*maxy - eq[5];
  eq3temp = eq[6]*maxx + eq[7]*maxy - eq[8];

  for(int y = maxy; y >= miny; y--){           // Treat like one giant PE at the moment

      eq1temp -= eq[1];
      eq2temp -= eq[4];
      eq3temp -= eq[7];

      eq1result = eq1temp;
      eq2result = eq2temp;
      eq3result = eq3temp;

      yrstart -= colors[1];
      red = yrstart;

      ygstart -= colors[3];
      green = ygstart;

      ybstart -= colors[5];
      blue = ybstart;

      for(int x = maxx; x >= minx; x--){

         eq1result -= eq[0];
         eq2result -= eq[3];
         eq3result -= eq[6];

         red   -= colors[0]; 
         green -= colors[2]; 
         blue  -= colors[4]; 
         
          if(  (eq1result < 0)
            && (eq2result < 0)
            && (eq3result < 0) ){

             color = (red & 0xff00) << 8;
             color = color | (green & 0xff00);
             color = color | (blue & 0xff00) >> 8;

             PixelData->WriteData((Uint32)x,y, color);
          }else{
             PixelData->WriteData((Uint32)x,y, 0x00ffff00);
          }
      }
  }

}


