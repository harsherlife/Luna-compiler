.PHONY: build check run profile

build:
	mkdir -p builds
	odin build src/ -out:builds/luna-compiler

check:
	odin build src/ -debug -out:builds/luna-debug-compiler && builds/luna-debug-compiler examples/test.lu

run: build
	builds/luna-compiler examples/test.lu

profile:
	mkdir -p builds
	odin build src/ -define:TIMING=true -out:builds/luna-timed-compiler && builds/luna-timed-compiler examples/test.lu