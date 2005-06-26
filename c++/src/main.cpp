#include <iostream>
#include <stdlib.h>

#ifdef _MSC_VER
#include <Windows.h>
#endif

#include "SDL.h"
#include "input.h"
#include "VGAout.h"
#include "mcore_defs.h"
#include "Triangle3D.h"
#include "Point3D.h"
#include "Rasterizer.h"
#include "Transformer.h"
#include "mcore.h"

using namespace std;

MCfloat pVertexArray[] = 
{
    -25, -25, -25, 
     25,  25, -25, 
     25,  25, -25, 
     25, -25, -25, 
    -25, -25,  25, 
    -25,  25,  25, 
     25,  25,  25, 
     25, -25,  25
};

MCuchar pColorArray[] = 
{
    31,   1,   1,
     1,  63,   1,
     1,   1,  31,
    31,   1,  31,
     1,   6,  31,
     1,  31,  15,
     1,   1,  10,
     1,  31,  15
};

MCint pCubeIndices[] =
{
        0, 1, 2,
        0, 3, 2,
        4, 5, 6,
        4, 7, 6,

        0, 1, 5,
        0, 5, 4,
        2, 3, 6,
        3, 6, 7,

        1, 2, 5,
        2, 5, 6,
        0, 3, 4,
        3, 4, 7 
};

int main(int argc,char * argv[])
{
    argc = argc;
    argv = argv;

    Uint32 width, height, bpp, die = 0;
    SDL_Surface *Surface;
    const SDL_VideoInfo* info = NULL;
    bool fullscreen;
    Uint32 *flags = new Uint32;

    mcContext* pContext;
    mcSurfaceDescriptor* pDescriptor;
    int* pZ;
    unsigned short* pColor;
    Rasterizer* RasterEngine;
    Transformer* TransformEngine;

    float angle = 0.f ;

    Point3D* point[8];

    if( SDL_Init(SDL_INIT_VIDEO) < 0 ) 
    {
	    exit(1);
    }

    // Defaults
    fullscreen=false;
    width = MCORE_WIDTH;
    height = MCORE_HEIGHT;

    info = SDL_GetVideoInfo( );
//    long lasttime=0;
//    long thistime;

    bpp=16;
    atexit(SDL_Quit);  

    SDL_ShowCursor(0);
    *flags = SDL_SWSURFACE;

    if(fullscreen)
    {
        *flags |= SDL_FULLSCREEN;
    }

    Surface = SDL_SetVideoMode(width, height, bpp, *flags);
    SDL_WM_SetCaption("Software Renderer", NULL);

    pColor = new unsigned short[MCORE_WIDTH*MCORE_HEIGHT];
    pZ = new int[MCORE_WIDTH*MCORE_HEIGHT];
   
    pContext = new mcContext;
    pDescriptor = new mcSurfaceDescriptor;

    pContext->drawDesc = pDescriptor;
    pDescriptor->colorBuffer = (void*) pColor;
    pDescriptor->depthBuffer = (void*) pZ;
    pDescriptor->width = MCORE_WIDTH;
    pDescriptor->height = MCORE_HEIGHT;
    pDescriptor->colorBytes = 2;

    RasterEngine = new Rasterizer(pContext);	
    RasterEngine -> blank(); 
    TransformEngine = new Transformer(); 

    point[0] = new Point3D(-25, -25, -25, 31,  1,  1);
    point[1] = new Point3D(-25,  25, -25,  1, 63,  1);
    point[2] = new Point3D( 25,  25, -25,  1,  1,  31);
    point[3] = new Point3D( 25, -25, -25, 31,  1,  31);
    point[4] = new Point3D(-25, -25,  25,  1,  6,  31);
    point[5] = new Point3D(-25,  25,  25,  1,  31, 15);
    point[6] = new Point3D( 25,  25,  25,  1,  1,  10);
    point[7] = new Point3D( 25, -25,  25,  1,  31, 15);

    while(!die)
    {
        RasterEngine -> blank(); 
        angle += 0.04f;

        //mcVertexArrayPointer(

        RasterEngine->TransformEngine->loadIdentity();
        RasterEngine->TransformEngine->rotate3f(angle, 0.f, 1.f, 0.f);
        RasterEngine->TransformEngine->rotate3f(angle, 1.f, 0.f, 0.f);
        RasterEngine->TransformEngine->translate3f(0.f, 0.f, -100.f);

        RasterEngine->vertex3P(*point[0], *point[1], *point[2]);
        RasterEngine->vertex3P(*point[0], *point[3], *point[2]);
        RasterEngine->vertex3P(*point[4], *point[5], *point[6]);
        RasterEngine->vertex3P(*point[4], *point[7], *point[6]);

        RasterEngine->vertex3P(*point[0], *point[1], *point[5]);
        RasterEngine->vertex3P(*point[0], *point[5], *point[4]);
        RasterEngine->vertex3P(*point[2], *point[3], *point[6]);
        RasterEngine->vertex3P(*point[3], *point[6], *point[7]);

        RasterEngine->vertex3P(*point[1], *point[2], *point[5]);
        RasterEngine->vertex3P(*point[2], *point[5], *point[6]);
        RasterEngine->vertex3P(*point[0], *point[3], *point[4]);
        RasterEngine->vertex3P(*point[3], *point[4], *point[7]);

        RasterEngine->rasterizeArray();

        //SDL_Delay(50);
        /*
        thistime = SDL_GetTicks();
        cout << "FPS: " << 1.0f/(thistime-lasttime)*1000 << endl;
        lasttime = thistime;
        */

        die = process_input();

        if ( SDL_MUSTLOCK(Surface) ) 
        {
            SDL_LockSurface(Surface);
        }

        memcpy((void *)Surface->pixels, (void *)pColor, MCORE_WIDTH*MCORE_HEIGHT*MCORE_BYTESPERPIXEL);

        if ( SDL_MUSTLOCK(Surface) ) 
        {
            SDL_UnlockSurface(Surface);
        }
          
        SDL_UpdateRect(Surface, 0, 0, MCORE_WIDTH, MCORE_HEIGHT);


    }

    SDL_Quit();
    return 0;
}

