/* -*- Mode: C++; tab-width: 3; indent-tabs-mode: t; c-basic-offset: 3 -*- */
///////////////////////////////////////////////////////////////////////////
// Name: Rasterizer 
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Modifications:
//
//
///////////////////////////////////////////////////////////////////////////
#ifndef _Rasterizer_h_
#define _Rasterizer_h_

// System Includes
//

//#include "SDL.h"

// Project Includes
//
#include "Point3D.h"
#include "Point2D.h"
#include "Triangle3D.h"
#include "Triangle3Dx.h"
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
class Rasterizer
{
public:

// Lifecycle

   Rasterizer(PixelRAM*);
   Rasterizer(const Rasterizer&);            // copy constructor
   ~Rasterizer();

// Operator
   
   Rasterizer&   operator=(const Rasterizer&);     // assignment operator

// Operations

	void Rasterize(Triangle3D &);
	void Rasterizex(Triangle3Dx &);
// Access

// Inquiry

protected:
// Protected Methods
private:
// Private Methods

  void s3dGetColorDeltas(Point2D& P1, Point2D& P2, Point2D& P3, short* colors);
  void s3dGetZDeltas(Point2D& P1, Point2D& P2, Point2D& P3, int* z);
  void s3dGetLineEq(Point2D& P1, Point2D& P2, short* eq);

//  SDL_Surface* Screen;
  PixelRAM* PixelData;

   Point2D P2D_world1;
   Point2D P2D_world2;
   Point2D P2D_world3;

  Point3D P3D1, P3D2, P3D3;
  float P1X, P1Y, P1Z;
  float P2X, P2Y, P2Z;
  float P3X, P3Y, P3Z;
  fixed1616 P1Xx, P1Yx, P1Zx;
  fixed1616 P2Xx, P2Yx, P2Zx;
  fixed1616 P3Xx, P3Yx, P3Zx;

  int P1screenX, P1screenY;
  int P2screenX, P2screenY;
  int P3screenX, P3screenY;
  int P1fixedZ, P2fixedZ, P3fixedZ;

//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Rasterizer_h

