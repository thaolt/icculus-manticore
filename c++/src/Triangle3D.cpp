//////////////////////////////////////////////////////////////////////////
// Name: Triangle3D 
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
#include "Triangle3D.h"                                // class implemented


/////////////////////////////// Public ///////////////////////////////////////

//============================= Lifecycle ====================================

Triangle3D::Triangle3D()
  :P3D1(),P3D2(),P3D3()
{
}// Triangle3D

Triangle3D::Triangle3D(const Point3D& inp1, const Point3D& inp2, const Point3D& inp3): P3D1(inp1),
     P3D2(inp2),
     P3D3(inp3)
{


}

Triangle3D::Triangle3D(const Triangle3D&)
{
}// Triangle3D

Triangle3D::~Triangle3D()
{
}// ~Triangle3D


//============================= Operators ====================================

Triangle3D& 
Triangle3D::operator=(const Triangle3D&rhs)
{
   if ( this==&rhs ) {
        return *this;
    }
    //superclass::operator =(rhs);

    //add local assignments

    return *this;

}// =

//============================= Operations ===================================

void 
Triangle3D::SetPoints(const Point3D& inp1, const Point3D& inp2, const Point3D& inp3){

    P3D1 = inp1;
    P3D2 = inp2;
    P3D3 = inp3;

}
//============================= Access      ==================================

Point3D
Triangle3D::GetP3D1(){

  return P3D1;

} 

Point3D
Triangle3D::GetP3D2(){

  return P3D2;

}

Point3D
Triangle3D::GetP3D3(){

  return P3D3;

}

//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
