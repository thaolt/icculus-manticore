/* -*- Mode: C++; tab-width: 3; indent-tabs-mode: t; c-basic-offset: 3 -*- */
///////////////////////////////////////////////////////////////////////////
// Name: Point2D 
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// Modifications:
//
//
///////////////////////////////////////////////////////////////////////////
#ifndef _Point2D_h_
#define _Point2D_h_

// System Includes
//

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
class Point2D
{
public:

// Lifecycle

   Point2D();
	Point2D(const int& x, const int& y);
    Point2D(const int& x, const int& y, const int& r, const int& g, const int& b);
    Point2D(const Point2D&);            // copy constructor
   ~Point2D();

// Operator
   
   Point2D&   operator=(const Point2D&);     // assignment operator

// Operations

// Access
	const int& GetX()const;
	const int& GetY()const;
    const int& GetR()const;
    const int& GetG()const;
    const int& GetB()const;
    
    // Inquiry

protected:
// Protected Methods
private:

// Private Methods
	int x;
	int y;
    int r;
    int g;
    int b;
//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Point2D_h