build:
	mkdir -p builds
	odin build src/ -out:builds/luna-compiler

check :
	ulimit -n 65535 && valgrind --leak-check=full ./builds/luna-compiler  builds/try.txt

run :
	builds/luna-compiler builds/try.txt