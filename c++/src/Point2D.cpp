//////////////////////////////////////////////////////////////////////////
// Name: Point2D 
//
// Files:
// Bugs:
// See Also:
// Type: C++-Source
//////////////////////////////////////////////////////////////////////////
// Authors:
// Date:
//////////////////////////////////////////////////////////////////////////
// Modifications:
//
/////////////////////////////////////////////////////////////////////////
#include "Point2D.h"                                // class implemented


/////////////////////////////// Public ///////////////////////////////////////

//============================= Lifecycle ====================================

Point2D::Point2D()
{

  x=0;
  y=0;


}// Point2D

Point2D::Point2D(const int& inx, const int& iny){

  x = inx;
  y = iny;

}

Point2D::Point2D(const int& inx, const int& iny, const int& inr, const int& ing, const int& inb){

  x = inx;
  y = iny;
  r = inr;
  g = ing;
  b = inb;
}

Point2D::Point2D(const Point2D&point)
{
  x = point.GetX();
  y = point.GetY();

}// Point2D

Point2D::~Point2D()
{
}// ~Point2D


//============================= Operators ====================================

Point2D& 
Point2D::operator=(const Point2D&rhs)
{
   if ( this==&rhs ) {
        return *this;
    }
    //superclass::operator =(rhs);

    //add local assignments
   x = rhs.GetX();
   y = rhs.GetY();

    return *this;

}// =

//============================= Operations ===================================
const int&
Point2D::GetX()const{

  return x;

}

const int&
Point2D::GetY()const{

  return y;

}

const int&
Point2D::GetR()const{

  return r;

}

const int&
Point2D::GetG()const{

  return g;

}

const int&
Point2D::GetB()const{

  return b;

}
//============================= Access      ==================================
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
