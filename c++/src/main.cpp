\

#include <iostream>
#include <stdlib.h>

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
	cout<<    "Couldn't initialize SDL: "<< SDL_GetError() << endl;;
    exit(1);
  }

  // Defaults
  fullscreen=false;
  width = MCORE_WIDTH;
  height = MCORE_HEIGHT;

  info = SDL_GetVideoInfo( );

  bpp = info->vfmt->BitsPerPixel;

  atexit(SDL_Quit);
  
  SDL_ShowCursor(0);

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

  //Point3D P1(-150, 0, -120);
  //Point3D P2(-100, -100, -120);
  //Point3D P3(-20, -60, -120);
  Point3D P1(-0, -100, -120);
  Point3D P2(-100, -100, -120);
  Point3D P3(-20, -250, -120);

  

  while(!die){
  

    TransformEngine -> Translate(P1,0,0,120 );
    TransformEngine -> Translate(P2,0,0,120 );
    TransformEngine -> Translate(P3,0,0,120 );

    TransformEngine -> RotateY(P1,0.06);
    TransformEngine -> RotateY(P2,0.06);
    TransformEngine -> RotateY(P3,0.06);
    
    TransformEngine -> Translate(P1,0,0,-120 );
    TransformEngine -> Translate(P2,0,0,-120 );
    TransformEngine -> Translate(P3,0,0,-120 );


    Triangle3D tri1(P1, P2, P3);
    RasterEngine->Rasterize(tri1);
   
    die = process_input();
    Video.DrawScreen();
  }

  SDL_Quit();
  return 0;


}
