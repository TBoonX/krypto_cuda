#include <stdlib.h>
#include <stdio.h>

//Variablen
#define p 3
#define q 5
#define n 15
#define e 3
#define v 3
#define z 8
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
Dafuer werden die einzellnen chars in Integer umgewandelt (<=28) und dies halbiert und auf 3 Werte verteilt.
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
	
	long int block_length = anzahl_Zeichen/count_cores;
	
	for (i = 0 ; i < block_length; i++)
	{
		multi = x  = klartexte[i+blockIdx.x*block_length];
		for (j = 1; j < v; j++)
			x *= multi;
		
		geheimtexte[i+blockIdx.x*block_length] = x % n;
		
	}
}


__global__ void entschluessselung(long int geheimtexte[], long int klartexte_pruefung[])
{
	long int i, j, multi, x;
	
	long int block_length = anzahl_Zeichen/count_cores;

	for (i = 0 ; i < block_length; i++)
	{
		multi = x  = geheimtexte[i+blockIdx.x*block_length];
		for (j = 1; j < e; j++)
			x *= multi;
		
		klartexte_pruefung[i+blockIdx.x*block_length] = x % n;
		
	}
}

void splitt(char text[], long int numbers[])
{
	int i;
	
	//Splitte Klartext
	for (i = 0; i < anzahl_Zeichen; i++)
	{
		long int number = (int)text[i];
		int modulo, multi;
		
		//char in int beginnend mit 0
		//Sonderzeichen
		if (number == 44)		//,
			number = 27;
		else if (number == 46)		//.
			number = 28;
		else if (number == 63)		//?
			number = 29;
		else if (number == 32)		//' '
			number = 30;
		else				//a-z
			number -= 97;
		
		modulo = number % 10;
		multi = (int)(number/10);
		
		//splitt
		if (multi == 0)
		{
			numbers[i*3] = modulo;
			numbers[i*3+1] = 0;
			numbers[i*3+2] = 0;
		}
		else if (multi == 1)
		{
			numbers[i*3] = 10;
			numbers[i*3+1] = modulo;
			numbers[i*3+2] = 0;
		}
		else
		{
			numbers[i*3] = 10;
			numbers[i*3+1] = 10;
			numbers[i*3+2] = number-20;
		}
	}
}

void unsplitt(char text[], long int numbers[])
{
	int i;
	
	//Splitte Klartext
	for (i = 0; i < anzahl_Zeichen; i++)
	{
		long int number = numbers[i*3]+numbers[i*3+1]+numbers[i*3+2];
		char t;
		
		//int in char
		//Sonderzeichen
		if (number == 27)		//,
			t = ',';
		else if (number == 28)		//.
			number = t = '.';
		else if (number == 29)		//?
			t = '\n';
		else if (number == 30)		//' '
			t = ' ';
		else				//a-z
			t = (char)number+97;
			
		text[i] = t;
	}
}

int main(void) {
	int i;
	cudaEvent_t start, stop;
	float elapsedTime;
	
	char klartext[anzahl_Zeichen+1];
	char klartext2[anzahl_Zeichen+1];
	long int kt_splitted[anzahl_Zeichen*3+1];
	long int kt_splitted2[anzahl_Zeichen*3+1];
	long int *dev_kt_splitted, *dev_kt_splitted2, *dev_gt_splitted;
	
	//Debug
	printf("\na: %d   z: %d   ,: %d   .: %d   ?: %d    : %d\n\n", (int)'a', (int)'z', (int)',', (int)'.', (int)'?', (int)' ');
	

	//Klartetext erzeugen
	strcpy(klartext, "hat der alte hexenmeister?sich doch einmal wegbegeben.?und nun sollen seine geister?auch nach meinem willen leben.?seine wort und werke?merkt ich und den brauch,?und mit geistesstaerke?tu ich wunder auch.?walle. walle?manche strecke,?dass, zum zwecke,?wasser fliesse?und mit reichem, vollem schwalle?zu dem bade sich ergiesse.?und nun komm, du alter besen.?nimm die schlechten lumpenhuellen ?bist schon lange knecht gewesen:?nun erfuelle meinen willen.?auf zwei beinen stehe,?oben sei ein kopf,?eile nun und gehe?mit dem wassertopf.?walle. walle?manche strecke,?dass, zum zwecke,?wasser fliesse?und mit reichem, vollem schwalle?zu dem bade sich ergiesse.?seht, er laeuft zum ufer nieder,?wahrlich. ist schon an dem flusse,?und mit blitzesschnelle wieder?ist er hier mit raschem gusse.?schon zum zweiten male.?wie das becken schwillt.?wie sich jede schale?voll mit wasser fuellt.?stehe. stehe.?denn wir haben?deiner gaben?vollgemessen. ?ach, ich merk es. wehe. wehe.?hab ich doch das wort vergessen.?ach, das wort, worauf am ende?er das wird, was er gewesen.?ach, er laeuft und bringt behende.?waerst du doch der alte besen.?immer neue guesse?bringt er schnell herein,?ach. und hundert fluesse?stuerzen auf mich ein.?nein, nicht laenger?kann ichs lassen ?will ihn fassen.?das ist tuecke.?ach. nun wird mir immer baenger.?welche mine. welche blicke.?o du ausgeburt der hoelle.?soll das ganze haus ersaufen??seh ich ueber jede schwelle?doch schon wasserstroeme laufen.?ein verruchter besen,?der nicht hoeren will.?stock, der du gewesen,?steh doch wieder still.?willst am ende?gar nicht lassen??will dich fassen,?will dich halten?und das alte holz behende?mit dem scharfen beile spalten.?seht da kommt er schleppend wieder.?wie ich mich nur auf dich werfe,?gleich, o kobold, liegst du nieder ?krachend trifft die glatte schaerfe.?wahrlich, brav getroffen.?seht, er ist entzwei.?und nun kann ich hoffen,?und ich atme frei.?wehe. wehe.?beide teile?stehn in eile?schon als knechte?voellig fertig in die hoehe.?helft mir, ach. ihr hohen maechte.?und sie laufen. nass und naesser?wirds im saal und auf den stufen.?welch entsetzliches gewaesser.?herr und meister. hoer mich rufen.  ?ach, da kommt der meister.?herr, die not ist gross.?die ich rief, die geister?werd ich nun nicht los.?in die ecke,?besen, besen.?seids gewesen.?denn als geister?ruft euch nur zu diesem zwecke,?erst hervor der alte meister.?                                                                                                                                                                                                                                                                                                    ");

	printf("\n\nDer Klartext ist %d Zeichen lang.\n", sizeof(klartext)/sizeof(char));
	
	//Chars in ints aufsplitten
	splitt(klartext, kt_splitted);

	//Variablen der Zeitmessung erstellen
	HANDLE_ERROR(cudaEventCreate(&start));
	HANDLE_ERROR(cudaEventCreate(&stop));

	//Start Zeitmessung
	HANDLE_ERROR(cudaEventRecord(start, 0));

	//allokieren
	HANDLE_ERROR(cudaMalloc((void **)&dev_kt_splitted, sizeof(kt_splitted)));
	HANDLE_ERROR(cudaMalloc((void **)&dev_kt_splitted2, sizeof(kt_splitted2)));
	HANDLE_ERROR(cudaMalloc((void **)&dev_gt_splitted, sizeof(kt_splitted)));

	//kopieren
	HANDLE_ERROR(cudaMemcpy(dev_kt_splitted, kt_splitted, sizeof(kt_splitted), cudaMemcpyHostToDevice));

	//Block festlegen
	dim3 blocks(count_cores, 1);

	//verschluesseln
	verschluessselung<<<blocks, 1>>>(dev_kt_splitted, dev_gt_splitted);

	//zurueckkopieren
	//HANDLE_ERROR(cudaMemcpy(geheimtexte, dev_geheimtexte, sizeof(geheimtexte), cudaMemcpyDeviceToHost));
	
	//entschluesseln
	entschluessselung<<<blocks, 1>>>(dev_gt_splitted, dev_kt_splitted2);
	
	//zurueckkopieren
	HANDLE_ERROR(cudaMemcpy(kt_splitted2, dev_kt_splitted2, sizeof(kt_splitted2), cudaMemcpyDeviceToHost));
		
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
		putchar(klartext[i]);
	}
	printf("\n\n");

	//freigeben
	HANDLE_ERROR(cudaEventDestroy(start));
	HANDLE_ERROR(cudaEventDestroy(stop));

	return EXIT_SUCCESS;
}
