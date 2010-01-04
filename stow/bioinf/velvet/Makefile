CC = gcc
CFLAGS = -Wall
DEBUG = -g
LDFLAGS = -lm
OPT = -O3
MAXKMERLENGTH=31
CATEGORIES=2
DEF = -D MAXKMERLENGTH=$(MAXKMERLENGTH) -D CATEGORIES=$(CATEGORIES)

Z_LIB_DIR=third-party/zlib-1.2.3
Z_LIB_FILES=$(Z_LIB_DIR)/*.o

# Mac OS users: uncomment the following lines
# Z_LIB_FILES=
# LDFLAGS = -lm -lz
# CFLAGS = -Wall -m64

# Sparc/Solaris users: uncomment the following line
# CFLAGS = -Wall -m64

OBJ = obj/tightString.o obj/run.o obj/splay.o obj/splayTable.o obj/graph.o obj/run2.o obj/fibHeap.o obj/fib.o obj/concatenatedGraph.o obj/passageMarker.o obj/graphStats.o obj/correctedGraph.o obj/dfib.o obj/dfibHeap.o obj/recycleBin.o obj/readSet.o obj/shortReadPairs.o obj/locallyCorrectedGraph.o obj/graphReConstruction.o obj/roadMap.o obj/preGraph.o obj/preGraphConstruction.o obj/concatenatedPreGraph.o obj/readCoherentGraph.o obj/crc.o obj/utility.o obj/kmer.o obj/scaffold.o
OBJDBG = $(subst obj,obj/dbg,$(OBJ))

default : cleanobj zlib obj velveth velvetg doc

clean :
	-rm obj/*.o obj/dbg/*.o ./velvet* 
	cd $(Z_LIB_DIR) && make clean
	-rm -f doc/manual_src/Manual.toc doc/manual_src/Manual.aux doc/manual_src/Manual.out doc/manual_src/Manual.log

cleanobj: 
	-rm obj/*.o obj/dbg/*.o 

zlib : 
	cd $(Z_LIB_DIR); ./configure; make; rm minigzip.o; rm example.o

velveth : $(OBJ) 
	$(CC) $(CFLAGS) $(OPT) $(LDFLAGS) -o velveth obj/tightString.o obj/run.o obj/recycleBin.o obj/splay.o obj/splayTable.o obj/readSet.o obj/crc.o obj/utility.o obj/kmer.o $(Z_LIB_FILES)


velvetg : $(OBJ)
	$(CC) $(CFLAGS) $(OPT) $(LDFLAGS) -o velvetg obj/tightString.o obj/graph.o obj/run2.o obj/fibHeap.o obj/fib.o obj/concatenatedGraph.o obj/passageMarker.o obj/graphStats.o obj/correctedGraph.o obj/dfib.o obj/dfibHeap.o obj/recycleBin.o obj/readSet.o obj/shortReadPairs.o obj/scaffold.o obj/locallyCorrectedGraph.o obj/graphReConstruction.o obj/roadMap.o obj/preGraph.o obj/preGraphConstruction.o obj/concatenatedPreGraph.o obj/readCoherentGraph.o obj/utility.o obj/kmer.o $(Z_LIB_FILES)

debug : cleanobj zlib obj/dbg $(OBJDBG)
	$(CC) $(CFLAGS) $(LDFLAGS) $(DEBUG) -o velveth obj/dbg/tightString.o obj/dbg/run.o obj/dbg/recycleBin.o obj/dbg/splay.o obj/dbg/splayTable.o obj/dbg/readSet.o obj/dbg/crc.o obj/dbg/utility.o obj/dbg/kmer.o $(Z_LIB_FILES)
	$(CC) $(CFLAGS) $(LDFLAGS) $(DEBUG) -o velvetg obj/dbg/tightString.o obj/dbg/graph.o obj/dbg/run2.o obj/dbg/fibHeap.o obj/dbg/fib.o obj/dbg/concatenatedGraph.o obj/dbg/passageMarker.o obj/dbg/graphStats.o obj/dbg/correctedGraph.o obj/dbg/dfib.o obj/dbg/dfibHeap.o obj/dbg/recycleBin.o obj/dbg/readSet.o obj/dbg/shortReadPairs.o obj/dbg/scaffold.o obj/dbg/locallyCorrectedGraph.o obj/dbg/graphReConstruction.o obj/dbg/roadMap.o obj/dbg/preGraph.o obj/dbg/preGraphConstruction.o obj/dbg/concatenatedPreGraph.o obj/dbg/readCoherentGraph.o obj/dbg/utility.o obj/dbg/kmer.o $(Z_LIB_FILES)

color : override DEF := $(DEF) -D COLOR
color : cleanobj zlib obj $(OBJ)
	$(CC) $(CFLAGS) $(OPT) $(LDFLAGS) -o velveth_de obj/tightString.o obj/run.o obj/recycleBin.o obj/splay.o obj/splayTable.o obj/readSet.o obj/crc.o obj/utility.o obj/kmer.o $(Z_LIB_FILES)
	$(CC) $(CFLAGS) $(OPT) $(LDFLAGS) -o velvetg_de obj/tightString.o obj/graph.o obj/run2.o obj/fibHeap.o obj/fib.o obj/concatenatedGraph.o obj/passageMarker.o obj/graphStats.o obj/correctedGraph.o obj/dfib.o obj/dfibHeap.o obj/recycleBin.o obj/readSet.o obj/shortReadPairs.o obj/scaffold.o obj/locallyCorrectedGraph.o obj/graphReConstruction.o obj/roadMap.o obj/preGraph.o obj/preGraphConstruction.o obj/concatenatedPreGraph.o obj/readCoherentGraph.o obj/utility.o obj/kmer.o $(Z_LIB_FILES)

colordebug : override DEF := $(DEF) -D COLOR
colordebug : cleanobj zlib obj/dbg $(OBJDBG) 
	$(CC) $(CFLAGS) $(LDFLAGS) $(DEBUG) -o velveth_de obj/dbg/tightString.o obj/dbg/run.o obj/dbg/recycleBin.o obj/dbg/splay.o obj/dbg/splayTable.o obj/dbg/readSet.o obj/dbg/crc.o obj/dbg/utility.o obj/dbg/kmer.o $(Z_LIB_FILES)
	$(CC) $(CFLAGS) $(LDFLAGS) $(DEBUG) -o velvetg_de obj/dbg/tightString.o obj/dbg/graph.o obj/dbg/run2.o obj/dbg/fibHeap.o obj/dbg/fib.o obj/dbg/concatenatedGraph.o obj/dbg/passageMarker.o obj/dbg/graphStats.o obj/dbg/correctedGraph.o obj/dbg/dfib.o obj/dbg/dfibHeap.o obj/dbg/recycleBin.o obj/dbg/readSet.o obj/dbg/shortReadPairs.o obj/dbg/scaffold.o obj/dbg/locallyCorrectedGraph.o obj/dbg/graphReConstruction.o obj/dbg/roadMap.o obj/dbg/preGraph.o obj/dbg/preGraphConstruction.o obj/dbg/concatenatedPreGraph.o obj/dbg/readCoherentGraph.o obj/dbg/utility.o obj/dbg/kmer.o $(Z_LIB_FILES)

obj:
	mkdir -p obj

obj/dbg: 
	mkdir -p obj/dbg

obj/%.o: src/%.c
	$(CC) $(CFLAGS) $(OPT) $(DEF) -c $? -o $@ 

obj/dbg/%.o: src/%.c
	$(CC) $(CFLAGS) $(DEBUG) $(DEF) -c $? -o $@ 

doc: Manual.pdf

Manual.pdf: doc/manual_src/Manual.tex
	cd doc/manual_src; pdflatex Manual.tex; pdflatex Manual.tex; mv Manual.pdf ../..	
