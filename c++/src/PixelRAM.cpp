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

PixelRAM::PixelRAM()
{

  PixelData = new Uint8[MCORE_HEIGHT*MCORE_WIDTH*MCORE_BYTESPERPIXEL];
  for(Uint32 i = 0 ; i < MCORE_HEIGHT*MCORE_WIDTH*MCORE_BYTESPERPIXEL; i+=MCORE_BYTESPERPIXEL){
    int row = i/(MCORE_WIDTH*MCORE_BYTESPERPIXEL);
    PixelData[i]=255;  // This garbage is for loving memories
    if(row < 60){
      PixelData[i+1]=0; 
      PixelData[i+2]=0;  
    }else if(row<120){
      PixelData[i+1]=64; 
      PixelData[i+2]=64;  
    }else if(row<180){
      PixelData[i+1]=96; 
      PixelData[i+2]=96;  
    }else if(row<240){
      PixelData[i+1]=128; 
      PixelData[i+2]=128;  
    }else if(row<300){
      PixelData[i+1]=160; 
      PixelData[i+2]=160;  
    }else if(row<360){
      PixelData[i+1]=192; 
      PixelData[i+2]=192;  
    }else if(row<420){
      PixelData[i+1]=224; 
      PixelData[i+2]=224;  
    }else if(row<480){
      PixelData[i+1]=255; 
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

  return &PixelData[row*MCORE_WIDTH*MCORE_BYTESPERPIXEL];

}


//============================= Operations ===================================

void
PixelRAM::WriteData(Uint32 x, Uint32 y, Uint32 col){
  Uint8 *p;
  if((y<MCORE_HEIGHT) && (x>0) && (x < MCORE_WIDTH) && (y > 0)){
  //  cout << x <<"," << y <<","<< col << endl;
    p = &PixelData[(y*MCORE_WIDTH+x)*MCORE_BYTESPERPIXEL];
    *(Uint32 *)p = col;
  }
}

void
PixelRAM::Blank(){


  for(Uint32 i = 0 ; i < MCORE_HEIGHT*MCORE_WIDTH*MCORE_BYTESPERPIXEL; i+=MCORE_BYTESPERPIXEL){
    int row = i/(MCORE_WIDTH*MCORE_BYTESPERPIXEL);
    PixelData[i]=80;  // This garbage is for loving memories
	PixelData[i+1]=80;
	PixelData[i+2]=80;

  }


}

//============================= Access      ==================================
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
