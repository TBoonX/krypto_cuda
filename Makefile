TARGET=rsa_cump

NVCC=/usr/local/cuda/bin/nvcc


NV_CFLAGS=-g -lgmp

NV_LDFLAGS=-lgmp
	
$(TARGET): $(TARGET).o
	$(NVCC) $(NV_LDFLAGS) $+ -o $(TARGET)

%.o: %.cu
	$(NVCC) $(NV_CFLAGS) -c $< -o $@

clean:
	rm -rf *.o $(TARGET)

