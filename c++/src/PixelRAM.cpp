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

  PixelData = new unsigned char[MCORE_HEIGHT*MCORE_WIDTH*(bpp/8)];
  ZData = new int[MCORE_HEIGHT*MCORE_WIDTH];

  for(int i = 0 ; i < MCORE_HEIGHT*MCORE_WIDTH*(bpp/8); i+=(bpp/8)){

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

unsigned char *
PixelRAM::GetLine(int row){

  return &PixelData[row*MCORE_WIDTH*(bpp/8)];

}


//============================= Operations ===================================

void
PixelRAM::WriteData(int x, int y, int col, int depth){
  unsigned char *p;

  if(bpp == 32){
    if((y<MCORE_HEIGHT) && (x>0) && (x < MCORE_WIDTH) && (y > 0)){

        p = &PixelData[(y*MCORE_WIDTH+x)*(bpp/8)];
        *(int *)p = col;
    }
  }else if( bpp == 16 ){
    if((y<MCORE_HEIGHT) && (x>0) && (x < MCORE_WIDTH) && (y > 0)){

        p = &PixelData[(y*MCORE_WIDTH+x)*(bpp/8)];
        *(unsigned short *)p = col;

    }
  }

  ZData[(y*MCORE_WIDTH+x)]=depth; // 4 bytes for depth
}

void
PixelRAM::Blank(){
  for(int i = 0 ; i < MCORE_HEIGHT*MCORE_WIDTH*(bpp/8); i+=(bpp/8)){

    PixelData[i]=10; 
	PixelData[i+1]=10;
    if(bpp==32){
	    PixelData[i+2]=10;
    }
  }


  for(int j = 0 ; j < MCORE_HEIGHT*MCORE_WIDTH; j++){
       ZData[j] = -2000000000;
  }
}

int
PixelRAM::GetZ(int x, int y){

    return ZData[(y*MCORE_WIDTH+x)];

}

int 
PixelRAM::Getbpp(){

    return bpp;
}

//============================= Access      ==================================
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
