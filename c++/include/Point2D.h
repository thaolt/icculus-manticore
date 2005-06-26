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
            const unsigned int & r,
            const unsigned int & g, 
            const unsigned int & b);
    Point2D(const Point2D&);            // copy constructor
   ~Point2D();

// Operator
   
   Point2D&   operator=(const Point2D&);     // assignment operator

// Operations

// Access
    const int & GetX()const;
    const int & GetY()const;
    const int & GetZ()const;
    unsigned int GetR()const;
    unsigned int GetG()const;
    unsigned int GetB()const;
    
    void SetX(const int &);
    void SetY(const int &);
    void SetZ(const int &);
    void SetR(const unsigned int &);
    void SetG(const unsigned int &);
    void SetB(const unsigned int &);
    // Inquiry

protected:
// Protected Methods
private:

// Private Methods
    int x;
    int y;
    int z;
    unsigned int r;
    unsigned int g;
    unsigned int b;
//////////////////Removed
};

// Inline Methods
//
// External References
//

#endif  // _Point2D_h

