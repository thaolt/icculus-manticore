//////////////////////////////////////////////////////////////////////////
// Name: Point3D 
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
#include "Point3D.h"                                // class implemented


/////////////////////////////// Public ///////////////////////////////////////

//============================= Lifecycle ====================================

Point3D::Point3D()
{

  x=0;
  y=0;
  z=0;

}// Point3D

Point3D::Point3D(const double& inx, const double& iny, const double& inz){

  x = inx;
  y = iny;
  z = inz;
  //  cout << x << y << z << endl;
}
Point3D::Point3D(const Point3D&point)
{

  x = point.GetX();
  y = point.GetY();
  z = point.GetZ();

}// Point3D

Point3D::~Point3D()
{
}// ~Point3D


//============================= Operators ====================================

Point3D& 
Point3D::operator=(const Point3D&rhs)
{
   if ( this==&rhs ) {
        return *this;
    }
    //superclass::operator =(rhs);

    //add local assignments
   x = rhs.GetX();
   y = rhs.GetY();
   z = rhs.GetZ();
    return *this;

}// =

//============================= Operations ===================================
//============================= Access      ==================================
const double&
Point3D::GetX()const{

  return x;

}

const double&
Point3D::GetY()const{

  return y;

}

const double&
Point3D::GetZ()const{

  return z;

}
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
