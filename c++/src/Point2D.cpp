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

Point2D::Point2D(const double& inx, const double& iny){

  x = inx;
  y = iny;

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
const double&
Point2D::GetX()const{

  return x;

}

const double&
Point2D::GetY()const{

  return y;

}

//============================= Access      ==================================
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
