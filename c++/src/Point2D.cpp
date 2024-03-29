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
  z=0;
  r=0;
  g=0;
  b=0;

}// Point2D

Point2D::Point2D(const int & inx, const int & iny, const int & inz){

  x = inx;
  y = iny;
  z = inz;
  r = 0;
  g = 0;
  b = 0;
}

Point2D::Point2D(const int & inx, const int & iny, const int & inz, const unsigned int & inr, const unsigned int & ing, const unsigned int & inb){

  x = inx;
  y = iny;
  z = inz;
  r = inr;
  g = ing;
  b = inb;
}

Point2D::Point2D(const Point2D&point)
{
  x = point.GetX();
  y = point.GetY();
  z = point.GetZ();
  r = point.GetR();
  g = point.GetG();
  b = point.GetB();
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
   z = rhs.GetZ();
   r = rhs.GetR();
   g = rhs.GetG();
   b = rhs.GetB();
    return *this;

}// =

//============================= Operations ===================================
const int &
Point2D::GetX()const{

  return x;

}

const int &
Point2D::GetY()const{

  return y;

}

const int &
Point2D::GetZ()const{

  return z;

}

unsigned int 
Point2D::GetR()const{

  return r;

}

unsigned int 
Point2D::GetG()const{

  return g;

}

unsigned int
Point2D::GetB()const{

  return b;

}

void 
Point2D::SetX(const int &xin){

    x = xin;
}

void 
Point2D::SetY(const int &yin){

    y = yin;
}


void 
Point2D::SetZ(const int &zin){
    z = zin;
}


void 
Point2D::SetR(const unsigned int &rin){
    r = rin;
}


void 
Point2D::SetG(const unsigned int &gin){
    g = gin;
}


void 
Point2D::SetB(const unsigned int &bin){
    b = bin;
}


//============================= Access      ==================================
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
