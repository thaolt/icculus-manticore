//////////////////////////////////////////////////////////////////////////
// Name: PixelRAM 
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
#include "PixelRAM.h"                                // class implemented


/////////////////////////////// Public ///////////////////////////////////////

//============================= Lifecycle ====================================

PixelRAM::PixelRAM(const int& bppin)
{
  bpp = bppin;  // bits per pixel

  PixelData = new Uint8[MCORE_HEIGHT*MCORE_WIDTH*(bpp/8)];
  for(Uint32 i = 0 ; i < MCORE_HEIGHT*MCORE_WIDTH*(bpp/8); i+=(bpp/8)){
    int row = i/(MCORE_WIDTH*(bpp/8));

    PixelData[i]=255;  // This garbage is for loving memories
    PixelData[i+1]=255;

    if(bpp == 32){
         PixelData[i+2]=255;
    }

  }

}// PixelRAM

PixelRAM::PixelRAM(const PixelRAM&)
{
}// PixelRAM

PixelRAM::~PixelRAM()
{
}// ~PixelRAM


//============================= Operators ====================================

PixelRAM& 
PixelRAM::operator=(const PixelRAM &rhs)
{
   if ( this==&rhs ) {
        return *this;
    }
    //superclass::operator =(rhs);

    //add local assignments

    return *this;

}// =

Uint8 *
PixelRAM::GetLine(Uint32 row){

  return &PixelData[row*MCORE_WIDTH*(bpp/8)];

}


//============================= Operations ===================================

void
PixelRAM::WriteData(Uint32 x, Uint32 y, Uint32 col){
  Uint8 *p;

  if(bpp == 32){
    if((y<MCORE_HEIGHT) && (x>0) && (x < MCORE_WIDTH) && (y > 0)){

        p = &PixelData[(y*MCORE_WIDTH+x)*(bpp/8)];
        *(Uint32 *)p = col;
    }
  }else if( bpp == 16 ){

        p = &PixelData[(y*MCORE_WIDTH+x)*(bpp/8)];
        *(Uint16 *)p = col;
  }

}

void
PixelRAM::Blank(){


  for(Uint32 i = 0 ; i < MCORE_HEIGHT*MCORE_WIDTH*(bpp/8); i+=(bpp/8)){
    int row = i/(MCORE_WIDTH*(bpp/8));
    PixelData[i]=80; 
	PixelData[i+1]=80;
    if(bpp==32){
	    PixelData[i+2]=80;
    }
  }

}

int 
PixelRAM::Getbpp(){

    return bpp;
}

//============================= Access      ==================================
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
