#include <stdlib.h>
#include <stdio.h>
//CUMP Bibliothek
#include <gmp.h>
#include <cump/cump.cuh>

__device__ mpz_t biginteger;

//#define DEBUG

//Variablen
#define p 3
#define q 5
#define n 15
#define e 3
#define v 3
#define z 8
#define anzahl_Texte 80
#define count_cores 8

/*
Klartext: K
Geheimtext: G
Verschluesselung: G = K^v mod n
Entschluesselung: K = G^e mod n

Index des CUDA Kerns: blockIdx.x blockIdx.y

*/

static void HandleError( cudaError_t err, const char *file, int line ) {
	if (err != cudaSuccess) {
		printf( "%s in %s at line %d\n", cudaGetErrorString( err ), file, line );
		exit( EXIT_FAILURE );
	}
}
#define HANDLE_ERROR( err ) (HandleError( err, __FILE__, __LINE__ ))

__device__ __host__ float biAdd(mpz_t a, unsigned long int b)
{
	mpz_add_ui(a, a, b);
	return 1.0;
}



__global__ void verschluessselung(long int klartexte[], long int geheimtexte[])
{
	using namespace cump;

	long int i, j, multi, x;
	
	long int block_length = anzahl_Texte/count_cores;
	
	for (i = 0 ; i < block_length; i++)
	{
		multi = x  = klartexte[i+blockIdx.x*block_length];
		for (j = 1; j < v; j++)
			x *= multi;
		
		geheimtexte[i+blockIdx.x*block_length] = x % n;
		
	}
	
	//GMP
	//biAdd(biginteger, (unsigned long int)25);
	//mpz_add_ui(biginteger, biginteger, (unsigned long int)25);
	biAdd(biginteger, (unsigned long int)25);
	
}


__global__ void entschluessselung(long int geheimtexte[], long int klartexte_pruefung[])
{
	long int i, j, multi, x;
	
	long int block_length = anzahl_Texte/count_cores;

	for (i = 0 ; i < block_length; i++)
	{
		multi = x  = geheimtexte[i+blockIdx.x*block_length];
		for (j = 1; j < e; j++)
			x *= multi;
		
		klartexte_pruefung[i+blockIdx.x*block_length] = x % n;
		
	}
}

int main(void) {
	int i;
	cudaEvent_t start, stop;
	float elapsedTime;
	
	long int klartexte[anzahl_Texte];
	long int klartexte_pruefung[anzahl_Texte];
	long int geheimtexte[anzahl_Texte];

	// GMP Integer
	// mpz_t biginteger;
	mpz_init(biginteger);
	unsigned long int number = 1;
	//number = number<<31;
	mpz_set_ui(biginteger, number);
	// gmp_printf("\nGMP Integer: %Zd\n\n", biginteger);
	
//	printf("\nlong int: %d\n", sizeof(long int));
//	printf("\nunsigned long int: %d\n", sizeof(unsigned long int));
//	printf("\nunsigned long long: %d\n", sizeof(unsigned long long));
	

	//Klartetexte Array belegen
	//rand initialisieren
	srand((unsigned)time(NULL));
	for (i = 0; i < anzahl_Texte; i ++)
	{
		klartexte[i] = rand() % 15;		//Zahlen nicht  zu gross waehlen
	}
	
	printf("Die Klartexte:\n");
	for (i = 0; i < anzahl_Texte; i++)
	{
		printf("%ld, ", klartexte[i]);
	}
	printf("\n\n");

	long int *dev_klartexte, *dev_geheimtexte, *dev_klartexte_pruefung;

	HANDLE_ERROR(cudaEventCreate(&start));
	HANDLE_ERROR(cudaEventCreate(&stop));



	HANDLE_ERROR(cudaEventRecord(start, 0));

        HANDLE_ERROR(cudaMalloc((void **)&dev_klartexte, sizeof(klartexte)));
        HANDLE_ERROR(cudaMalloc((void **)&dev_geheimtexte, sizeof(geheimtexte)));
        HANDLE_ERROR(cudaMalloc((void **)&dev_klartexte_pruefung, sizeof(klartexte_pruefung)));

        HANDLE_ERROR(cudaMemcpy(dev_klartexte, klartexte, sizeof(klartexte), cudaMemcpyHostToDevice));

	dim3 blocks(count_cores, 1);

	verschluessselung<<<blocks, 1>>>(dev_klartexte, dev_geheimtexte);

        HANDLE_ERROR(cudaMemcpy(geheimtexte, dev_geheimtexte, sizeof(geheimtexte), cudaMemcpyDeviceToHost));
		

	gmp_printf("\nGMP Integer: %Zd\n\n", biginteger);

	printf("Die Klartexte wurden verschluesselt.\n\nGeheimtexte:\n");
	for (i = 0; i < anzahl_Texte; i++)
	{
		printf("%ld, ", geheimtexte[i]);
	}
	printf("\n\n");
	
	entschluessselung<<<blocks, 1>>>(dev_geheimtexte, dev_klartexte_pruefung);
	
	HANDLE_ERROR(cudaMemcpy(klartexte_pruefung, dev_klartexte_pruefung, sizeof(klartexte_pruefung), cudaMemcpyDeviceToHost));
		

	HANDLE_ERROR(cudaEventRecord(stop, 0));
	HANDLE_ERROR(cudaEventSynchronize(stop));
	
	printf("Die Geheimtexte wurden entschluesselt.\n\nKlartexte:\n");
		for (i = 0; i < anzahl_Texte; i++)
		{
			printf("%ld, ", klartexte_pruefung[i]);
		}
		printf("\n\n");

	HANDLE_ERROR(cudaEventElapsedTime(&elapsedTime, start, stop));
	printf("Elapsed time: %3.1f ms\n", elapsedTime);



	HANDLE_ERROR(cudaEventDestroy(start));
	HANDLE_ERROR(cudaEventDestroy(stop));
	
	gmp_printf("\nGMP Integer: %Zd\n\n", biginteger);

	return EXIT_SUCCESS;
}

