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

   loadIdentity();

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
Transformer::loadIdentity()
{

   m_tMatrix[0][0] = 1;
   m_tMatrix[1][1] = 1;
   m_tMatrix[2][2] = 1;
   m_tMatrix[3][3] = 1;

   m_tMatrix[0][1] = 0;
   m_tMatrix[0][2] = 0;
   m_tMatrix[0][3] = 0;
   
   m_tMatrix[1][0] = 0;
   m_tMatrix[1][2] = 0;
   m_tMatrix[1][3] = 0;
   
   m_tMatrix[2][0] = 0;
   m_tMatrix[2][1] = 0;
   m_tMatrix[2][3] = 0;   
   
   m_tMatrix[3][0] = 0;
   m_tMatrix[3][1] = 0;
   m_tMatrix[3][2] = 0;
      
}

void
Transformer::translate3f(const float& x, const float& y, const float& z)
{

   m_tempMatrix[0][0] = 1;
   m_tempMatrix[1][1] = 1;
   m_tempMatrix[2][2] = 1;
   m_tempMatrix[3][3] = 1;

   m_tempMatrix[0][1] = 0;
   m_tempMatrix[0][2] = 0;
   m_tempMatrix[0][3] = 0;
   
   m_tempMatrix[1][0] = 0;
   m_tempMatrix[1][2] = 0;
   m_tempMatrix[1][3] = 0;
   
   m_tempMatrix[2][0] = 0;
   m_tempMatrix[2][1] = 0;
   m_tempMatrix[2][3] = 0; 

   m_tempMatrix[3][0] = x;
   m_tempMatrix[3][1] = y;
   m_tempMatrix[3][2] = z;
   
   applyTempMatrix();

}

void
Transformer::rotate3f(const float& x, const float& y, const float& z, const float& angle)
{
  // input axis needs to be unit
  float ux, uy, uz, mag;
  float txy, tyz, txz;
  float txx, tyy, tzz;
  float sy, sx, sz;
  float c, s, t;
  
  mag = sqrt(x*x + y*y + z*z);
  ux = x/mag;
  uy = y/mag;
  uz = z/mag;
  
  c = cos(angle);
  s = sin(angle);
  t = 1-c;
  
  txx = t*x*x;
  tyy = t*y*y;
  tzz = t*z*z;
  txy = t*x*y;
  txz = t*x*z;
  tyz = t*y*z;
  
  sx = s*x;
  sy = s*y;
  sz = s*z;
  
  m_tempMatrix[0][0] = txx + c;
  m_tempMatrix[0][1] = txy - sz;
  m_tempMatrix[0][2] = txz + sy;
  m_tempMatrix[0][3] = 0;
  
  m_tempMatrix[1][0] = txy + sz;
  m_tempMatrix[1][1] = tyy + c;
  m_tempMatrix[1][2] = tyz - sx;
  m_tempMatrix[1][3] = 0; 

  m_tempMatrix[2][0] = txz - sy;
  m_tempMatrix[2][1] = tyz + sx;
  m_tempMatrix[2][2] = tzz + c;
  m_tempMatrix[2][3] = 0; 
  
  m_tempMatrix[3][0] = 0;
  m_tempMatrix[3][1] = 0;
  m_tempMatrix[3][2] = 0;
  m_tempMatrix[3][3] = 1;   
  
  applyTempMatrix();
}

void
Transformer::applyTempMatrix()
{







}
// Old interface

void 
Transformer::RotateX(Point3D &pnt, float angle ){

  float y =  pnt.GetY()*cos(angle) + pnt.GetZ()*sin(angle);
  float z = -pnt.GetY()*sin(angle) + pnt.GetZ()*cos(angle);
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
Transformer::Translatef(Point3D &pnt, float dx, float dy, float dz){

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
