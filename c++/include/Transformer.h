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
    void loadIdentity();
    void translate3f(const float& x, const float& y, const float& z);
    void rotate3f(const float& angle, const float& x, const float& y, const float& z);
    void applyTransform(Point3D &pnt);
    
    // old interface
	void RotateX(Point3D &pnt, float angle );
	void RotateY(Point3D &pnt, float angle );
	void RotateZ(Point3D &pnt, float angle );
	void Translatef(Point3D &pnt, float dx, float dy, float dz);
	void Scale(Point3D &pnt, float factor );

// Access

// Inquiry

protected:
// Protected Methods
private:
// Private Methods
   
   void applyTempMatrix();

   float m_tMatrix[4][4];
   float m_tempMatrix[4][4];
//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Transformer_h
