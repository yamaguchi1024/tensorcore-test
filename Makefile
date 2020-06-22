all: tensorcoretest.cu
	nvcc -o tensorcoretest -arch=sm_70 tensorcoretest.cu

clean:
	rm -f tensorcoretest
