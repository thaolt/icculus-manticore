//////////////////////////////////////////////////////////////////////////
// Name: Point3Dx 
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
#include "Point3Dx.h"                                // class implemented
#include "mcore_defs.h"

/////////////////////////////// Public ///////////////////////////////////////

//============================= Lifecycle ====================================

Point3Dx::Point3Dx()
{

  x=0;
  y=0;
  z=0;

}// Point3Dx

Point3Dx::Point3Dx(const fixed1616& inx, const fixed1616& iny, const fixed1616& inz){

  x = inx;
  y = iny;
  z = inz;
  r = 0;
  g = 0;
  b = 0;
  //  cout << x << y << z << endl;
}

Point3Dx::Point3Dx(const fixed1616& inx, const fixed1616& iny, const fixed1616& inz, const int& inr, const int& ing, const int& inb){

  x = inx;
  y = iny;
  z = inz;
  r = inr;
  g = ing;
  b = inb;
  //  cout << x << y << z << endl;
}

Point3Dx::Point3Dx(const Point3Dx&point)
{

  x = point.GetX();
  y = point.GetY();
  z = point.GetZ();
  r = point.GetR();
  g = point.GetG();
  b = point.GetB();
}// Point3Dx

Point3Dx::~Point3Dx()
{
}// ~Point3Dx


//============================= Operators ====================================

Point3Dx& 
Point3Dx::operator=(const Point3Dx&rhs)
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
const fixed1616&
Point3Dx::GetX()const{

  return x;

}

const fixed1616&
Point3Dx::GetY()const{

  return y;

}

const fixed1616&
Point3Dx::GetZ()const{

  return z;

}


const int&
Point3Dx::GetR()const{

  return r;

}

const int&
Point3Dx::GetG()const{

  return g;

}

const int&
Point3Dx::GetB()const{

  return b;

}

void
Point3Dx::SetX(const fixed1616& xin){

  x = xin;
  
}


void 
Point3Dx::SetY(const fixed1616& yin){

  y = yin;
  
}

void 
Point3Dx::SetZ(const fixed1616& zin){

  z = zin;
  
}

void 
Point3Dx::SetR(const int &rin){
    r = rin;
}


void 
Point3Dx::SetG(const int &gin){
    g = gin;
}


void 
Point3Dx::SetB(const int &bin){
    b = bin;
}

//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
