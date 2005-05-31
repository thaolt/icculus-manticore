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
#include "mcore_defs.h"
#include "mcore_types.h"
#include "Transformer.h"

class Rasterizer
{
public:

// Lifecycle

   Rasterizer(mcContext* context);
   Rasterizer(const Rasterizer&);    // copy constructor
   ~Rasterizer();
   
   Rasterizer&   operator=(const Rasterizer&);    
   
   void rasterizeArray();
   void vertex3P(Point3D P1, Point3D P2, Point3D P3);
   void blank();

   Transformer* TransformEngine;


protected:
// Protected Methods
private:
// Private Methods

  void s3dGetColorDeltas(Point2D& P1, Point2D& P2, Point2D& P3, short* colors);
  void s3dGetZDeltas(Point2D& P1, Point2D& P2, Point2D& P3, int* z);
  void s3dGetLineEq(Point2D& P1, Point2D& P2, short* eq);

  float*         m_pVertexArray;
  unsigned char* m_pColorArray;
  unsigned int   m_vertexCount;
  unsigned int   m_vertexSize;

  mcContext*    m_pContext;  
  unsigned char* m_pPixelData;
  int*           m_pZData;
  
  int            m_dx;
  int            m_dy;
  int            m_bpp;

  short*         m_colors;
  short*         m_eq;
  int*           m_zslopes;

  float          m_P1X, m_P1Y, m_P1Z;
  float          m_P2X, m_P2Y, m_P2Z;
  float          m_P3X, m_P3Y, m_P3Z;

  int            m_P1screenX, m_P1screenY;
  int            m_P2screenX, m_P2screenY;
  int            m_P3screenX, m_P3screenY;
  int            m_P1fixedZ, m_P2fixedZ, m_P3fixedZ;

};

// Inline Methods
//
// External References
//

#endif  // _Rasterizer_h

