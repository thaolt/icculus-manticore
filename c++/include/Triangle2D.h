/* -*- Mode: C++; tab-width: 3; indent-tabs-mode: t; c-basic-offset: 3 -*- */
///////////////////////////////////////////////////////////////////////////
// Name: Triangle2D 
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Modifications:
//
//
///////////////////////////////////////////////////////////////////////////
#ifndef _Triangle2D_h_
#define _Triangle2D_h_

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
class Triangle2D
{
public:

// Lifecycle

   Triangle2D();
	Triangle2D(const Point2D& inp1, const Point2D& inp2, const Point2D& inp3);
   Triangle2D(const Triangle2D&);            // copy constructor
   ~Triangle2D();

// Operator
   
   Triangle2D&   operator=(const Triangle2D&);     // assignment operator

// Operations

// Access

// Inquiry

protected:
// Protected Methods
private:

	Point2D p1;
	Point2D p2;
	Point2D p3;

	
// Private Methods


//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Triangle2D_h
