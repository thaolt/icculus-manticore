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
//using namespace std;

class Point3D
{
public:

// Lifecycle

   Point3D();
    Point3D(const float& x, const float& y, const float& z);
    Point3D(const float& x, 
            const float& cy, 
            const float& z,
            const unsigned char& r,
            const unsigned char& g, 
            const unsigned char& b
            );
            
    Point3D(const Point3D&);            // copy constructor
   ~Point3D();

// Operator
   
   Point3D&   operator=(const Point3D&);     // assignment operator

// Operations

// Access
    const float& GetX()const;
    const float& GetY()const;
    const float& GetZ()const;
    unsigned char GetR()const;
    unsigned char GetG()const;
    unsigned char GetB()const;

    void SetX(const float&);
    void SetY(const float&);
    void SetZ(const float&);
    void SetR(const unsigned char&);
    void SetG(const unsigned char&);
    void SetB(const unsigned char&);

protected:
// Protected Methods
private:

// Private Methods
    float x;
    float y;
    float z;
    int r;
    int g;
    int b;
//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Point3D_h

