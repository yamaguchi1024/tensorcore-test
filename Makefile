all: tensorcoretest.cu
	nvcc -o tensorcoretest -std=c++11 -arch=sm_70 tensorcoretest.cu

clean:
	rm -f tensorcoretest
