#########################################################################

BIN = manticore
CYGWIN_DIR=  
SRCDIR = src
SRCS = src/main.cpp \
       src/input.cpp \
       src/VGAout.cpp \
       src/PixelRAM.cpp \
       src/Rasterizer.cpp \
       src/Triangle2D.cpp \
       src/Triangle3D.cpp \
       src/Point2D.cpp \
       src/Point3D.cpp \
       src/Transformer.cpp

#CFLAGS  = -g -ggdb -Wall  -ansi -DDEBUG  `sdl-config --cflags`
CFLAGS  = -Wall  -ansi  `sdl-config --cflags`
INCLUDE = -I. -Iinclude
LDFLAGS = -Llib -L/lib/mingw -lm `sdl-config --libs`

#############################################################################################


OBJS		= $(SRCS:.cpp=.o)
HEADERS 	= $(SRCS:.cpp=.h)	



default:$(BIN)

all:$(BIN)

$(BIN):$(OBJS) 
	$(CXX) $(CFLAGS) $(INCLUDE) $^ -o $@  $(LDFLAGS)
	@echo "|    Binary file: "$(BIN)" was successfully created."


%.o : %.cpp 

	$(CXX) $(CFLAGS) $(INCLUDE)  -o $@ -c $<


all:$(ALL)

clean:	

	@ rm -f src/*.o
	@ rm -f *.dat
	@ rm -f $(ALL)
	@ rm -f $(BIN)
	@ rm -f *.exe
	@ rm -f *.stackdump







