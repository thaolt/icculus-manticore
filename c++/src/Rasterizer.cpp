
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

#define BINARY_PLACES 10
/////////////////////////////// Public ///////////////////////////////////////

//============================= Lifecycle ====================================

//Rasterizer::Rasterizer(SDL_Surface *InScreen, PixelRAM  *InPixelData)
Rasterizer::Rasterizer(unsigned char *buffer, int dx, int dy)
{
  m_pPixelData = buffer;
  m_pZData = new int[dx*dy];
  m_dx = dx;
  m_dy = dy;
  m_bpp = 16;
  
  colors = new short[9];  // short arrays for SIMD array
  eq = new short[9];
  zslopes = new int[3];
//  PixelData = InPixelData;
//  Screen = InScreen;
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
Rasterizer::blank(){

  unsigned short* p = (unsigned short *)m_pPixelData;
  
  for(int x=0; x < m_dx; x++){
    for(int y=0; y < m_dy; y++){
      m_pZData[y*m_dx+x] = -20000000;
      p[y*m_dx+x] = 0;      
    }
  }
  
}


void 
Rasterizer::s3dGetColorDeltas(Point2D& P1, Point2D& P2, Point2D& P3, short* colors){
   int drdx, drdy, dgdx, dgdy, dbdx, dbdy, area;
   int rstart, gstart, bstart;

      area = ((P2.GetX() - P1.GetX()) * (P3.GetY() - P1.GetY()) - (P2.GetY() - P1.GetY()) * (P3.GetX() - P1.GetX()));
      // Find the red slopes, 8 binary places after point
      if(area == 0){
          for(int i=0; i<9; i++){
              colors[i]=0;
              return;
          }
      }
	  drdx = (((P2.GetR() - P1.GetR()) * (P3.GetY() - P1.GetY()) - (P3.GetR() - P1.GetR()) * (P2.GetY() - P1.GetY())) << BINARY_PLACES) / area;
	  drdy = (((P3.GetR() - P1.GetR()) * (P2.GetX() - P1.GetX()) - (P2.GetR() - P1.GetR()) * (P3.GetX() - P1.GetX())) << BINARY_PLACES) / area;

	  dgdx = (((P2.GetG() - P1.GetG()) * (P3.GetY() - P1.GetY()) - (P3.GetG() - P1.GetG()) * (P2.GetY() - P1.GetY())) << BINARY_PLACES) / area;
	  dgdy = (((P3.GetG() - P1.GetG()) * (P2.GetX() - P1.GetX()) - (P2.GetG() - P1.GetG()) * (P3.GetX() - P1.GetX())) << BINARY_PLACES) / area;

	  dbdx = (((P2.GetB() - P1.GetB()) * (P3.GetY() - P1.GetY()) - (P3.GetB() - P1.GetB()) * (P2.GetY() - P1.GetY())) << BINARY_PLACES) / area;
	  dbdy = (((P3.GetB() - P1.GetB()) * (P2.GetX() - P1.GetX()) - (P2.GetB() - P1.GetB()) * (P3.GetX() - P1.GetX())) << BINARY_PLACES) / area;

      rstart = (P1.GetR()<<BINARY_PLACES);
      gstart = (P1.GetG()<<BINARY_PLACES);
      bstart = (P1.GetB()<<BINARY_PLACES);

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
Rasterizer::s3dGetZDeltas(Point2D& P1, Point2D& P2, Point2D& P3, int* zslopes){

  int dzdx, dzdy, area;
  int zstart;

  area = ((P2.GetX() - P1.GetX()) * (P3.GetY() - P1.GetY()) - (P2.GetY() - P1.GetY()) * (P3.GetX() - P1.GetX()));
  // Find the red slopes, 8 binary places after point

   if(area == 0){
       for(int i=0; i<3; i++){
           zslopes[i]=0;
           return;
       }
   }

  dzdx = (((P2.GetZ() - P1.GetZ()) * (P3.GetY() - P1.GetY()) - (P3.GetZ() - P1.GetZ()) * (P2.GetY() - P1.GetY()))) / area;
  dzdy = (((P3.GetZ() - P1.GetZ()) * (P2.GetX() - P1.GetX()) - (P2.GetZ() - P1.GetZ()) * (P3.GetX() - P1.GetX()))) / area;

  zstart = (P1.GetZ());

  zslopes[0]=dzdx;
  zslopes[1]=dzdy;
  zslopes[2]=zstart;

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
       m = 100000000;
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
    


  P1X = tri.GetP3D1().GetX();     //  Grab the points' x,y,z values;
  P1Y = tri.GetP3D1().GetY();   
  P1Z = tri.GetP3D1().GetZ();
  P2X = tri.GetP3D2().GetX();  
  P2Y = tri.GetP3D2().GetY();   
  P2Z = tri.GetP3D2().GetZ();
  P3X = tri.GetP3D3().GetX();  
  P3Y = tri.GetP3D3().GetY();   
  P3Z = tri.GetP3D3().GetZ();
  
  // 3D to screen projections
  P1screenX = (int)(P1X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P1Z) +m_dx/2);
  P1screenY = (int)(P1Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P1Z) +m_dy/2);
  P2screenX = (int)(P2X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P2Z) +m_dx/2);
  P2screenY = (int)(P2Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P2Z) +m_dy/2);
  P3screenX = (int)(P3X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P3Z) +m_dx/2);
  P3screenY = (int)(P3Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P3Z) +m_dy/2);

  P1fixedZ = (int)tri.GetP3D1().GetZ()*4096; // 12 bits of fraction
  P2fixedZ = (int)tri.GetP3D2().GetZ()*4096;
  P3fixedZ = (int)tri.GetP3D3().GetZ()*4096;

  Point2D P1(P1screenX, P1screenY, P1fixedZ, tri.GetP3D1().GetR(), tri.GetP3D1().GetG(), tri.GetP3D1().GetB());  // create some 2d points, (still need to impliment z)
  Point2D P2(P2screenX, P2screenY, P2fixedZ, tri.GetP3D2().GetR(), tri.GetP3D2().GetG(), tri.GetP3D2().GetB());
  Point2D P3(P3screenX, P3screenY, P3fixedZ, tri.GetP3D3().GetR(), tri.GetP3D3().GetG(), tri.GetP3D3().GetB());

  s3dGetColorDeltas(P1,P2,P3, colors);   // short array pointers are used to load the SIMD array
                                         // kept here for consistency
  s3dGetZDeltas(P1,P2,P3, zslopes);

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


  int red, green, blue;
  
  short yrstart, ybstart, ygstart;
  int color;

  int z, yzstart;

  short miny, minx, maxy, maxx;

  miny = min(P1.GetY(),P2.GetY());
  miny = min(miny,     P3.GetY());
  minx = min(P1.GetX(),P2.GetX());
  minx = min(minx,     P3.GetX());

  maxy = max(P1.GetY(),P2.GetY());
  maxy = max(maxy,     P3.GetY());
  maxx = max(P1.GetX(),P2.GetX());
  maxx = max(maxx,     P3.GetX());

  yrstart =  (P1.GetR()<<BINARY_PLACES) + ((maxx+1)-P1.GetX())*colors[0] + ((maxy+1)-P1.GetY())*colors[1];
  ygstart =  (P1.GetG()<<BINARY_PLACES) + ((maxx+1)-P1.GetX())*colors[2] + ((maxy+1)-P1.GetY())*colors[3];
  ybstart =  (P1.GetB()<<BINARY_PLACES) + ((maxx+1)-P1.GetX())*colors[4] + ((maxy+1)-P1.GetY())*colors[5];

  yzstart =  (P1.GetZ()) + ((maxx+1)-P1.GetX())*zslopes[0] + ((maxy+1)-P1.GetY())*zslopes[1];

  short eq1result, eq1temp;
  short eq2result, eq2temp;
  short eq3result, eq3temp;

  eq1temp = eq[0]*(maxx+1) + eq[1]*(maxy+1) - eq[2]; 
  eq2temp = eq[3]*(maxx+1) + eq[4]*(maxy+1) - eq[5];
  eq3temp = eq[6]*(maxx+1) + eq[7]*(maxy+1) - eq[8];

  for(int y = maxy; y >= miny; y--){ 

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
     
      yzstart -= zslopes[1];
      z = yzstart;


      for(int x = maxx; x >= minx; x--){

         eq1result -= (int)eq[0];
         eq2result -= (int)eq[3];
         eq3result -= (int)eq[6];

         red   -= colors[0];
         
         green -= colors[2];

         blue -= colors[4];
         
         z -= zslopes[0];        
         
          if(  (eq1result <= 0)
            && (eq2result <= 0)
            && (eq3result <= 0) ){
//                   PixelData->WriteData(x,y,0xffff, (z));
//         }else{
//             if(PixelData->Getbpp()==32){
//                color = (red & 0xff00) << 8;
//                color = color | (green & 0xff00);
//                color = color | (blue & 0xff00) >> 8;
//              }else if(PixelData->Getbpp()==16){
//
                color = (red & (0x1f<<BINARY_PLACES)) << (11-BINARY_PLACES);
                color = color | (green & (0x3f<<BINARY_PLACES)) >> (BINARY_PLACES-5);
                color = color | (blue & (0x1f<<BINARY_PLACES)) >> (BINARY_PLACES);
//              }
                if((y<m_dy) && (x>0) && (x < m_dx) && (y > 0)){
                  if((z) > m_pZData[y*m_dx+x]){
                      m_pZData[y*m_dx+x]=z;
                      unsigned char *p;
                      p = &m_pPixelData[(y*m_dx+x)*(m_bpp/8)];
                      *(unsigned short *)p = color;
                }
              }
          }
      }
   }
  
}

/*
void
Rasterizer::Rasterizex(Triangle3Dx &tri){
    
  short *colors = new short[9];  // short arrays for SIMD array
  short *eq = new short[9];
  int *zslopes = new int[3];
  int temp;

  P1Xx = tri.GetP3D1().GetX();     //  Grab the points' x,y,z values;
  P1Yx = tri.GetP3D1().GetY();   
  P1Zx = tri.GetP3D1().GetZ();
  P2Xx = tri.GetP3D2().GetX();  
  P2Yx = tri.GetP3D2().GetY();   
  P2Zx = tri.GetP3D2().GetZ();
  P3Xx = tri.GetP3D3().GetX();  
  P3Yx = tri.GetP3D3().GetY();   
  P3Zx = tri.GetP3D3().GetZ();
  
  // 3D to screen projections
  temp = (P1Xx>>8)*(MCORE_FOCALLENGTH);
  temp = (temp)/((MCORE_FOCALLENGTH<<8)-(P1Zx>>8));
  P1screenX = temp+(m_dx)/2;

  P1screenY = ((((P1Yx>>8)*(MCORE_FOCALLENGTH))/((MCORE_FOCALLENGTH<<8)-(P1Zx>>8)))) +(m_dy)/2;
  P2screenX = ((((P2Xx>>8)*(MCORE_FOCALLENGTH))/((MCORE_FOCALLENGTH<<8)-(P2Zx>>8)))) +(m_dx)/2;
  P2screenY = ((((P2Yx>>8)*(MCORE_FOCALLENGTH))/((MCORE_FOCALLENGTH<<8)-(P2Zx>>8)))) +(m_dy)/2;
  P3screenX = ((((P3Xx>>8)*(MCORE_FOCALLENGTH))/((MCORE_FOCALLENGTH<<8)-(P3Zx>>8)))) +(m_dx)/2;
  P3screenY = ((((P3Yx>>8)*(MCORE_FOCALLENGTH))/((MCORE_FOCALLENGTH<<8)-(P3Zx>>8)))) +(m_dy)/2;

  P1fixedZ = (tri.GetP3D1().GetZ())>>4;//<<12; // 12 bits of fraction
  P2fixedZ = (tri.GetP3D2().GetZ())>>4;//<<12;
  P3fixedZ = (tri.GetP3D3().GetZ())>>4;//<<12;

  Point2D P1(P1screenX, P1screenY, P1fixedZ, tri.GetP3D1().GetR(), tri.GetP3D1().GetG(), tri.GetP3D1().GetB());  // create some 2d points, (still need to impliment z)
  Point2D P2(P2screenX, P2screenY, P2fixedZ, tri.GetP3D2().GetR(), tri.GetP3D2().GetG(), tri.GetP3D2().GetB());
  Point2D P3(P3screenX, P3screenY, P3fixedZ, tri.GetP3D3().GetR(), tri.GetP3D3().GetG(), tri.GetP3D3().GetB());

  s3dGetColorDeltas(P1,P2,P3, colors);   // short array pointers are used to load the SIMD array
                                         // kept here for consistency
  s3dGetZDeltas(P1,P2,P3, zslopes);

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


  short red, green, blue;
  short yrstart, ybstart, ygstart;
  int color;

  int z, yzstart;

  short miny, minx, maxy, maxx;

  miny = min(P1.GetY(),P2.GetY());
  miny = min(miny,     P3.GetY());
  minx = min(P1.GetX(),P2.GetX());
  minx = min(minx,     P3.GetX());

  maxy = max(P1.GetY(),P2.GetY());
  maxy = max(maxy,     P3.GetY());
  maxx = max(P1.GetX(),P2.GetX());
  maxx = max(maxx,     P3.GetX());

  yrstart =  (P1.GetR()<<8) + ((maxx)-P1.GetX())*colors[0] + ((maxy+1)-P1.GetY())*colors[1];
  ygstart =  (P1.GetG()<<8) + ((maxx)-P1.GetX())*colors[2] + ((maxy+1)-P1.GetY())*colors[3];
  ybstart =  (P1.GetB()<<8) + ((maxx)-P1.GetX())*colors[4] + ((maxy+1)-P1.GetY())*colors[5];

  yzstart =  (P1.GetZ()) + ((maxx+1)-P1.GetX())*zslopes[0] + ((maxy+1)-P1.GetY())*zslopes[1];

  short eq1result, eq1temp;
  short eq2result, eq2temp;
  short eq3result, eq3temp;

  eq1temp = eq[0]*(maxx+1) + eq[1]*(maxy+1) - eq[2]; 
  eq2temp = eq[3]*(maxx+1) + eq[4]*(maxy+1) - eq[5];
  eq3temp = eq[6]*(maxx+1) + eq[7]*(maxy+1) - eq[8];

  for(int y = maxy; y >= miny; y--){ 

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

      yzstart -= zslopes[1];
      z = yzstart;


      for(int x = maxx; x >= minx; x--){

         eq1result -= (int)eq[0];
         eq2result -= (int)eq[3];
         eq3result -= (int)eq[6];

         red   -= colors[0]; 
         green -= colors[2]; 
         blue  -= colors[4]; 
         z -= zslopes[0];        
         
          if(  (eq1result <= 0)
            && (eq2result <= 0)
            && (eq3result <= 0) ){
 //                   PixelData->WriteData(x,y,0xffff, (z));
 //         }else{
              if(PixelData->Getbpp()==32){
                color = (red & 0xff00) << 8;
                color = color | (green & 0xff00);
                color = color | (blue & 0xff00) >> 8;
              }else if(PixelData->Getbpp()==16){
                color = (red & 0x1f00) << 3;
                color = color | (green & 0x3f00) >> 3;
                color = color | (blue & 0x1f00) >> 8;
              }
              if((z) > PixelData->GetZ(x,y)){
                    PixelData->WriteData(x,y,color, (z));
              }
          }
      }
  }
}

*/