/* -*- Mode: C++; tab-width: 3; indent-tabs-mode: t; c-basic-offset: 3 -*- */
///////////////////////////////////////////////////////////////////////////
// Name: Triangle3D 
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Modifications:
//
//
///////////////////////////////////////////////////////////////////////////
#ifndef _Triangle3D_h_
#define _Triangle3D_h_

// System Includes
//

// Project Includes
//
#include "Point3D.h"
#include "Point2D.h"
// Local Includes
//

// Forward References
//

/**   
  *    @author 
  *    @date 
  */
class Triangle3D
{
public:

// Lifecycle

    Triangle3D();
    Triangle3D(const Point3D& inp1, const Point3D& inp2, const Point3D& inp3);
    Triangle3D(const Triangle3D&);            // copy constructor
   ~Triangle3D();

// Operator
   
   Triangle3D&   operator=(const Triangle3D&);     // assignment operator

// Operations
    void SetPoints(const Point3D& inp1, const Point3D& inp2, const Point3D& inp3);
// Access

    Point3D GetP3D1();
    Point3D GetP3D2();
    Point3D GetP3D3();
// Inquiry

protected:
// Protected Methods
private:

    Point3D P3D1;
    Point3D P3D2;
    Point3D P3D3;

// Private Methods


//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Triangle3D_h
