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
	Point2D(const float& x, const float& y);
   Point2D(const Point2D&);            // copy constructor
   ~Point2D();

// Operator
   
   Point2D&   operator=(const Point2D&);     // assignment operator

// Operations

// Access
	const float& GetX()const;
	const float& GetY()const;
// Inquiry

protected:
// Protected Methods
private:

// Private Methods
	float x;
	float y;

//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Point2D_h
