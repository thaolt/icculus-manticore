
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
#include "Transformer.h"

#include <math.h>
#include "mcore_types.h"

#define BINARY_PLACES 10
#define VERTEX_START_SIZE 9

extern 
/////////////////////////////// Public ///////////////////////////////////////


//============================= Lifecycle ====================================
/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/
 
Rasterizer::Rasterizer(oglContext* context)
{
  m_pPixelData  = (unsigned char*)(context->drawDesc->colorBuffer);
  m_pZData      = (int*)(context->drawDesc->depthBuffer);
  m_dx          = context->drawDesc->width;
  m_dy          = context->drawDesc->height;
  m_bpp         = 8*context->drawDesc->colorBytes;
  
  colors        = new short[9];  // short arrays for SIMD array
  eq            = new short[9];
  zslopes       = new int[3];
  
  m_vertexCount = 0;
  m_vertexSize  = VERTEX_START_SIZE;
  m_vertexArray = new float[VERTEX_START_SIZE];
  m_colorArray  = new unsigned char[VERTEX_START_SIZE];

  TransformEngine = new Transformer();

}// Rasterizer

/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/
 
Rasterizer::Rasterizer(const Rasterizer&)
{
}// Rasterizer

/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/
 
Rasterizer::~Rasterizer()
{

  delete[] colors;
  delete[] eq;
  delete[] zslopes;
  delete[] m_vertexArray;
  
}// ~Rasterizer


//============================= Operators ====================================
/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/
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

/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/

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

/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/

void 
Rasterizer::s3dGetColorDeltas(Point2D& P1, Point2D& P2, Point2D& P3, short* colors){
   int drdx, drdy, dgdx, dgdy, dbdx, dbdy, area;
   int rstart, gstart, bstart;

   int P1R = (int)P1.GetR();
   int P1G = (int)P1.GetG();
   int P1B = (int)P1.GetB();

   int P2R = (int)P2.GetR();
   int P2G = (int)P2.GetG();
   int P2B = (int)P2.GetB();
  
   int P3R = (int)P3.GetR();
   int P3G = (int)P3.GetG();
   int P3B = (int)P3.GetB();  

      area = ((P2.GetX() - P1.GetX()) * (P3.GetY() - P1.GetY()) - (P2.GetY() - P1.GetY()) * (P3.GetX() - P1.GetX()));
      // Find the red slopes, 8 binary places after point
      if(area == 0){
          for(int i=0; i<9; i++){
              colors[i]=0;
              return;
          }
      }
      
	  drdx = (((P2R - P1R) * (P3.GetY() - P1.GetY()) - (P3R - P1R) * (P2.GetY() - P1.GetY())) << BINARY_PLACES) / area;
	  drdy = (((P3R - P1R) * (P2.GetX() - P1.GetX()) - (P2R - P1R) * (P3.GetX() - P1.GetX())) << BINARY_PLACES) / area;

	  dgdx = (((P2G - P1G) * (P3.GetY() - P1.GetY()) - (P3G - P1G) * (P2.GetY() - P1.GetY())) << BINARY_PLACES) / area;
	  dgdy = (((P3G - P1G) * (P2.GetX() - P1.GetX()) - (P2G - P1G) * (P3.GetX() - P1.GetX())) << BINARY_PLACES) / area;

	  dbdx = (((P2B - P1B) * (P3.GetY() - P1.GetY()) - (P3B - P1B) * (P2.GetY() - P1.GetY())) << BINARY_PLACES) / area;
	  dbdy = (((P3B - P1B) * (P2.GetX() - P1.GetX()) - (P2B - P1B) * (P3.GetX() - P1.GetX())) << BINARY_PLACES) / area;

      rstart = (P1R<<BINARY_PLACES);
      gstart = (P1G<<BINARY_PLACES);
      bstart = (P1B<<BINARY_PLACES);

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

/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/

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

/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/

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
    eq[2] = (short)c;  // C
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

/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/

void
Rasterizer::vertex3P(Point3D P1, Point3D P2, Point3D P3)
{
     
     TransformEngine->applyTransform(P1);
     TransformEngine->applyTransform(P2);
     TransformEngine->applyTransform(P3);          
     
     if(m_vertexSize - m_vertexCount < 9)
     {    
        float* tempArray = new float[m_vertexSize*2];
        for(int i = 0; i <m_vertexCount; i++)
        {
            tempArray[i] = m_vertexArray[i];
        }
        delete[] m_vertexArray;
        m_vertexArray = tempArray;  
        
        unsigned char* tempcArray = new unsigned char[m_vertexSize*2];
        for(int i = 0; i <m_vertexCount; i++)
        {
            tempcArray[i] = m_colorArray[i];
        } 
        delete[] m_colorArray;
        m_colorArray = tempcArray;        
               
        m_vertexSize = m_vertexSize*2;     
     }

     m_colorArray[m_vertexCount] = P1.GetR();
     m_vertexArray[m_vertexCount++] = P1.GetX();
     m_colorArray[m_vertexCount] = P1.GetG();
     m_vertexArray[m_vertexCount++] = P1.GetY();
     m_colorArray[m_vertexCount] = P1.GetB();
     m_vertexArray[m_vertexCount++] = P1.GetZ();          

     m_colorArray[m_vertexCount] = P2.GetR();
     m_vertexArray[m_vertexCount++] = P2.GetX();
     m_colorArray[m_vertexCount] = P2.GetG();     
     m_vertexArray[m_vertexCount++] = P2.GetY();
     m_colorArray[m_vertexCount] = P2.GetB();     
     m_vertexArray[m_vertexCount++] = P2.GetZ();          

     m_colorArray[m_vertexCount] = P3.GetR();
     m_vertexArray[m_vertexCount++] = P3.GetX();
     m_colorArray[m_vertexCount] = P3.GetG();     
     m_vertexArray[m_vertexCount++] = P3.GetY();
     m_colorArray[m_vertexCount] = P3.GetB();     
     m_vertexArray[m_vertexCount++] = P3.GetZ();          

}


/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/

void
Rasterizer::rasterizeArray(){

   for(unsigned int i=0; i < m_vertexCount; i+=9)   
   {
        
      P1X = m_vertexArray[i];     //  Grab the points' x,y,z values;
      P1Y = m_vertexArray[i+1];   
      P1Z = m_vertexArray[i+2]; 
      P2X = m_vertexArray[i+3];   
      P2Y = m_vertexArray[i+4];    
      P2Z = m_vertexArray[i+5]; 
      P3X = m_vertexArray[i+6];   
      P3Y = m_vertexArray[i+7];    
      P3Z = m_vertexArray[i+8]; 
      
      if((P1Z >= 0) || (P2Z >= 0) || (P3Z >= 0)) return;
      
      P1screenX = (int)(((P1X/(-P1Z))*MCORE_FOCALLENGTH) +m_dx/2);
      P1screenY = (int)(((P1Y/(-P1Z))*MCORE_FOCALLENGTH) +m_dy/2);
      P2screenX = (int)(((P2X/(-P2Z))*MCORE_FOCALLENGTH) +m_dx/2);
      P2screenY = (int)(((P2Y/(-P2Z))*MCORE_FOCALLENGTH) +m_dy/2);
      P3screenX = (int)(((P3X/(-P3Z))*MCORE_FOCALLENGTH) +m_dx/2);
      P3screenY = (int)(((P3Y/(-P3Z))*MCORE_FOCALLENGTH) +m_dy/2);

      P1fixedZ = (int)(P1Z * 4096); // 12 bits of fraction
      P2fixedZ = (int)(P2Z * 4096);
      P3fixedZ = (int)(P3Z * 4096);

      Point2D P1(P1screenX, P1screenY, P1fixedZ, m_colorArray[i], m_colorArray[i+1], m_colorArray[i+2]);  // create some 2d points, (still need to impliment z)
      Point2D P2(P2screenX, P2screenY, P2fixedZ, m_colorArray[i+3], m_colorArray[i+4], m_colorArray[i+5]);
      Point2D P3(P3screenX, P3screenY, P3fixedZ, m_colorArray[i+6], m_colorArray[i+7], m_colorArray[i+8]);

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

     
      if(maxy > m_dy) maxy = m_dy;
      if(miny < 0) miny = 0;
      
      if(maxx > m_dx) maxx = m_dx;
      if(minx < 0) minx = 0;   


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
                
                    // Hard coded 16bpp!
                    color = (red & (0x1f<<BINARY_PLACES)) << (11-BINARY_PLACES);
                    color = color | (green & (0x3f<<BINARY_PLACES)) >> (BINARY_PLACES-5);
                    color = color | (blue & (0x1f<<BINARY_PLACES)) >> (BINARY_PLACES);

                    if((y<m_dy) && (x>0) && (x < m_dx) && (y > 0)){
                      if((z) > m_pZData[y*m_dx+x]){
                          m_pZData[y*m_dx+x]=z;
                          unsigned char *p;
                          p = &m_pPixelData[(y*m_dx+x)*(m_bpp/8)];
                          *(unsigned short *)p = color;
                      } // depth
                    } // on screen
              } // inclusion test
          } // x
       } // y
    } // vertex loop
    m_vertexCount = 0;  // clear it all

} 



/***************************************************************************/
/**
 * : 
 *
 * \param  
 *
 * \return void
 **************************************************************************/

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
  
  if((P1Z >= 0) || (P2Z >= 0) || (P3Z >= 0)) return;
  
  P1screenX = (int)(((P1X/(-P1Z))*MCORE_FOCALLENGTH) +m_dx/2);
  P1screenY = (int)(((P1Y/(-P1Z))*MCORE_FOCALLENGTH) +m_dy/2);
  P2screenX = (int)(((P2X/(-P2Z))*MCORE_FOCALLENGTH) +m_dx/2);
  P2screenY = (int)(((P2Y/(-P2Z))*MCORE_FOCALLENGTH) +m_dy/2);
  P3screenX = (int)(((P3X/(-P3Z))*MCORE_FOCALLENGTH) +m_dx/2);
  P3screenY = (int)(((P3Y/(-P3Z))*MCORE_FOCALLENGTH) +m_dy/2);

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

 
  if(maxy > m_dy) maxy = m_dy;
  if(miny < 0) miny = 0;
  
  if(maxx > m_dx) maxx = m_dx;
  if(minx < 0) minx = 0;   


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
            
                // Hard coded 16bpp!
                color = (red & (0x1f<<BINARY_PLACES)) << (11-BINARY_PLACES);
                color = color | (green & (0x3f<<BINARY_PLACES)) >> (BINARY_PLACES-5);
                color = color | (blue & (0x1f<<BINARY_PLACES)) >> (BINARY_PLACES);

                if((y<m_dy) && (x>0) && (x < m_dx) && (y > 0)){
                  if((z) > m_pZData[y*m_dx+x]){
                      m_pZData[y*m_dx+x]=z;
                      unsigned char *p;
                      p = &m_pPixelData[(y*m_dx+x)*(m_bpp/8)];
                      *(unsigned short *)p = color;
                  } // depth
                } // on screen
          } // inclusion test
      } // x
   } // y
} 

