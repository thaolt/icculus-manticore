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

Point3D::Point3D(const float& inx, const float& iny, const float& inz){

  x = inx;
  y = iny;
  z = inz;
  r = 0;
  g = 0;
  b = 0;
  //  cout << x << y << z << endl;
}

Point3D::Point3D(const float& inx, const float& iny, const float& inz, const unsigned int & inr, const unsigned int & ing, const unsigned int & inb){

  x = inx;
  y = iny;
  z = inz;
  r = inr;
  g = ing;
  b = inb;
  //  cout << x << y << z << endl;
}

Point3D::Point3D(const Point3D&point)
{

  x = point.GetX();
  y = point.GetY();
  z = point.GetZ();
  r = point.GetR();
  g = point.GetG();
  b = point.GetB();
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
   r = rhs.GetR();
   g = rhs.GetG();
   b = rhs.GetB();
    return *this;

}// =

//============================= Operations ===================================
//============================= Access      ==================================
const float&
Point3D::GetX()const{

  return x;

}

const float&
Point3D::GetY()const{

  return y;

}

const float&
Point3D::GetZ()const{

  return z;

}


unsigned int 
Point3D::GetR()const{

  return r;

}

unsigned int 
Point3D::GetG()const{

  return g;

}

unsigned int 
Point3D::GetB()const{

  return b;

}

void
Point3D::SetX(const float& xin){

  x = xin;
  
}


void 
Point3D::SetY(const float& yin){

  y = yin;
  
}

void 
Point3D::SetZ(const float& zin){

  z = zin;
  
}

void 
Point3D::SetR(const unsigned int & rin){
    r = rin;
}


void 
Point3D::SetG(const unsigned int & gin){
    g = gin;
}


void 
Point3D::SetB(const unsigned int & bin){
    b = bin;
}

//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
