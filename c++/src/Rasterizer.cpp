//////////////////////////////////////////////////////////////////////////
// Name: Rasterizer 
//
// Files:
// Bugs:
// See Also:
// Type: C++-Source
//////////////////////////////////////////////////////////////////////////
// Authors:
// Date:
//////////////////////////////////////////////////////////////////////////
// Modifications:
//
/////////////////////////////////////////////////////////////////////////
#include "Rasterizer.h"                                // class implemented


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

  Point3D P3D1, P3D2, P3D3;
  double P1X, P1Y, P1Z;
  double P2X, P2Y, P2Z;
  double P3X, P3Y, P3Z;
  double P1screenX, P1screenY;
  double P2screenX, P2screenY;
  double P3screenX, P3screenY;
  double slope1, slope2, slope3;

  P3D1 = tri.GetP3D1();
  P3D2 = tri.GetP3D2();
  P3D3 = tri.GetP3D3();
  P1X = P3D1.GetX();  
  P1Y = P3D1.GetY();   P1Z = P3D1.GetZ();
  P2X = P3D2.GetX();  
  P2Y = P3D2.GetY();   P2Z = P3D2.GetZ();
  P3X = P3D3.GetX();  
  P3Y = P3D3.GetY();   P3Z = P3D3.GetZ();
  
  P1screenX = P1X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P1Z) +MCORE_WIDTH/2;
  P1screenY = P1Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P1Z) +MCORE_HEIGHT/2;
  P2screenX = P2X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P2Z) +MCORE_WIDTH/2;
  P2screenY = P2Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P2Z) +MCORE_HEIGHT/2;
  P3screenX = P3X*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P3Z) +MCORE_WIDTH/2;
  P3screenY = P3Y*MCORE_FOCALLENGTH/(MCORE_FOCALLENGTH-P3Z) +MCORE_HEIGHT/2;

  Point2D P1(P1screenX, P1screenY);
  Point2D P2(P2screenX, P2screenY);
  Point2D P3(P3screenX, P3screenY);

  //  cout << "Output: "<<P1screenX << "," <<P1screenY <<endl;
  //  cout << "Output: "<<P2screenX << "," <<P2screenY << endl;
  //  cout << "Output: "<<P3screenX << "," <<P3screenY << endl;

  Uint32 col1 = 255<<8;
  Uint32 col2 = (255<<16)+(255<<8);
  Uint32 col3 = 255<<16;

  // Slope Calculations

  Point2D topY, leftX, rightX;
  
  if((P1screenY > P2screenY) && (P1screenY > P3screenY)){
    topY = P1;
  }

  if((P2screenY > P1screenY) && (P2screenY > P3screenY)){
    topY = P2;
  }

  if((P3screenY > P2screenY) && (P3screenY > P1screenY)) {
    topY = P3;
  }

  PixelData->Blank();
  for(int i=-3; i < 4; i++){
    for(int j=-3; j <4; j++){
      PixelData->WriteData((Uint32)P1.GetX()+i,(Uint32)P1.GetY()+j, col1);
      PixelData->WriteData((Uint32)P2.GetX()+i,(Uint32)P2.GetY()+j, col2);
      PixelData->WriteData((Uint32)P3.GetX()+i,(Uint32)P3.GetY()+j, col3);
    }
  }
}

//============================= Access      ==================================
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
