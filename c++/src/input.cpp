
#include <iostream>
#include "input.h"
#include "SDL.h"
using namespace std;


int process_input()
{

  
  {
    SDL_Event event;

    while ( SDL_PollEvent(&event) ) {
      switch (event.type) {
	
      case SDL_MOUSEBUTTONDOWN:
	return 0;

      case SDL_QUIT:
	return 1;

      case SDL_JOYAXISMOTION:
	break;

      case SDL_JOYBUTTONDOWN:  /* Handle Joystick Button Presses */
	break;

      case SDL_KEYDOWN:

	if (event.key.state == SDL_PRESSED){

	  switch( event.key.keysym.sym ){

	  case SDLK_ESCAPE:
	    return 1;

	  case SDLK_q:
	    return 1;

	  default:
	    break;
	  }
	}	  

	if((event.key.keysym.sym & SDLK_RETURN) && 
	   (event.key.keysym.mod & (KMOD_ALT | KMOD_META | KMOD_CTRL) )         )
	  {	   
	    return 2; //Send video resize.
	  }

	break;


      }
    }
  }

  return 0;

}

