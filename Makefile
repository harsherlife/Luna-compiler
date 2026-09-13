build:
	mkdir -p builds
	odin build src/ -out:builds/luna-compiler

check :
	odin build src/ -debug -out:builds/luna-debug-compiler && builds/luna-debug-compiler examples/test.lu

run : build
	builds/luna-compiler examples/test.lu