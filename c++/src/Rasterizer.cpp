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

  Uint32 col1 = 255<<8;               // green
  Uint32 col2 = (255<<16)+(255<<8);   // yellow
  Uint32 col3 = 255<<16;              // red
  Uint32 col4 = col3 - (63<<16);            //orange
  // Slope Calculations
  
  // Handle degenerate cases first
  if(P1screenY == P2screenY){
      degenerate=true;
      if(P3screenY > P1screenY){  // 3rd point below
          top=P1;  middle=P3; bottom=P3; left=P3; right=P3;
          if(P1screenX < P2screenX){
            l=P2screenX; 
            r=P1screenX;
          }else{
            r=P2screenX; 
            l=P1screenX;
          }
          dxleft = l - left.GetX();
          dxright = r - right.GetX();
      }else{   // 3rd point above
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

  else if(P1screenY == P3screenY){
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

  else if(P2screenY == P3screenY){
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

  if(!degenerate){
    dxleft = top.GetX() - left.GetX();
    dxright = top.GetX() - right.GetX();
    dxclose = middle.GetX() - bottom.GetX();
    l=top.GetX();
    r=top.GetX();
    dy = middle.GetY()-bottom.GetY();
    slopeclose = (int)dxclose/dy;
  }

  dy = top.GetY()-left.GetY();
  slopeleft = (int)dxleft/dy;

  dy = top.GetY()-right.GetY();
  sloperight = (int)dxright/dy;


  float temp;
  // In some orientations the left and right edges are swapped
  //  definitions of l and r are not really accurate
  if(slopeleft < sloperight){  
       temp=slopeleft;
       slopeleft=sloperight;
       sloperight=temp;
   }

  for(Uint32 i=(Uint32)top.GetY(); i < (Uint32)middle.GetY(); i++){
      l+=slopeleft;
      r+=sloperight;
      
      for(Uint32 j=(Uint32)r; j<(Uint32)l; j++){
         PixelData->WriteData((Uint32)j,i, col4);
      }    
  }

   if(fabs(r - middle.GetX()) < fabs(l - middle.GetX())){
       r=middle.GetX();
       sloperight=slopeclose;
   }else{
       l=middle.GetX();
       slopeleft=slopeclose;
   }

  for(Uint32 i=(Uint32)middle.GetY(); i < (Uint32)bottom.GetY(); i++){
      l+=slopeleft;
      r+=sloperight;
      for(Uint32 j=(Uint32)r; j<(Uint32)l; j++){
         PixelData->WriteData((Uint32)j,i, col4);
      }     
  }

  for(int i=-1; i < 1; i++){
    for(int j=-1; j <1; j++){
      PixelData->WriteData((Uint32)P1.GetX()+i,(Uint32)P1.GetY()+j, col1);
      PixelData->WriteData((Uint32)P2.GetX()+i,(Uint32)P2.GetY()+j, col2);
      PixelData->WriteData((Uint32)P3.GetX()+i,(Uint32)P3.GetY()+j, col3);
    }
  }
}

