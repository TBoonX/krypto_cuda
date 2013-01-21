#include <stdlib.h>
#include <stdio.h>
//#include <math.h>

//#define DEBUG

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
	
	long int block_length = anzahl_Texte/count_cores;
	
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
	
	char klartext[anzahlZeichen+1];
	char klartext2[anzahlZeichen+1];
	

	//Klartetext erzeugen
	klartext = "hat der alte hexenmeister
sich doch einmal wegbegeben.
und nun sollen seine geister
auch nach meinem willen leben.
seine wort und werke
merkt ich und den brauch,
und mit geistesstaerke
tu ich wunder auch.
walle. walle
manche strecke,
dass, zum zwecke,
wasser fliesse
und mit reichem, vollem schwalle
zu dem bade sich ergiesse.
und nun komm, du alter besen.
nimm die schlechten lumpenhuellen;
bist schon lange knecht gewesen:
nun erfuelle meinen willen.
auf zwei beinen stehe,
oben sei ein kopf,
eile nun und gehe
mit dem wassertopf.
walle. walle
manche strecke,
dass, zum zwecke,
wasser fliesse
und mit reichem, vollem schwalle
zu dem bade sich ergiesse.
seht, er laeuft zum ufer nieder,
wahrlich. ist schon an dem flusse,
und mit blitzesschnelle wieder
ist er hier mit raschem gusse.
schon zum zweiten male.
wie das becken schwillt.
wie sich jede schale
voll mit wasser fuellt.
stehe. stehe.
denn wir haben
deiner gaben
vollgemessen. 
ach, ich merk es. wehe. wehe.
hab ich doch das wort vergessen.
ach, das wort, worauf am ende
er das wird, was er gewesen.
ach, er laeuft und bringt behende.
waerst du doch der alte besen.
immer neue guesse
bringt er schnell herein,
ach. und hundert fluesse
stuerzen auf mich ein.
nein, nicht laenger
kann ichs lassen;
will ihn fassen.
das ist tuecke.
ach. nun wird mir immer baenger.
welche mine. welche blicke.
o du ausgeburt der hoelle.
soll das ganze haus ersaufen?
seh ich ueber jede schwelle
doch schon wasserstroeme laufen.
ein verruchter besen,
der nicht hoeren will.
stock, der du gewesen,
steh doch wieder still.
willst am ende
gar nicht lassen?
will dich fassen,
will dich halten
und das alte holz behende
mit dem scharfen beile spalten.
seht da kommt er schleppend wieder.
wie ich mich nur auf dich werfe,
gleich, o kobold, liegst du nieder;
krachend trifft die glatte schaerfe.
wahrlich, brav getroffen.
seht, er ist entzwei.
und nun kann ich hoffen,
und ich atme frei.
wehe. wehe.
beide teile
stehn in eile
schon als knechte
voellig fertig in die hoehe.
helft mir, ach. ihr hohen maechte.
und sie laufen. nass und naesser
wirds im saal und auf den stufen.
welch entsetzliches gewaesser.
herr und meister. hoer mich rufen.  
ach, da kommt der meister.
herr, die not ist gross.
die ich rief, die geister
werd ich nun nicht los.
in die ecke,
besen, besen.
seids gewesen.
denn als geister
ruft euch nur zu diesem zwecke,
erst hervor der alte meister.
                                                                                                                                                                                                  ";

	printf("\n\nDer Klartext ist %d Zeichen lang.\n", sizeof(klartext)/sizeof(char));

	HANDLE_ERROR(cudaEventCreate(&start));
	HANDLE_ERROR(cudaEventCreate(&stop));



	HANDLE_ERROR(cudaEventRecord(start, 0));

        //HANDLE_ERROR(cudaMalloc((void **)&dev_klartexte, sizeof(klartexte)));
        //HANDLE_ERROR(cudaMalloc((void **)&dev_geheimtexte, sizeof(geheimtexte)));
        //HANDLE_ERROR(cudaMalloc((void **)&dev_klartexte_pruefung, sizeof(klartexte_pruefung)));

        //HANDLE_ERROR(cudaMemcpy(dev_klartexte, klartexte, sizeof(klartexte), cudaMemcpyHostToDevice));

	dim3 blocks(count_cores, 1);

	//verschluessselung<<<blocks, 1>>>(dev_klartexte, dev_geheimtexte);

        //HANDLE_ERROR(cudaMemcpy(geheimtexte, dev_geheimtexte, sizeof(geheimtexte), cudaMemcpyDeviceToHost));
	
	//entschluessselung<<<blocks, 1>>>(dev_geheimtexte, dev_klartexte_pruefung);
	
	//HANDLE_ERROR(cudaMemcpy(klartexte_pruefung, dev_klartexte_pruefung, sizeof(klartexte_pruefung), cudaMemcpyDeviceToHost));
		

	HANDLE_ERROR(cudaEventRecord(stop, 0));
	HANDLE_ERROR(cudaEventSynchronize(stop));

	HANDLE_ERROR(cudaEventElapsedTime(&elapsedTime, start, stop));
	printf("Elapsed time: %3.1f ms\n", elapsedTime);



	HANDLE_ERROR(cudaEventDestroy(start));
	HANDLE_ERROR(cudaEventDestroy(stop));
	

	return EXIT_SUCCESS;
}
