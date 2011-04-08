
DIRS = NAST-iEr ChimeraSlayer WigeoN RESOURCES

all clean:
	X=`pwd`; \
	for i in $(DIRS); \
	do echo '<<<' $$i '>>>'; cd $$X/$$i; make $@; done



test: testNast testWigeon testChimeraSlayer

testNast:
	cd NAST-iEr; make test

testWigeon:
	cd WigeoN; make test

testChimeraSlayer:
	cd ChimeraSlayer; make test




