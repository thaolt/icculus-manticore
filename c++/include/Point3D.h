/* -*- Mode: C++; tab-width: 3; indent-tabs-mode: t; c-basic-offset: 3 -*- */
///////////////////////////////////////////////////////////////////////////
// Name: Point3D 
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Modifications:
//
//
///////////////////////////////////////////////////////////////////////////
#ifndef _Point3D_h_
#define _Point3D_h_

// System Includes
//
#include <iostream>
// Project Includes
//

// Local Includes
//

// Forward References
//

/**   
  *    @author 
  *    @date 
  */
using namespace std;

class Point3D
{
public:

// Lifecycle

   Point3D();
	Point3D(const double& x, const double& y, const double& z);
   Point3D(const Point3D&);            // copy constructor
   ~Point3D();

// Operator
   
   Point3D&   operator=(const Point3D&);     // assignment operator

// Operations

// Access
	const double& GetX()const;
	const double& GetY()const;
	const double& GetZ()const;
// Inquiry

protected:
// Protected Methods
private:

// Private Methods
	double x;
	double y;
	double z;

//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Point3D_h
