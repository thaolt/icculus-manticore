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

  float y = pnt.GetY()*cos(angle)+pnt.GetZ()*sin(angle);
  float z = -pnt.GetY()*sin(angle)+pnt.GetZ()*cos(angle);
  pnt.SetY(y);
  pnt.SetZ(z);

}

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
Transformer::Translate(Point3D &pnt, float dx, float dy, float dz){

  pnt.SetX(pnt.GetX()+dx);
  pnt.SetY(pnt.GetY()+dy);
  pnt.SetZ(pnt.GetZ()+dz);

}

void 
Transformer::Scale(Point3D &pnt, float factor ){



}


//============================= Access      ==================================
//============================= Inquiry    ===================================
/////////////////////////////// Protected Methods ////////////////////////////

/////////////////////////////// Private   Methods ////////////////////////////
