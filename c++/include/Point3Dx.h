/* -*- Mode: C++; tab-width: 3; indent-tabs-mode: t; c-basic-offset: 3 -*- */
///////////////////////////////////////////////////////////////////////////
// Name: Point3Dx 
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Modifications:
//
//
///////////////////////////////////////////////////////////////////////////
#ifndef _Point3Dx_h_
#define _Point3Dx_h_

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

/**   
  *    @author 
  *    @date 
  */
//using namespace std;

class Point3Dx
{
public:

// Lifecycle

   Point3Dx();
    Point3Dx(const fixed1616& x, const fixed1616& y, const fixed1616& z);
    Point3Dx(const fixed1616& x, const fixed1616& cy, const fixed1616& z, const int& r, const int& g, const int& b);
    Point3Dx(const Point3Dx&);            // copy constructor
   ~Point3Dx();

// Operator
   
   Point3Dx&   operator=(const Point3Dx&);     // assignment operator

// Operations

// Access
    const fixed1616& GetX()const;
    const fixed1616& GetY()const;
    const fixed1616& GetZ()const;
    const int& GetR()const;
    const int& GetG()const;
    const int& GetB()const;

    void SetX(const fixed1616&);
    void SetY(const fixed1616&);
    void SetZ(const fixed1616&);
    void SetR(const int&);
    void SetG(const int&);
    void SetB(const int&);

protected:
// Protected Methods
private:

// Private Methods
    fixed1616 x;
    fixed1616 y;
    fixed1616 z;
    int r;
    int g;
    int b;
//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Point3Dx_h

