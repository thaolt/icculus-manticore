/* -*- Mode: C++; tab-width: 3; indent-tabs-mode: t; c-basic-offset: 3 -*- */
///////////////////////////////////////////////////////////////////////////
// Name: Transformer 
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Modifications:
//
//
///////////////////////////////////////////////////////////////////////////
#ifndef _Transformer_h_
#define _Transformer_h_

// System Includes
//

// Project Includes
//
#include "Point3D.h"
//#include "Point3Dx.h"
#include "mcore_defs.h"
// Local Includes
//

// Forward References
//

/**   
  *    @author 
  *    @date 
  */
class Transformer
{
public:

// Lifecycle

   Transformer();
   Transformer(const Transformer&);            // copy constructor
   ~Transformer();

// Operator
   
   Transformer&   operator=(const Transformer&);     // assignment operator

// Operations

	void RotateX(Point3D &pnt, float angle );
//	void RotateXx(Point3Dx &pnt, float angle );
	void RotateY(Point3D &pnt, float angle );
	void RotateZ(Point3D &pnt, float angle );
	void Translatef(Point3D &pnt, float dx, float dy, float dz);
//	void Translatex(Point3Dx &pnt, fixed1616 dx, fixed1616 dy, fixed1616 dz);
	void Scale(Point3D &pnt, float factor );

// Access

// Inquiry

protected:
// Protected Methods
private:
// Private Methods


//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Transformer_h
