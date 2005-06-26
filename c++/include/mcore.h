#ifndef _MCORE_H_
#define _MCORE_H_

#if defined (__cplusplus)
extern "C" {
#endif

typedef struct 
{
   int      width;
   int      height;
   void*    colorBuffer;
   void*    depthBuffer;
   void*    stencilBuffer;
   int      colorBufferStride;
   int      depthBufferStride;
   int      stencilBufferStride;
   int      colorBytes;
   int      depthBytes;
   int      stencilBytes;
   int      redBits;
   int      redOffset;
   int      greenBits;
   int      greenOffset;
   int      blueBits;
   int      blueOffset;
   int      alphaBits;
   int      alphaOffset;
} mcSurfaceDescriptor;
   
   
typedef struct 
{

   mcSurfaceDescriptor* drawDesc;
   mcSurfaceDescriptor* readDesc;
   
} mcContext;

#if defined (__cplusplus)
}
#endif

/* Types */

typedef int             MCint;
typedef unsigned int    MCuint;
typedef short           MCshort;
typedef unsigned short  MCushort;
typedef char            MCchar;
typedef unsigned char   MCuchar;
typedef float           MCfloat;
typedef unsigned int    MCtype;

#define MC_INT      0x100
#define MC_UINT     0x101
#define MC_SHORT    0x102 
#define MC_USHORT   0x103
#define MC_CHAR     0x104
#define MC_UCHAR    0x105
#define MC_FLOAT    0x106

void mcVertexPointer    (void *vPtr, MCtype type, MCuint stride);
void mcColorPointer     (void *vPtr, MCtype type, MCuint stride);
void mcTexCoordPointer  (void *vPtr, MCtype type, MCuint stride);
void mcDrawElements     (MCuint count, MCtype type, void* iPtr);

#endif // _MCOREH_