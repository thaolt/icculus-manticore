//////////////////////////////////////////////////////////////////////////
// Name: Transformer 
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
#include "Transformer.h"                                // class implemented
#include <math.h>
#include "mcore_defs.h"
/////////////////////////////// Public ///////////////////////////////////////

//============================= Lifecycle ====================================

Transformer::Transformer()
{
}// Transformer

Transformer::Transformer(const Transformer&)
{
}// Transformer

Transformer::~Transformer()
{
}// ~Transformer


//============================= Operators ====================================

Transformer& 
Transformer::operator=(const Transformer &rhs)
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
Transformer::RotateX(Point3D &pnt, float angle ){

  float y =  pnt.GetY()*cos(angle) + pnt.GetZ()*sin(angle);
  float z = -pnt.GetY()*sin(angle) + pnt.GetZ()*cos(angle);
  pnt.SetY(y);
  pnt.SetZ(z);

}
/*
void 
Transformer::RotateXx(Point3Dx &pnt, float angle ){

  float cosf = cos(angle);
  float sinf = sin(angle);
 
  fixed1616 cosx = (long)(cosf*256);
  fixed1616 sinx = (long)(sinf*256);

  fixed1616 y = ( pnt.GetY()*cosx + pnt.GetZ()*sinx)>>8;
  fixed1616 z = (-pnt.GetY()*sinx + pnt.GetZ()*cosx)>>8;
 
  pnt.SetY(y);
  pnt.SetZ(z);

}
*/
void 
Transformer::RotateY(Point3D &pnt, float angle ){

  float x = pnt.GetX()*cos(angle)-pnt.GetZ()*sin(angle);
  float z = pnt.GetX()*sin(angle)+pnt.GetZ()*cos(angle);
  pnt.SetX(x);
  pnt.SetZ(z);
}

void 
Transformer::RotateZ(Point3D &pnt, float angle ){

  float x = pnt.GetX()*cos(angle)+pnt.GetY()*sin(angle);
  float y = -pnt.GetX()*sin(angle)+pnt.GetY()*cos(angle);
  pnt.SetX(x);
  pnt.SetY(y);

}

void 
Transformer::Translatef(Point3D &pnt, float dx, float dy, float dz){

  pnt.SetX(pnt.GetX()+dx);
  pnt.SetY(pnt.GetY()+dy);
  pnt.SetZ(pnt.GetZ()+dz);

}
/*
void 
Transformer::Translatex(Point3Dx &pnt, fixed1616 dx, fixed1616 dy, fixed1616 dz){

  pnt.SetX(pnt.GetX()+dx);
  pnt.SetY(pnt.GetY()+dy);
  pnt.SetZ(pnt.GetZ()+dz);

}
*/
void 
Transformer::Scale(Point3D &pnt, float factor ){



}


//============================= Access      ==================================
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
