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

    int dx,dy;
    float m, i, a, b, c;

    dx = P2.GetX()-P1.GetX();
    dy = P2.GetY()-P1.GetY();


    if(dx!=0){
       m = (float)dy/(float)dx;
    }else{
       m = 1000000;
    }

    i = (float)P1.GetY()-(m)*((float)P1.GetX());

    a = (-m*dx);
    b = dx;
    c = i*dx;

    if(a>0){    // Round for truncation
        a+=0.5;
    }else{
        a-=0.5;
    }
    if(b>0){
        b+=0.5;
    }else{
        b-=0.5;
    }
    if(c>0){
        c+=0.5;
    }else{
        c-=0.5;
    }

    eq[0] = (short)a;  // A
    eq[1] = (short)b;  // B
    eq[2] = (short)c;  
    // C
}

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


void
Rasterizer::Rasterize(Triangle3D &tri){
    
  short *colors = new short[9];
  short *eq = new short[9];

  P1X = tri.GetP3D1().GetX();     //  Grab the points' x,y,z values;
  P1Y = tri.GetP3D1().GetY();   P1Z = tri.GetP3D1().GetZ();
  P2X = tri.GetP3D2().GetX();  
  P2Y = tri.GetP3D2().GetY();   P2Z = tri.GetP3D2().GetZ();
  P3X = tri.GetP3D3().GetX();  
  P3Y = tri.GetP3D3().GetY();   P3Z = tri.GetP3D3().GetZ();
  
  // 3D to screen projections
  P1screenX = (int)(P1X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P1Z) +MCORE_WIDTH/2);
  P1screenY = (int)(P1Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P1Z) +MCORE_HEIGHT/2);
  P2screenX = (int)(P2X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P2Z) +MCORE_WIDTH/2);
  P2screenY = (int)(P2Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P2Z) +MCORE_HEIGHT/2);
  P3screenX = (int)(P3X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P3Z) +MCORE_WIDTH/2);
  P3screenY = (int)(P3Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P3Z) +MCORE_HEIGHT/2);

  Point2D P1(P1screenX, P1screenY, tri.GetP3D1().GetR(), tri.GetP3D1().GetG(), tri.GetP3D1().GetB());  // create some 2d points, (still need to impliment z)
  Point2D P2(P2screenX, P2screenY, tri.GetP3D2().GetR(), tri.GetP3D2().GetG(), tri.GetP3D2().GetB());
  Point2D P3(P3screenX, P3screenY, tri.GetP3D3().GetR(), tri.GetP3D3().GetG(), tri.GetP3D3().GetB());

  s3dGetColorDeltas(P1,P2,P3, colors);   // Short array pointers are used to load the SIMD array
                                         // kept here for consistency

  Point2D *Sorted1, *Sorted2, *Sorted3;


  // Use cross product to make sure triangle orientation is correct
  int crossz;
  // Rz = PxQy - PyQx;   P = P1-P2, Q=P1-P3
  crossz = (P1.GetX() - P2.GetX())*(P1.GetY() - P3.GetY()) - (P1.GetY() - P2.GetY())*(P1.GetX()-P3.GetX());
  if(crossz >= 0){
    Sorted1 = &P1;
    Sorted2 = &P2;
    Sorted3 = &P3;
  }else{
    Sorted1 = &P3;
    Sorted2 = &P2;
    Sorted3 = &P1;
  }

  s3dGetLineEq( *Sorted2, *Sorted1, eq); 
  s3dGetLineEq( *Sorted3, *Sorted2, eq+3);
  s3dGetLineEq( *Sorted1, *Sorted3, eq+6);

  short red,green,blue;
  short yrstart, ybstart, ygstart;
  int color;

  short miny, minx, maxy, maxx;

  miny = min(P1.GetY(),P2.GetY());
  miny = min(miny,     P3.GetY());
  minx = min(P1.GetX(),P2.GetX());
  minx = min(minx,     P3.GetX());

  maxy = max(P1.GetY(),P2.GetY());
  maxy = max(maxy,     P3.GetY());
  maxx = max(P1.GetX(),P2.GetX());
  maxx = max(maxx,     P3.GetX());

  yrstart =  (P1.GetR()<<8) + (maxx-P1.GetX())*colors[0] + (maxy-P1.GetY())*colors[1];
  ygstart =  (P1.GetG()<<8) + (maxx-P1.GetX())*colors[2] + (maxy-P1.GetY())*colors[3];
  ybstart =  (P1.GetB()<<8) + (maxx-P1.GetX())*colors[4] + (maxy-P1.GetY())*colors[5];

  short eq1result, eq1temp;
  short eq2result, eq2temp;
  short eq3result, eq3temp;

  eq1temp = eq[0]*(maxx) + eq[1]*(maxy) - eq[2]; 
  eq2temp = eq[3]*(maxx) + eq[4]*(maxy) - eq[5];
  eq3temp = eq[6]*(maxx) + eq[7]*(maxy) - eq[8];

  for(int y = maxy-1; y >= miny; y--){ 

      eq1temp -= (int)eq[1];
      eq2temp -= (int)eq[4];
      eq3temp -= (int)eq[7];

      eq1result = eq1temp;
      eq2result = eq2temp;
      eq3result = eq3temp;

      yrstart -= colors[1];
      red = yrstart;

      ygstart -= colors[3];
      green = ygstart;

      ybstart -= colors[5];
      blue = ybstart;

      for(int x = maxx-1; x >= minx; x--){

         eq1result -= (int)eq[0];
         eq2result -= (int)eq[3];
         eq3result -= (int)eq[6];

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

          }
      }
  }
}


