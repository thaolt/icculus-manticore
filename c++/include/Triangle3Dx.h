/* -*- Mode: C++; tab-width: 3; indent-tabs-mode: t; c-basic-offset: 3 -*- */
///////////////////////////////////////////////////////////////////////////
// Name: Triangle3Dx 
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Modifications:
//
//
///////////////////////////////////////////////////////////////////////////
#ifndef _Triangle3Dx_h_
#define _Triangle3Dx_h_

// System Includes
//

// Project Includes
//
#include "Point3Dx.h"
#include "Point2D.h"
// Local Includes
//

// Forward References
//

/**   
  *    @author 
  *    @date 
  */
class Triangle3Dx
{
public:

// Lifecycle

    Triangle3Dx();
    Triangle3Dx(const Point3Dx& inp1, const Point3Dx& inp2, const Point3Dx& inp3);
    Triangle3Dx(const Triangle3Dx&);            // copy constructor
   ~Triangle3Dx();

// Operator
   
   Triangle3Dx&   operator=(const Triangle3Dx&);     // assignment operator

// Operations
    void SetPoints(const Point3Dx& inp1, const Point3Dx& inp2, const Point3Dx& inp3);
// Access

    Point3Dx GetP3D1();
    Point3Dx GetP3D2();
    Point3Dx GetP3D3();
// Inquiry

protected:
// Protected Methods
private:

    Point3Dx P3D1;
    Point3Dx P3D2;
    Point3Dx P3D3;

// Private Methods


//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Triangle3Dx_h
