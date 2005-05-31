#ifndef _MCORE_TYPES_H_
#define _MCORE_TYPES_H_

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

#endif // _MCORE_TYPES_H_