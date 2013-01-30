package rsa_java;

import java.io.*;
/**
 *
 * @author m
 */
public class Rsa_java {
    
    //Variablen für RSA
    static long p = 5; 
    static long q = 7;
    static long n = 35; // p * q
    static long e = 5;  // 1 < e < z, e teilerfremd zu z    AKA d
    static long v = 5;  // (v*e)%z = 1 
    static long z = 24; // (p-1)*(q-1)
    
    /*
     * Verschlüsseln
     */
    static char[] encrypt(String plainStr) {
        long ti = 0;

        char [] encryptedStr = new char[plainStr.length()];

        encryptedStr[plainStr.length()-1] = '\0';
        
        for(int i = 0; i < plainStr.length(); i++) {
            ti = plainStr.charAt(i)-'a';
            encryptedStr[i] = (char)(Math.pow(ti,v) % n);
        }
        
        return encryptedStr;
    }
    
    /*
     * Entschlüsseln
     */
    static char[] decrypt(String encryptedStr) {
        long ti = 0;

        char [] decryptedStr = new char[encryptedStr.length()];

        decryptedStr[encryptedStr.length()-1] = '\0';
        
        for(int i = 0; i < encryptedStr.length(); i++) {
            ti = (int)encryptedStr.charAt(i);
            decryptedStr[i] = (char)(((int)(Math.pow(ti , e) % n))+'a');
            
        }
        
        return decryptedStr;
    }
    
    //Quelle: http://andy.ekiwi.de/?p=181
    static private String loadFileToString(String fileName) throws IOException {
        File file = new File(fileName);
        StringBuilder content = new StringBuilder();
        BufferedReader reader = null;
 
        try {
            reader = new BufferedReader(new FileReader(file));
            String s = null;
 
            while ((s = reader.readLine()) != null) {
                content.append(s).append(System.getProperty("line.separator"));
            }
        } catch (FileNotFoundException e) {
            throw e;
        } catch (IOException e) {
            throw e;
        } finally {
            try {
                if (reader != null) {
                    reader.close();
                }
            } catch (IOException e) {
                throw e;
            }
        }
        return content.toString();
    }
    
    public static void main(String[] args) throws IOException {
        boolean debug = false;
        int rounds = 1;
        //String sPlainIn = "hat der alte hexenmeister\nsich doch einmal wegbegeben.\nund nun sollen seine geister\nauch nach meinem willen leben.\nseine wort und werke\nmerkt ich und den brauch,\nund mit geistesstaerke\ntu ich wunder auch.\nwalle. walle\nmanche strecke,\ndass, zum zwecke,\nwasser fliesse\nund mit reichem, vollem schwalle\nzu dem bade sich ergiesse.\nund nun komm, du alter besen.\nnimm die schlechten lumpenhuellen \nbist schon lange knecht gewesen:\nnun erfuelle meinen willen.\nauf zwei beinen stehe,\noben sei ein kopf,\neile nun und gehe\nmit dem wassertopf.\nwalle. walle\nmanche strecke,\ndass, zum zwecke,\nwasser fliesse\nund mit reichem, vollem schwalle\nzu dem bade sich ergiesse.\nseht, er laeuft zum ufer nieder,\nwahrlich. ist schon an dem flusse,\nund mit blitzesschnelle wieder\nist er hier mit raschem gusse.\nschon zum zweiten male.\nwie das becken schwillt.\nwie sich jede schale\nvoll mit wasser fuellt.\nstehe. stehe.\ndenn wir haben\ndeiner gaben\nvollgemessen. \nach, ich merk es. wehe. wehe.\nhab ich doch das wort vergessen.\nach, das wort, worauf am ende\ner das wird, was er gewesen.\nach, er laeuft und bringt behende.\nwaerst du doch der alte besen.\nimmer neue guesse\nbringt er schnell herein,\nach. und hundert fluesse\nstuerzen auf mich ein.\nnein, nicht laenger\nkann ichs lassen \nwill ihn fassen.\ndas ist tuecke.\nach. nun wird mir immer baenger.\nwelche mine. welche blicke.\no du ausgeburt der hoelle.\nsoll das ganze haus ersaufen\n\nseh ich ueber jede schwelle\ndoch schon wasserstroeme laufen.\nein verruchter besen,\nder nicht hoeren will.\nstock, der du gewesen,\nsteh doch wieder still.\nwillst am ende\ngar nicht lassen\n\nwill dich fassen,\nwill dich halten\nund das alte holz behende\nmit dem scharfen beile spalten.\nseht da kommt er schleppend wieder.\nwie ich mich nur auf dich werfe,\ngleich, o kobold, liegst du nieder \nkrachend trifft die glatte schaerfe.\nwahrlich, brav getroffen.\nseht, er ist entzwei.\nund nun kann ich hoffen,\nund ich atme frei.\nwehe. wehe.\nbeide teile\nstehn in eile\nschon als knechte\nvoellig fertig in die hoehe.\nhelft mir, ach. ihr hohen maechte.\nund sie laufen. nass und naesser\nwirds im saal und auf den stufen.\nwelch entsetzliches gewaesser.\nherr und meister. hoer mich rufen.  \nach, da kommt der meister.\nherr, die not ist gross.\ndie ich rief, die geister\nwerd ich nun nicht los.\nin die ecke,\nbesen, besen.\nseids gewesen.\ndenn als geister\nruft euch nur zu diesem zwecke,\nerst hervor der alte meister.\n";
        //String sPlainIn = "Hat der alte, hexenmeister,\n sich doch einmal wegbegeben.und nun sollen seine geister auch nach meinem willen leben.";
        String sPlainIn = ",. abcdefghijklmnopqrstuvwxyz";  //Standardstring 
        //String sPlainIn = loadFileToString("/home/m/NetBeansProjects/rsa_java/src/rsa_java/klartext");
        
        
        
        //Argumente auswerten:
        for(int a = 0; a < args.length; a++) {
            if(args[a].compareTo("-n") == 0) {          //Anzahl Runden wurde als Parameter angegeben
                rounds = Integer.parseInt(args[a+1]);
                if(debug) System.out.println("Rundenanzahl wurde angegeben: " + rounds);
            } else if (args[a].compareTo("-f") == 0) {  //Textdatei wurde angegeben
                sPlainIn = loadFileToString(args[a+1]);
                if(debug) System.out.println("Textdatei wurde als Eingabe angegeben: " + args[a+1]);
            } else if (args[a].compareTo("-d") == 0) {  //Textdatei wurde angegeben
                debug = true;
                System.out.println("DEBUG MODE ENABLED BY COMMAND LINE ARGUMENT");
            }
        }

        //Klartext vervielfachen
        if(rounds > 1) {
            if(debug) System.out.println("sPlainIn Laenge vorher: " + sPlainIn.length());
            
            StringBuilder sb = new StringBuilder();
            for(int w = 0; w < rounds; w++) {
                sb.append(sPlainIn);
            }
            sPlainIn = sb.toString();
            
            if(debug) System.out.println("sPlainIn Laenge nachher: " + sPlainIn.length());
        }
        
        //verschluesseln - dabei Leerzeichen durch { ersetzen, da { im ASCII-Code nach z das nacheste zeichen ist
        // . -> |  ,-> }
        long startCrypt = System.currentTimeMillis();
        String sCrypted     = new String( encrypt( sPlainIn.replace(' ', '{').replace('.', '|').replace(',', '}').replace('\n', '~').toLowerCase() ) );
        long stopCrypt = System.currentTimeMillis();
        
        //entschluesseln - dabei { wieder durch Leerzeichen ersetzen um den Ursprungstext zu erhalten
        long startDecrypt = System.currentTimeMillis();
        String sTemp        = new String( decrypt(sCrypted) );
        long stopDecrypt = System.currentTimeMillis();
        String sPlainOut    = sTemp.replace('{', ' ').replace('|', '.').replace('}', ',').replace('~', '\n');
        
        if(debug) System.out.println("PlainIn:  ["+ sPlainIn.length()+"]\n" + sPlainIn);
        //if(debug) System.out.println("Crypted:  ["+ sCrypted.length()+"]\n" + sCrypted);
        if(debug) System.out.println("PlainOut: ["+ sPlainOut.length()+"]\n" + sPlainOut);

        System.out.println("Zeitmessung fuer "+ sPlainOut.length() +" Zeichen - Crypt: " + (stopCrypt-startCrypt) + " ms  Decrypt: "  + (stopDecrypt-startDecrypt) + " ms");
    }
}
