\

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

using namespace std;

int main(int argc,char * argv[])
{

  Uint32 width, height, bpp, die = 0;
  SDL_Surface *Surface;
  const SDL_VideoInfo* info = NULL;
  bool fullscreen;
  Uint32 *flags = new Uint32;

  if( SDL_Init(SDL_INIT_VIDEO) < 0 ) {
	//cout<<    "Couldn't initialize SDL: "<< SDL_GetError() << endl;;
    exit(1);
  }

  // Defaults
  fullscreen=false;
  width = MCORE_WIDTH;
  height = MCORE_HEIGHT;

  info = SDL_GetVideoInfo( );
  long lasttime=0;
  long thistime;

  //bpp = info->vfmt->BitsPerPixel;
  bpp=32;
  atexit(SDL_Quit);
  
  SDL_ShowCursor(0);
  *flags = SDL_SWSURFACE;
  if(fullscreen){
    *flags = SDL_FULLSCREEN;
  }

  Surface = SDL_SetVideoMode(width, height, bpp, *flags);

  SDL_WM_SetCaption("Software Triangle", NULL);


  PixelRAM* PixelData = new PixelRAM;
  Rasterizer* RasterEngine = new Rasterizer(Surface, PixelData);
  Transformer* TransformEngine = new Transformer();

  VGAout Video(Surface, PixelData);
  Video.ClearScreen();

  Point3D P1(-120,    0, -120, 255,   0, 0  );
  Point3D P2(-300, -100, -120,   0, 255, 0  );
  Point3D P3(-170, -160, -120,   0,   0, 255);

  Point3D P6( 150, 100, -120, 40, 255, 0  );
  Point3D P5(-100,  00, -120,   0, 90, 55);
  Point3D P4(  80, 150, -120, 20,  60, 255);

  Point3D P9(180, -200, -80,   30,  75,  82);
  Point3D P8(100, -200, -150, 115,  76,  32);
  Point3D P7(150, -100, -120, 200, 200, 200);

  Triangle3D tri1(P1, P2, P3);
  Triangle3D tri2(P4, P5, P6);  
  Triangle3D tri3(P7, P8, P9);

  while(!die){
  
    PixelData->Blank();


    TransformEngine -> Translate(P1,0,0,120 );
    TransformEngine -> Translate(P2,0,0,120 );
    TransformEngine -> Translate(P3,0,0,120 );

    TransformEngine -> RotateZ(P1,0.04f);
    TransformEngine -> RotateZ(P2,0.04f);
    TransformEngine -> RotateZ(P3,0.04f);

    TransformEngine -> Translate(P1,0,0,-120 );
    TransformEngine -> Translate(P2,0,0,-120 );
    TransformEngine -> Translate(P3,0,0,-120 );

    TransformEngine -> Translate(P4,0,0,120 );
    TransformEngine -> Translate(P5,0,0,120 );
    TransformEngine -> Translate(P6,0,0,120 );

    TransformEngine -> RotateY(P4,0.06f);
    TransformEngine -> RotateY(P5,0.06f);
    TransformEngine -> RotateY(P6,0.06f);

    TransformEngine -> Translate(P4,0,0,-120 );
    TransformEngine -> Translate(P5,0,0,-120 );
    TransformEngine -> Translate(P6,0,0,-120 );

    TransformEngine -> Translate(P7,0,0,280 );
    TransformEngine -> Translate(P8,0,0,280 );
    TransformEngine -> Translate(P9,0,0,280 );

    TransformEngine -> RotateX(P7,0.06f);
    TransformEngine -> RotateX(P8,0.06f);
    TransformEngine -> RotateX(P9,0.06f);

    TransformEngine -> Translate(P7,0,0,-280 );
    TransformEngine -> Translate(P8,0,0,-280 );
    TransformEngine -> Translate(P9,0,0,-280 );
/*
    */
    tri1.SetPoints(P1,P2,P3);
    tri2.SetPoints(P4,P5,P6);
    tri3.SetPoints(P7,P8,P9);


    RasterEngine->Rasterize(tri2);

    RasterEngine->Rasterize(tri1);

    RasterEngine->Rasterize(tri3);

    thistime = SDL_GetTicks();
    cout << "FPS: " << 1.0f/(thistime-lasttime)*1000 << endl;
    lasttime = thistime;

    die = process_input();
    Video.DrawScreen();
  }

  SDL_Quit();
  return 0;


}
