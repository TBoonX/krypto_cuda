#include <stdlib.h>
#include <stdio.h>
#include <math.h>

//#define DEBUG

//Variablen
#define p 7
#define q 11
#define n 77
#define e 7
#define v 103 //zu gross -> neu berechnen!
#define z 360
#define anzahl_Texte 1000

__device __ long int klartexte[anzahl_Texte];
__device __ long int klartexte_pruefung[anzahl_Texte];
__device __ long int geheimtexte[anzahl_Texte];

/*
Klartext: K
Geheimtext: G
Verschluesselung: G = K^v mod n
Entschluesselung: K = G^e mod n

Index des CUDA Kerns: blockIdx.x blockIdx.y

*/

#ifdef DEBUG
	#define WIDTH 3
#else
	#define WIDTH 256
#endif

static void HandleError( cudaError_t err, const char *file, int line ) {
	if (err != cudaSuccess) {
		printf( "%s in %s at line %d\n", cudaGetErrorString( err ), file, line );
		exit( EXIT_FAILURE );
	}
}
#define HANDLE_ERROR( err ) (HandleError( err, __FILE__, __LINE__ ))

__device__ int getArrayElement(int *m, int x, int y, int width) {
	return m[y * width + x];
}

__device__ void setArrayElement(int *m, int x, int y, int width, int value) {
	m[y * width + x] = value;
}


__global__ void matmul_simple(int *matM, int *matN, int *matP) {
	int sum, i;
	int m, n;

	sum = 0;

	for(i = 0; i < WIDTH; i++) {
		m = getArrayElement(matM, blockIdx.x, i, WIDTH);
		n = getArrayElement(matN, i, blockIdx.y, WIDTH);

		sum += m * n;
	}

	setArrayElement(matP, blockIdx.x, blockIdx.y, WIDTH, sum);
}

__global__ void verschluessselung(int klartext)
{
	int i;
	
	for (i = 0 ; i < 100; i ++)
	{
		//Integer hoch 103 ist zu hoch!
		geheimtexte[i+blockIdx.x*100] = pow(klartexte[i+blockIdx.x*100],v) % v;
	}
	
	printf("\nProzessor %d hat verschluesselt.\n", blockIdx.x);
}


__global__ void entschluessselung(int index)
{
	
}



int main(void) {
	int i, j;
	cudaEvent_t start, stop;
	float elapsedTime;

	//Klartetexte Array belegen
	//rand initialisieren
	srand((unsigned)time(NULL));
	for (i = 0; i < anzahl_Texte; i ++)
	{
		klartexte[i] = rand() % 10;		//Zahlen nicht  zu groß wählen
	}

	int *dev_matM, *dev_matN, *dev_matP;

	HANDLE_ERROR(cudaEventCreate(&start));
	HANDLE_ERROR(cudaEventCreate(&stop));

	for(i = 0; i < WIDTH; i++) {
		for(j = 0; j < WIDTH; j++) {
#ifdef DEBUG
			matM[i + j * WIDTH] = i * WIDTH + j;
			matN[i + j * WIDTH] = i + j * WIDTH;
#else
			matM[i + j * WIDTH] = rand();
			matN[i + j * WIDTH] = rand();
#endif
		}
	}

	HANDLE_ERROR(cudaEventRecord(start, 0));

        HANDLE_ERROR(cudaMalloc((void **)&dev_matM, sizeof(matM)));
        HANDLE_ERROR(cudaMalloc((void **)&dev_matN, sizeof(matN)));
        HANDLE_ERROR(cudaMalloc((void **)&dev_matP, sizeof(matP)));

        HANDLE_ERROR(cudaMemcpy(dev_matM, matM, sizeof(matM), cudaMemcpyHostToDevice));
        HANDLE_ERROR(cudaMemcpy(dev_matN, matN, sizeof(matN), cudaMemcpyHostToDevice));

	dim3 blocks(WIDTH, WIDTH);

	matmul_simple<<<blocks, 1>>>(dev_matM, dev_matN, dev_matP);

        HANDLE_ERROR(cudaMemcpy(matP, dev_matP, sizeof(matP), cudaMemcpyDeviceToHost));

	HANDLE_ERROR(cudaEventRecord(stop, 0));
	HANDLE_ERROR(cudaEventSynchronize(stop));

	HANDLE_ERROR(cudaEventElapsedTime(&elapsedTime, start, stop));
	printf("Elapsed time: %3.1f ms\n", elapsedTime);

#ifdef DEBUG
	printf("MatM:\n");
	for(i = 0; i < WIDTH; i++) {
		for(j = 0; j < WIDTH; j++) {
			printf("%4d ", matM[i + j * WIDTH]);
		}
		printf("\n");
	}

	printf("MatN:\n");
	for(i = 0; i < WIDTH; i++) {
		for(j = 0; j < WIDTH; j++) {
			printf("%4d ", matN[i + j * WIDTH]);
		}
		printf("\n");
	}

	printf("MatP:\n");
	for(i = 0; i < WIDTH; i++) {
		for(j = 0; j < WIDTH; j++) {
			printf("%4d ", matP[i + j * WIDTH]);
		}
		printf("\n");
	}
#endif

	HANDLE_ERROR(cudaEventDestroy(start));
	HANDLE_ERROR(cudaEventDestroy(stop));
	

	return EXIT_SUCCESS;
}
