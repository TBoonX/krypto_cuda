#include <stdlib.h>
#include <stdio.h>

//Variablen
#define p 5
#define q 7
#define n 35
#define e 5
#define v 5
#define z 24
#define anzahl_Zeichen 2688
#define count_cores 384

/*
Klartext: K
Geheimtext: G
Verschluesselung: G = K^v mod n
Entschluesselung: K = G^e mod n

Index des CUDA Kerns: blockIdx.x blockIdx.y

Ein groesserer Text soll ver- und entschluesselt werden.
Dieser wird jedoch wie folgt veraendert: nur kleine Buchstaben, keine Sonderzeichen außer . und ,
Dafuer werden die einzellnen chars in Integer umgewandelt.
Somit ist eine Verarbeitung moeglich.

*/

static void HandleError( cudaError_t err, const char *file, int line ) {
	if (err != cudaSuccess) {
		printf( "%s in %s at line %d\n", cudaGetErrorString( err ), file, line );
		exit( EXIT_FAILURE );
	}
}
#define HANDLE_ERROR( err ) (HandleError( err, __FILE__, __LINE__ ))

__global__ void verschluessselung(long int klartexte[], long int geheimtexte[])
{
	long int i, j, multi, x;
	
	/*
	 * Schleife für Blockgroesse 384 mit je einem Thread
	
	long int block_length = anzahl_Zeichen/count_cores;
	
	for (i = 0 ; i < block_length; i++)
	{
		multi = x  = klartexte[i+blockIdx.x*count_cores];
		for (j = 1; j < v; j++)
			x *= multi;
		
		geheimtexte[i+blockIdx.x*count_cores] = x % n;
	}
	*/
	
	
	//Fuer 384 Bloecke mit 7 Threads
	long int threads = anzahl_Zeichen/count_cores;
	
	multi = x  = klartexte[threadIdx.x+blockIdx.x*threads];
	for (j = 1; j < v; j++)
		x *= multi;
	
	geheimtexte[threadIdx.x+blockIdx.x*threads] = x % n;
}


__global__ void entschluessselung(long int geheimtexte[], long int klartexte_pruefung[])
{
	long int i, j, multi, x;
	
	/*
	 * Schleife für Blockgroesse 384 mit je einem Thread
	
	long int block_length = anzahl_Zeichen/count_cores;

	for (i = 0 ; i < block_length; i++)
	{
		multi = x  = geheimtexte[i+blockIdx.x*count_cores];
		for (j = 1; j < e; j++)
			x *= multi;
		
		klartexte_pruefung[i+blockIdx.x*count_cores] = x % n;
	}
	*/
	
	//Fuer 384 Bloecke mit 7 Threads
	long int threads = anzahl_Zeichen/count_cores;
	
	multi = x  = geheimtexte[threadIdx.x+blockIdx.x*threads];
	for (j = 1; j < e; j++)
		x *= multi;
	
	klartexte_pruefung[threadIdx.x+blockIdx.x*threads] = x % n;
}

void splitt(char text[], long int numbers[])
{
	int i;
	
	//Splitte Klartext
	for (i = 0; i < anzahl_Zeichen; i++)
	{
		long int number = (int)text[i];
		
		//char in int beginnend mit 0
		//Sonderzeichen
		if (number == 44)		//,
			number = 27;
		else if (number == 46)		//.
			number = 28;
		else if (number == 10)		//\n
			number = 29;
		else if (number == 32)		//' '
			number = 30;
		else				//a-z
			number -= 97;
		
		numbers[i*3] = number;
	}
}

void unsplitt(char text[], long int numbers[])
{
	int i;
	
	//Splitte Klartext
	for (i = 0; i < anzahl_Zeichen; i++)
	{
		long int number = numbers[i*3];
		char t;
		
		//int in char
		//Sonderzeichen
		if (number == 27)		//,
			t = ',';
		else if (number == 28)		//.
			number = t = '.';
		else if (number == 29)		//\n
			t = '\n';
		else if (number == 30)		//' '
			t = ' ';
		else				//a-z
			t = (char)(number+97);
			
		text[i] = t;
	}
}

int main(void) {
	int i;
	cudaEvent_t start, stop;
	float elapsedTime;
	int count_Threads;
	
	char klartext[anzahl_Zeichen+1];
	char klartext2[anzahl_Zeichen+1];
	long int kt_splitted[anzahl_Zeichen+1];
	long int kt_splitted2[anzahl_Zeichen+1];
	long int *dev_kt_splitted, *dev_kt_splitted2, *dev_gt_splitted;
	int size = sizeof(long int)*(anzahl_Zeichen+1);
	
	//Debug
	printf("\na: %d   z: %d   ,: %d   .: %d   ?: %d    : %d   backn: %d\n\n", (int)'a', (int)'z', (int)',', (int)'.', (int)'?', (int)' ',  (int)'\n');
	
	//TEST
	/*
	splitt(klartext, kt_splitted);
	for (i = 0; i < anzahl_Zeichen; i++)
	{
		klartext[i] = '-';
	}
	unsplitt(klartext, kt_splitted);
	*/

	//Klartetext erzeugen
	klartext[anzahl_Zeichen] = klartext2[anzahl_Zeichen] = '\0';
	strcpy(klartext, "hat der alte hexenmeister?sich doch einmal wegbegeben.?und nun sollen seine geister?auch nach meinem willen leben.?seine wort und werke?merkt ich und den brauch,?und mit geistesstaerke?tu ich wunder auch.?walle. walle?manche strecke,?dass, zum zwecke,?wasser fliesse?und mit reichem, vollem schwalle?zu dem bade sich ergiesse.?und nun komm, du alter besen.?nimm die schlechten lumpenhuellen ?bist schon lange knecht gewesen:?nun erfuelle meinen willen.?auf zwei beinen stehe,?oben sei ein kopf,?eile nun und gehe?mit dem wassertopf.?walle. walle?manche strecke,?dass, zum zwecke,?wasser fliesse?und mit reichem, vollem schwalle?zu dem bade sich ergiesse.?seht, er laeuft zum ufer nieder,?wahrlich. ist schon an dem flusse,?und mit blitzesschnelle wieder?ist er hier mit raschem gusse.?schon zum zweiten male.?wie das becken schwillt.?wie sich jede schale?voll mit wasser fuellt.?stehe. stehe.?denn wir haben?deiner gaben?vollgemessen. ?ach, ich merk es. wehe. wehe.?hab ich doch das wort vergessen.?ach, das wort, worauf am ende?er das wird, was er gewesen.?ach, er laeuft und bringt behende.?waerst du doch der alte besen.?immer neue guesse?bringt er schnell herein,?ach. und hundert fluesse?stuerzen auf mich ein.?nein, nicht laenger?kann ichs lassen ?will ihn fassen.?das ist tuecke.?ach. nun wird mir immer baenger.?welche mine. welche blicke.?o du ausgeburt der hoelle.?soll das ganze haus ersaufen??seh ich ueber jede schwelle?doch schon wasserstroeme laufen.?ein verruchter besen,?der nicht hoeren will.?stock, der du gewesen,?steh doch wieder still.?willst am ende?gar nicht lassen??will dich fassen,?will dich halten?und das alte holz behende?mit dem scharfen beile spalten.?seht da kommt er schleppend wieder.?wie ich mich nur auf dich werfe,?gleich, o kobold, liegst du nieder ?krachend trifft die glatte schaerfe.?wahrlich, brav getroffen.?seht, er ist entzwei.?und nun kann ich hoffen,?und ich atme frei.?wehe. wehe.?beide teile?stehn in eile?schon als knechte?voellig fertig in die hoehe.?helft mir, ach. ihr hohen maechte.?und sie laufen. nass und naesser?wirds im saal und auf den stufen.?welch entsetzliches gewaesser.?herr und meister. hoer mich rufen.  ?ach, da kommt der meister.?herr, die not ist gross.?die ich rief, die geister?werd ich nun nicht los.?in die ecke,?besen, besen.?seids gewesen.?denn als geister?ruft euch nur zu diesem zwecke,?erst hervor der alte meister.?                                                                                                                                                                                                                                                                                                    ");

	printf("\n\nDer Klartext ist %d Zeichen lang.\n", sizeof(klartext)/sizeof(char));
	
	//Ausgabe
	printf("\n\nDer Klartext:\n");
	for (i = 0; i < anzahl_Zeichen; i++)
	{
		if (klartext[i] == '?')
			klartext[i] = '\n';
		putchar(klartext[i]);
	}
	printf("\n\n");
	
	//klartext2 mit a füllen
	for (i = 0; i < anzahl_Zeichen; i++)
	{
		klartext2[i] = 'a';
	}
	printf("Klartext2 mit a gefuellt\n");
	
	//Chars in ints aufsplitten
	splitt(klartext, kt_splitted);
	printf("klartext gesplitted\n");

	//Variablen der Zeitmessung erstellen
	HANDLE_ERROR(cudaEventCreate(&start));
	HANDLE_ERROR(cudaEventCreate(&stop));

	//Start Zeitmessung
	HANDLE_ERROR(cudaEventRecord(start, 0));

	//allokieren
	HANDLE_ERROR(cudaMalloc((void **)&dev_kt_splitted, sizeof(kt_splitted)));
	HANDLE_ERROR(cudaMalloc((void **)&dev_kt_splitted2, sizeof(kt_splitted)));
	HANDLE_ERROR(cudaMalloc((void **)&dev_gt_splitted, sizeof(kt_splitted)));
	printf("mit CUDA allokiert\n");

	//kopieren
	HANDLE_ERROR(cudaMemcpy(dev_kt_splitted, kt_splitted, size, cudaMemcpyHostToDevice));
	printf("mit CUDA kopiert\n");

	//Block festlegen
	//dim3 blocks(count_cores, 1);
	
	//Anzahl Threads pro Block
	count_Threads = anzahl_Zeichen/count_cores; 

	//verschluesseln
	verschluessselung<<<count_cores, count_Threads>>>(dev_kt_splitted, dev_gt_splitted);
	
	printf("\nVerschluesselung abgeschlossen ...\n\n");

	//zurueckkopieren
	//HANDLE_ERROR(cudaMemcpy(geheimtexte, dev_geheimtexte, sizeof(geheimtexte), cudaMemcpyDeviceToHost));
	
	//sync
	HANDLE_ERROR(cudaDeviceSynchronize());
	
	//entschluesseln
	entschluessselung<<<count_cores, count_Threads>>>(dev_gt_splitted, dev_kt_splitted2);
	
	printf("\nEntschluesselung abgeschlossen ...\n\n");
	
	//zurueckkopieren
	HANDLE_ERROR(cudaMemcpy(kt_splitted2, dev_kt_splitted2, size, cudaMemcpyDeviceToHost));
		
	//Ende der Zeitmessung
	HANDLE_ERROR(cudaEventRecord(stop, 0));
	HANDLE_ERROR(cudaEventSynchronize(stop));

	//Ausgabe der verstrichenen Zeit
	HANDLE_ERROR(cudaEventElapsedTime(&elapsedTime, start, stop));
	printf("Elapsed time: %3.1f ms\n", elapsedTime);
	
	//ints wieder in char umwandeln
	unsplitt(klartext2, kt_splitted2);
	
	//Ausgabe
	printf("\n\nDer Klartext lautet nun:\n");
	for (i = 0; i < anzahl_Zeichen; i++)
	{
		putchar(klartext2[i]);
	}
	printf("\n\n");

	//freigeben
	HANDLE_ERROR(cudaEventDestroy(start));
	HANDLE_ERROR(cudaEventDestroy(stop));
	HANDLE_ERROR(cudaFree(dev_kt_splitted));
	HANDLE_ERROR(cudaFree(dev_kt_splitted2));
	HANDLE_ERROR(cudaFree(dev_gt_splitted));

	return EXIT_SUCCESS;
}

