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

#include "SDL.h"

// Project Includes
//
#include "Point3D.h"
#include "Point2D.h"
#include "Triangle2D.h"
#include "Triangle3D.h"
#include "PixelRAM.h"

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

   Rasterizer(SDL_Surface *, PixelRAM*);
   Rasterizer(const Rasterizer&);            // copy constructor
   ~Rasterizer();

// Operator
   
   Rasterizer&   operator=(const Rasterizer&);     // assignment operator

// Operations

	void Rasterize(Triangle3D &);
	void Rasterize2(Triangle3D &);
// Access

// Inquiry

protected:
// Protected Methods
private:
// Private Methods

  void s3dGetColorDeltas(Point2D& P1, Point2D& P2, Point2D& P3, short* colors);
  void s3dGetLineEq(Point2D& P1, Point2D& P2, short* eq);

  SDL_Surface* Screen;
  PixelRAM* PixelData;

   Point2D P2D_world1;
   Point2D P2D_world2;
   Point2D P2D_world3;

  Point3D P3D1, P3D2, P3D3;
  float P1X, P1Y, P1Z;
  float P2X, P2Y, P2Z;
  float P3X, P3Y, P3Z;
  float P1screenX, P1screenY;
  float P2screenX, P2screenY;
  float P3screenX, P3screenY;
  float l, r;
  float dxleft, dxright, dxclose;
  bool degenerate;
  float slopeleft, sloperight, slopeclose, dy;
  Point2D middle, bottom, top, left, right;

//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Rasterizer_h