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
    Point2D(const int & x, const int & y, const int & z);
    Point2D(const int & x, const int & y, const int & z, 
            const unsigned char & r,
            const unsigned char & g, 
            const unsigned char & b);
    Point2D(const Point2D&);            // copy constructor
   ~Point2D();

// Operator
   
   Point2D&   operator=(const Point2D&);     // assignment operator

// Operations

// Access
    const int & GetX()const;
    const int & GetY()const;
    const int & GetZ()const;
    unsigned char GetR()const;
    unsigned char GetG()const;
    unsigned char GetB()const;
    
    void SetX(const int &);
    void SetY(const int &);
    void SetZ(const int &);
    void SetR(const unsigned char &);
    void SetG(const unsigned char &);
    void SetB(const unsigned char &);
    // Inquiry

protected:
// Protected Methods
private:

// Private Methods
    int x;
    int y;
    int z;
    unsigned char r;
    unsigned char g;
    unsigned char b;
//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Point2D_h

