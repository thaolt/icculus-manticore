                 //////////////////////////////////////////////////////////////////////////
// Name: VGAout 
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
#include "VGAout.h"                                // class implemented


/////////////////////////////// Public ///////////////////////////////////////

//============================= Lifecycle ====================================

VGAout::VGAout(SDL_Surface *InScreen, PixelRAM *InPixels)
{
  Screen = InScreen;
  Pixels = InPixels;
//      bpp = Screen->format->BitsPerPixel;
  bpp=32;
//  cout << "Bits Per Pixel: " << bpp << endl;

}// VGAout

VGAout::VGAout(const VGAout&)
{
}// VGAout

VGAout::~VGAout()
{
}// ~VGAout


//============================= Operators ====================================

VGAout& 
VGAout::operator=(const VGAout&rhs)
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
VGAout::DrawScreen(){

 
  Uint32 color = SDL_MapRGB(Screen->format, 0x00, 0x00, 0xff); 

  if ( SDL_MUSTLOCK(Screen) ) {
    if ( SDL_LockSurface(Screen) < 0 ) {
 //     cout << "Can't lock Surface " << endl;
    }
  }


    for(Uint32 y=0 ; y < MCORE_HEIGHT ; y++){
      Uint32* color = (Uint32 *)Pixels->GetLine(y);
      for(Uint32 x=0 ; x < MCORE_WIDTH ; x++){
	DrawPixel(x,y,color[x]);
      }
    }

  if ( SDL_MUSTLOCK(Screen) ) {
    SDL_UnlockSurface(Screen);
  }
  
  SDL_UpdateRect(Screen, 0, 0, MCORE_WIDTH, MCORE_HEIGHT);

}

void
VGAout::ClearScreen(){


}
//============================= Access      ==================================
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////

void
VGAout::DrawPixel(Uint32 x, Uint32 y, Uint32 color){

  Uint8 *p = (Uint8 *)Screen->pixels + y * Screen->pitch + x*bpp/8;
   *(Uint32 *)p = color;

}
