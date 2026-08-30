build:
	mkdir -p builds
	odin build . -out:builds/luna-compiler
run:
	odin run . -- 
