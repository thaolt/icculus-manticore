
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
#include "Timer.h"

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
  m_pContext    = context;
  m_pPixelData  = (unsigned char*)(context->drawDesc->colorBuffer);
  m_pZData      = (int*)(context->drawDesc->depthBuffer);
  m_dx          = context->drawDesc->width;
  m_dy          = context->drawDesc->height;
  m_bpp         = 8*context->drawDesc->colorBytes;
  
  m_colors      = new short[9];  // short arrays for SIMD array
  m_eq          = new short[9];
  m_zslopes     = new int[3];
  
  m_vertexCount = 0;
  m_vertexSize  = VERTEX_START_SIZE;
  m_pVertexArray = new float[VERTEX_START_SIZE];
  m_pColorArray  = new unsigned char[VERTEX_START_SIZE];

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

  delete[] m_colors;
  delete[] m_eq;
  delete[] m_zslopes;
  delete[] m_pVertexArray;
  delete[] m_pColorArray;  
  delete   TransformEngine;
  
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

  m_pPixelData  = (unsigned char*)(m_pContext->drawDesc->colorBuffer); 
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
Rasterizer::s3dGetColorDeltas(Point2D& P1, Point2D& P2, Point2D& P3, short* m_colors){
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
              m_colors[i]=0;
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

      m_colors[0]=(short)drdx;
      m_colors[1]=(short)drdy;
      m_colors[2]=(short)dgdx;
      m_colors[3]=(short)dgdy;
      m_colors[4]=(short)dbdx;
      m_colors[5]=(short)dbdy;
      m_colors[6]=(short)rstart;
      m_colors[7]=(short)gstart;
      m_colors[8]=(short)bstart;

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
Rasterizer::s3dGetZDeltas(Point2D& P1, Point2D& P2, Point2D& P3, int* m_zslopes){

  int dzdx, dzdy, area;
  int zstart;

  area = ((P2.GetX() - P1.GetX()) * (P3.GetY() - P1.GetY()) - (P2.GetY() - P1.GetY()) * (P3.GetX() - P1.GetX()));
  // Find the red slopes, 8 binary places after point

   if(area == 0){
       for(int i=0; i<3; i++){
           m_zslopes[i]=0;
           return;
       }
   }

  dzdx = (((P2.GetZ() - P1.GetZ()) * (P3.GetY() - P1.GetY()) - (P3.GetZ() - P1.GetZ()) * (P2.GetY() - P1.GetY()))) / area;
  dzdy = (((P3.GetZ() - P1.GetZ()) * (P2.GetX() - P1.GetX()) - (P2.GetZ() - P1.GetZ()) * (P3.GetX() - P1.GetX()))) / area;

  zstart = (P1.GetZ());

  m_zslopes[0]=dzdx;
  m_zslopes[1]=dzdy;
  m_zslopes[2]=zstart;

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
            tempArray[i] = m_pVertexArray[i];
        }
        delete[] m_pVertexArray;
        m_pVertexArray = tempArray;  
        
        unsigned char* tempcArray = new unsigned char[m_vertexSize*2];
        for(int i = 0; i <m_vertexCount; i++)
        {
            tempcArray[i] = m_pColorArray[i];
        } 
        delete[] m_pColorArray;
        m_pColorArray = tempcArray;        
               
        m_vertexSize = m_vertexSize*2;     
     }

     m_pColorArray[m_vertexCount] = P1.GetR();
     m_pVertexArray[m_vertexCount++] = P1.GetX();
     m_pColorArray[m_vertexCount] = P1.GetG();
     m_pVertexArray[m_vertexCount++] = P1.GetY();
     m_pColorArray[m_vertexCount] = P1.GetB();
     m_pVertexArray[m_vertexCount++] = P1.GetZ();          

     m_pColorArray[m_vertexCount] = P2.GetR();
     m_pVertexArray[m_vertexCount++] = P2.GetX();
     m_pColorArray[m_vertexCount] = P2.GetG();     
     m_pVertexArray[m_vertexCount++] = P2.GetY();
     m_pColorArray[m_vertexCount] = P2.GetB();     
     m_pVertexArray[m_vertexCount++] = P2.GetZ();          

     m_pColorArray[m_vertexCount] = P3.GetR();
     m_pVertexArray[m_vertexCount++] = P3.GetX();
     m_pColorArray[m_vertexCount] = P3.GetG();     
     m_pVertexArray[m_vertexCount++] = P3.GetY();
     m_pColorArray[m_vertexCount] = P3.GetB();     
     m_pVertexArray[m_vertexCount++] = P3.GetZ();          

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
Rasterizer::rasterizeArray()
{

    unsigned char *p;

    int crossz;

    int red, green, blue;
          
    short yrstart, ybstart, ygstart;
    int color;

    int z, yzstart;

    short eq1result, eq1temp;
    short eq2result, eq2temp;
    short eq3result, eq3temp;
          
    short miny, minx, maxy, maxx;

          int time1;
          int time2; 
          int delta;
      
       TimerInit(TIMER_ID_TWO);
       TimerResetRealTime(TIMER_ID_TWO);          
                
       for(unsigned int i=0; i < m_vertexCount; i+=9)   
       {
            
          m_P1X = m_pVertexArray[i];     //  Grab the points' x,y,z values;
          m_P1Y = m_pVertexArray[i+1];   
          m_P1Z = m_pVertexArray[i+2]; 
          m_P2X = m_pVertexArray[i+3];   
          m_P2Y = m_pVertexArray[i+4];    
          m_P2Z = m_pVertexArray[i+5]; 
          m_P3X = m_pVertexArray[i+6];   
          m_P3Y = m_pVertexArray[i+7];    
          m_P3Z = m_pVertexArray[i+8]; 
          
          if((m_P1Z >= 0) || (m_P2Z >= 0) || (m_P3Z >= 0)) break;
          
          m_P1screenX = (int)(((m_P1X/(-m_P1Z))*MCORE_FOCALLENGTH) +m_dx/2);  // camera projection
          m_P1screenY = (int)(((m_P1Y/(-m_P1Z))*MCORE_FOCALLENGTH) +m_dy/2);
          m_P2screenX = (int)(((m_P2X/(-m_P2Z))*MCORE_FOCALLENGTH) +m_dx/2);
          m_P2screenY = (int)(((m_P2Y/(-m_P2Z))*MCORE_FOCALLENGTH) +m_dy/2);
          m_P3screenX = (int)(((m_P3X/(-m_P3Z))*MCORE_FOCALLENGTH) +m_dx/2);
          m_P3screenY = (int)(((m_P3Y/(-m_P3Z))*MCORE_FOCALLENGTH) +m_dy/2);

          m_P1fixedZ = (int)(m_P1Z * 4096); // 12 bits of fraction
          m_P2fixedZ = (int)(m_P2Z * 4096);
          m_P3fixedZ = (int)(m_P3Z * 4096);

          Point2D P1(m_P1screenX, m_P1screenY, m_P1fixedZ, m_pColorArray[i], m_pColorArray[i+1], m_pColorArray[i+2]);  // create some 2d points, (still need to impliment z)
          Point2D P2(m_P2screenX, m_P2screenY, m_P2fixedZ, m_pColorArray[i+3], m_pColorArray[i+4], m_pColorArray[i+5]);
          Point2D P3(m_P3screenX, m_P3screenY, m_P3fixedZ, m_pColorArray[i+6], m_pColorArray[i+7], m_pColorArray[i+8]);

          s3dGetColorDeltas(P1,P2,P3, m_colors);   // short array pointers are used to load the SIMD array
                                                 // kept here for consistency
          s3dGetZDeltas(P1,P2,P3, m_zslopes);

          Point2D *Sorted1, *Sorted2, *Sorted3;

          // Use cross product to make sure triangle orientation is correct
          // Rz = PxQy - PyQx;   P = P1-P2, Q=P1-P3
          crossz = (P1.GetX() - P2.GetX())*(P1.GetY() - P3.GetY()) - (P1.GetY() - P2.GetY())*(P1.GetX()-P3.GetX());
          
          if(crossz >= 0)
          {
            Sorted1 = &P1;
            Sorted2 = &P2;
            Sorted3 = &P3;
          }else{
            Sorted1 = &P3;
            Sorted2 = &P2;
            Sorted3 = &P1;
          }

          s3dGetLineEq( *Sorted2, *Sorted1, m_eq); 
          s3dGetLineEq( *Sorted3, *Sorted2, m_eq+3);
          s3dGetLineEq( *Sorted1, *Sorted3, m_eq+6);

          miny = min(P1.GetY(),P2.GetY());
          miny = min(miny,     P3.GetY());
          minx = min(P1.GetX(),P2.GetX());
          minx = min(minx,     P3.GetX());

          maxy = max(P1.GetY(),P2.GetY());
          maxy = max(maxy,     P3.GetY());
          maxx = max(P1.GetX(),P2.GetX());
          maxx = max(maxx,     P3.GetX());

          if(maxy >= m_dy) maxy = m_dy-1;
          if(miny < 0) miny = 0;
          
          if(maxx >= m_dx) maxx = m_dx-1;
          if(minx < 0) minx = 0;   

          yrstart =  (P1.GetR()<<BINARY_PLACES) + ((maxx+1)-P1.GetX())*m_colors[0] + ((maxy+1)-P1.GetY())*m_colors[1];
          ygstart =  (P1.GetG()<<BINARY_PLACES) + ((maxx+1)-P1.GetX())*m_colors[2] + ((maxy+1)-P1.GetY())*m_colors[3];
          ybstart =  (P1.GetB()<<BINARY_PLACES) + ((maxx+1)-P1.GetX())*m_colors[4] + ((maxy+1)-P1.GetY())*m_colors[5];

          yzstart =  (P1.GetZ()) + ((maxx+1)-P1.GetX())*m_zslopes[0] + ((maxy+1)-P1.GetY())*m_zslopes[1];

          eq1temp = m_eq[0]*(maxx+1) + m_eq[1]*(maxy+1) - m_eq[2]; 
          eq2temp = m_eq[3]*(maxx+1) + m_eq[4]*(maxy+1) - m_eq[5];
          eq3temp = m_eq[6]*(maxx+1) + m_eq[7]*(maxy+1) - m_eq[8];

          
          
          for(int y = maxy; y >= miny; y--)
          { 
              eq1temp -= m_eq[1];
              eq2temp -= m_eq[4];
              eq3temp -= m_eq[7];

              eq1result = eq1temp;
              eq2result = eq2temp;
              eq3result = eq3temp;

              yrstart -= m_colors[1];
              red = yrstart;
            
              ygstart -= m_colors[3];
              green = ygstart;
             
              ybstart -= m_colors[5];
              blue = ybstart;
             
              yzstart -= m_zslopes[1];
              z = yzstart;

              for(int x = maxx; x >= minx; x--)
              {
                 eq1result -= m_eq[0];
                 eq2result -= m_eq[3];
                 eq3result -= m_eq[6];

                 red   -= m_colors[0];             
                 green -= m_colors[2];
                 blue  -= m_colors[4];             
                 z     -= m_zslopes[0];        

                 if( z > m_pZData[y*m_dx+x])
                 {             
                   if(  (eq1result <= 0)
                     && (eq2result <= 0)
                     && (eq3result <= 0) )
                     {
                        // Hard coded 16bpp!
                        color = (red   & (0x1f<<BINARY_PLACES)) << (11-BINARY_PLACES)
                              | (green & (0x3f<<BINARY_PLACES)) >> (BINARY_PLACES-5)
                              | (blue  & (0x1f<<BINARY_PLACES)) >> (BINARY_PLACES);                        
                        
                        m_pZData[y*m_dx+x]=z;
                        m_pPixelData  = (unsigned char*)(m_pContext->drawDesc->colorBuffer);                                         
                        p = &m_pPixelData[(y*m_dx+x)*(m_bpp/8)];
                        *(unsigned short *)p = color;

                     } // inclusion test
                 } // depth test
              } // x
           } // y
       
   
         
       } // vertex loop  
       
       TimerReadTime(TIMER_ID_TWO);

       m_vertexCount = 0;  // clear it all  

} 



