#include <stdlib.h>
#include <stdio.h>

#define output 1

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
Dafuer werden die einzellnen chars in Integer umgewandelt (<=30).
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
	long int j, multi, x;
	
	//Fuer 384 Bloecke mit Threads
	long int threads = anzahl_Zeichen/count_cores;

	multi = x  = klartexte[threadIdx.x+blockIdx.x*threads];
	for (j = 1; j < v; j++)
		x *= multi;
	
	geheimtexte[threadIdx.x+blockIdx.x*threads] = x % n;
}

__global__ void entschluessselung(long int geheimtexte[], long int klartexte_pruefung[])
{
	long int j, multi, x;
	
	//Fuer 384 Bloecke mit Threads
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
		
		numbers[i] = number;
	}
}

void unsplitt(char text[], long int numbers[])
{
	int i;
	
	//Splitte Klartext
	for (i = 0; i < anzahl_Zeichen; i++)
	{
		long int number = numbers[i];
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

int main(int argc, char *argv[]) {
	int i;
	cudaEvent_t start, stop;
	float elapsedTime;
	int count_Threads;
	long int multi = 0;
	
	char klartext[anzahl_Zeichen+1];
	char klartext2[anzahl_Zeichen+1];
	long int kt_splitted[anzahl_Zeichen+1];
	long int kt_splitted2[anzahl_Zeichen+1];
	long int *dev_kt_splitted, *dev_kt_splitted2, *dev_gt_splitted;
	int size = sizeof(long int)*(anzahl_Zeichen+1);
	
	printf("\n-|| RSA mit CUDA ||-\n\n\n");
	
	//Klartetext erzeugen
	klartext[anzahl_Zeichen] = klartext2[anzahl_Zeichen] = '\0';
	strcpy(klartext, "hat der alte hexenmeister?sich doch einmal wegbegeben.?und nun sollen seine geister?auch nach meinem willen leben.?seine wort und werke?merkt ich und den brauch,?und mit geistesstaerke?tu ich wunder auch.?walle. walle?manche strecke,?dass, zum zwecke,?wasser fliesse?und mit reichem, vollem schwalle?zu dem bade sich ergiesse.?und nun komm, du alter besen.?nimm die schlechten lumpenhuellen ?bist schon lange knecht gewesen:?nun erfuelle meinen willen.?auf zwei beinen stehe,?oben sei ein kopf,?eile nun und gehe?mit dem wassertopf.?walle. walle?manche strecke,?dass, zum zwecke,?wasser fliesse?und mit reichem, vollem schwalle?zu dem bade sich ergiesse.?seht, er laeuft zum ufer nieder,?wahrlich. ist schon an dem flusse,?und mit blitzesschnelle wieder?ist er hier mit raschem gusse.?schon zum zweiten male.?wie das becken schwillt.?wie sich jede schale?voll mit wasser fuellt.?stehe. stehe.?denn wir haben?deiner gaben?vollgemessen. ?ach, ich merk es. wehe. wehe.?hab ich doch das wort vergessen.?ach, das wort, worauf am ende?er das wird, was er gewesen.?ach, er laeuft und bringt behende.?waerst du doch der alte besen.?immer neue guesse?bringt er schnell herein,?ach. und hundert fluesse?stuerzen auf mich ein.?nein, nicht laenger?kann ichs lassen ?will ihn fassen.?das ist tuecke.?ach. nun wird mir immer baenger.?welche mine. welche blicke.?o du ausgeburt der hoelle.?soll das ganze haus ersaufen??seh ich ueber jede schwelle?doch schon wasserstroeme laufen.?ein verruchter besen,?der nicht hoeren will.?stock, der du gewesen,?steh doch wieder still.?willst am ende?gar nicht lassen??will dich fassen,?will dich halten?und das alte holz behende?mit dem scharfen beile spalten.?seht da kommt er schleppend wieder.?wie ich mich nur auf dich werfe,?gleich, o kobold, liegst du nieder ?krachend trifft die glatte schaerfe.?wahrlich, brav getroffen.?seht, er ist entzwei.?und nun kann ich hoffen,?und ich atme frei.?wehe. wehe.?beide teile?stehn in eile?schon als knechte?voellig fertig in die hoehe.?helft mir, ach. ihr hohen maechte.?und sie laufen. nass und naesser?wirds im saal und auf den stufen.?welch entsetzliches gewaesser.?herr und meister. hoer mich rufen.  ?ach, da kommt der meister.?herr, die not ist gross.?die ich rief, die geister?werd ich nun nicht los.?in die ecke,?besen, besen.?seids gewesen.?denn als geister?ruft euch nur zu diesem zwecke,?erst hervor der alte meister.?                                                                                                                                                                                                                                                                                                    ");
	printf("\n\nDer Klartext ist %d Zeichen lang.\n", sizeof(klartext)/sizeof(char)-1);
	
	if (argc < 2)
	{
		printf("\nParameter fuer Groesse der Klartexted fehlt!\n");
		exit(0);
	}

	//lese Anzahl der Zeichen
	multi = atoi(argv[1]);

	if (multi < 1)
	{
		printf("\nAnzahl der Zeichen ist eine ganze positive Zahl.\n");
		exit(0);
	}
	
	printf("\nmulti: %d\n", multi);
	
	//Ausgabe
	if (output)
	{
		printf("\n\nAnfang des  Klartextes:\n\n");
		for (i = 0; i < anzahl_Zeichen; i++)
		{
			if (klartext[i] == '?')
				klartext[i] = '\n';
			if (i < 546)
				putchar(klartext[i]);
		}
		printf("\n\n");
	}
	
	//klartext2 mit a füllen
	for (i = 0; i < anzahl_Zeichen; i++)
	{
		klartext2[i] = 'a';
	}
	
	printf("Der Klartext wird nun verschluesselt und anschliessend entschluesselt.\n");
	
	//Chars in ints aufsplitten
	splitt(klartext, kt_splitted);
	
	//Variablen der Zeitmessung erstellen
	HANDLE_ERROR(cudaEventCreate(&start));
	HANDLE_ERROR(cudaEventCreate(&stop));
	
	//Start Zeitmessung
	HANDLE_ERROR(cudaEventRecord(start, 0));
	
	//allokieren
	HANDLE_ERROR(cudaMalloc((void **)&dev_kt_splitted, size));
	HANDLE_ERROR(cudaMalloc((void **)&dev_kt_splitted2, size));
	HANDLE_ERROR(cudaMalloc((void **)&dev_gt_splitted, size));
	
	//kopieren
	HANDLE_ERROR(cudaMemcpy(dev_kt_splitted, kt_splitted, size, cudaMemcpyHostToDevice));
	
	//Anzahl Threads pro Block
	count_Threads = anzahl_Zeichen/count_cores;
	
	for (i = 0; i < multi; i++)
	{
		//verschluesseln
		verschluessselung<<<count_cores, count_Threads>>>(dev_kt_splitted, dev_gt_splitted);
		
		//sync
		HANDLE_ERROR(cudaDeviceSynchronize());
		
		//entschluesseln
		entschluessselung<<<count_cores, count_Threads>>>(dev_gt_splitted, dev_kt_splitted2);
		
		//sync
		HANDLE_ERROR(cudaDeviceSynchronize());
	}
	
	//zurueckkopieren
	HANDLE_ERROR(cudaMemcpy(kt_splitted2, dev_kt_splitted2, size, cudaMemcpyDeviceToHost));
		
	//Ende der Zeitmessung
	HANDLE_ERROR(cudaEventRecord(stop, 0));
	HANDLE_ERROR(cudaEventSynchronize(stop));
	
	//Ausgabe der verstrichenen Zeit
	HANDLE_ERROR(cudaEventElapsedTime(&elapsedTime, start, stop));
	printf("\nBeendet.\n\n\nverstrichene Zeit: %3.1f ms\n", elapsedTime);
	
	//ints wieder in char umwandeln
	unsplitt(klartext2, kt_splitted2);
	
	//Ausgabe
	if (output)
	{
		printf("\n\nDer Klartext lautet nun: (Anfang)\n\n");
		for (i = 0; i < 545; i++)
		{
			putchar(klartext2[i]);
		}
		printf("\n\n");
	}
	
	//freigeben
	HANDLE_ERROR(cudaEventDestroy(start));
	HANDLE_ERROR(cudaEventDestroy(stop));
	HANDLE_ERROR(cudaFree(dev_kt_splitted));
	HANDLE_ERROR(cudaFree(dev_kt_splitted2));
	HANDLE_ERROR(cudaFree(dev_gt_splitted));
	return EXIT_SUCCESS;
}
