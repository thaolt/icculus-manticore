/* -*- Mode: C++; tab-width: 3; indent-tabs-mode: t; c-basic-offset: 3 -*- */
///////////////////////////////////////////////////////////////////////////
// Name: PixelRAM 
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Modifications:
//
//
///////////////////////////////////////////////////////////////////////////
#ifndef _PixelRAM_h_
#define _PixelRAM_h_

// System Includes
//
#include <iostream>
// Project Includes
//

#include "mcore_defs.h"

// Local Includes
//

// Forward References
//
using namespace std;

/**   
  *    @author 
  *    @date 
  */
class PixelRAM
{
public:

// Lifecycle

   PixelRAM(const int& bppin);
   PixelRAM(const PixelRAM&);            // copy constructor
   ~PixelRAM();

// Operator
   
   PixelRAM&   operator=(const PixelRAM&);     // assignment operator

// Operations
	void WriteData(Uint32 x, Uint32 y, Uint32 col);
	void Blank();

// Access
	Uint8* GetLine(Uint32 row);
    int Getbpp();
// Inquiry

protected:
// Protected Methods
private:
// Private Methods

	Uint8 *PixelData;
    int bpp;

//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _PixelRAM_h
