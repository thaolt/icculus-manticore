//////////////////////////////////////////////////////////////////////////
// Name: Triangle3Dx 
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
#include "Triangle3Dx.h"                                // class implemented


/////////////////////////////// Public ///////////////////////////////////////

//============================= Lifecycle ====================================

Triangle3Dx::Triangle3Dx()
  :P3D1(),P3D2(),P3D3()
{
}// Triangle3Dx

Triangle3Dx::Triangle3Dx(const Point3Dx& inp1, const Point3Dx& inp2, const Point3Dx& inp3): P3D1(inp1),
     P3D2(inp2),
     P3D3(inp3)
{


}

Triangle3Dx::Triangle3Dx(const Triangle3Dx&)
{
}// Triangle3Dx

Triangle3Dx::~Triangle3Dx()
{
}// ~Triangle3Dx


//============================= Operators ====================================

Triangle3Dx& 
Triangle3Dx::operator=(const Triangle3Dx&rhs)
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
Triangle3Dx::SetPoints(const Point3Dx& inp1, const Point3Dx& inp2, const Point3Dx& inp3){

    P3D1 = inp1;
    P3D2 = inp2;
    P3D3 = inp3;

}
//============================= Access      ==================================

Point3Dx
Triangle3Dx::GetP3D1(){

  return P3D1;

} 

Point3Dx
Triangle3Dx::GetP3D2(){

  return P3D2;

}

Point3Dx
Triangle3Dx::GetP3D3(){

  return P3D3;

}

//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
