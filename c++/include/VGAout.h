/* -*- Mode: C++; tab-width: 3; indent-tabs-mode: t; c-basic-offset: 3 -*- */
///////////////////////////////////////////////////////////////////////////
// Name: VGAout 
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Modifications:
//
//
///////////////////////////////////////////////////////////////////////////
#ifndef _VGAout_h_
#define _VGAout_h_


// System Includes
//

#include "SDL.h"
#include <iostream>
// Project Includes
//

#include "PixelRAM.h"
#include "mcore_defs.h"

// Local Includes
//

// Forward References
//

/**   
  *    @author 
  *    @date 
  */
using namespace std;

class VGAout
{
public:

// Lifecycle

   VGAout(SDL_Surface *, PixelRAM* Pixels);
   VGAout(const VGAout&);            // copy constructor
   ~VGAout();

// Operator
   
   VGAout&   operator=(const VGAout&);     // assignment operator

// Operations

	void DrawScreen();
	void ClearScreen();
	
// Access

// Inquiry

protected:
// Protected Methods
private:
// Private Methods

   void DrawPixel(Uint32 x, Uint32 y, Uint32 color);

	SDL_Surface *Screen;
	PixelRAM *Pixels;
	Uint32 bpp;

//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _VGAout_h
