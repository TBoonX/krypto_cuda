/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package rsa_java;

/**
 *
 * @author m
 */
public class Rsa_java {
    
    static long p = 5;//5;  // vorher 3 
    static long q = 7;//11;
    static long n = 35;//55; // p * q
    static long e = 5;//27; // 1 < e < z, e teilerfremd zu z
    static long v = 5;//3;  // (v*e)%z = 1 -> v = 
    static long z = 24;//40; // (p-1)*(q-1) 4 * 10
    
    /**
     * @param args the command line arguments
     */
    
    
    static char[] encrypt(String plainStr) {
        long ti = 0;

        
        //String encryptedStr = new String();
//        char [] encryptedStr = new char[plainStr.length()];
        char [] encryptedStr = new char[plainStr.length()];
//        encryptedStr[plainStr.length()-1] = '\0';
        encryptedStr[plainStr.length()-1] = '\0';
        
//        for(int i = 0; i < plainStr.length()-2; i++) {
        for(int i = 0; i < plainStr.length(); i++) {
            ti = plainStr.charAt(i)-'a';
            
            //Leerzeichen durch { ersetzen
 /*           if((plainStr.charAt(i)-'a') == 10) {
                ti = 1;
                System.out.println("bracket: " + (plainStr.charAt(i)-'a') + "ti neu: " + ti);
            }
   */         
            encryptedStr[i] = (char)(Math.pow(ti,v) % n);
            
        
        }
        
        return encryptedStr;
    }
    
    static char[] decrypt(String encryptedStr) {
        long ti = 0;
        
        //String encryptedStr = new String();
//        char [] decryptedStr = new char[encryptedStr.length()];
        char [] decryptedStr = new char[encryptedStr.length()];
//        decryptedStr[encryptedStr.length()-1] = '\0';
        decryptedStr[encryptedStr.length()-1] = '\0';
        
//        for(int i = 0; i < encryptedStr.length()-2; i++) {
        for(int i = 0; i < encryptedStr.length(); i++) {
            //encryptedStr[i] = plainStr.charAt(i)^2;
            ti = (int)encryptedStr.charAt(i);
            //System.out.print(plainStr.charAt(i) + " " + ti +" ");
        
            decryptedStr[i] = (char)(((int)(Math.pow(ti , e) % n))+'a');
            
            if((char)decryptedStr[i] == '{') {
                //System.out.println(" bracket gefunden " + (char)(decryptedStr[i]-113)); //ASCII: ' '==10 '{'==123 123-10 = 113 
     //           decryptedStr[i] -= 113;
            }
            System.out.print(((int)(Math.pow(ti , e) % n)) + " ");
            
        }
        System.out.println();
        
        
        return decryptedStr;
    }
    
    
    public static void main(String[] args) {
        boolean debug = true;
        //String sPlainIn = "hat der alte hexenmeister\nsich doch einmal wegbegeben.\nund nun sollen seine geister\nauch nach meinem willen leben.\nseine wort und werke\nmerkt ich und den brauch,\nund mit geistesstaerke\ntu ich wunder auch.\nwalle. walle\nmanche strecke,\ndass, zum zwecke,\nwasser fliesse\nund mit reichem, vollem schwalle\nzu dem bade sich ergiesse.\nund nun komm, du alter besen.\nnimm die schlechten lumpenhuellen \nbist schon lange knecht gewesen:\nnun erfuelle meinen willen.\nauf zwei beinen stehe,\noben sei ein kopf,\neile nun und gehe\nmit dem wassertopf.\nwalle. walle\nmanche strecke,\ndass, zum zwecke,\nwasser fliesse\nund mit reichem, vollem schwalle\nzu dem bade sich ergiesse.\nseht, er laeuft zum ufer nieder,\nwahrlich. ist schon an dem flusse,\nund mit blitzesschnelle wieder\nist er hier mit raschem gusse.\nschon zum zweiten male.\nwie das becken schwillt.\nwie sich jede schale\nvoll mit wasser fuellt.\nstehe. stehe.\ndenn wir haben\ndeiner gaben\nvollgemessen. \nach, ich merk es. wehe. wehe.\nhab ich doch das wort vergessen.\nach, das wort, worauf am ende\ner das wird, was er gewesen.\nach, er laeuft und bringt behende.\nwaerst du doch der alte besen.\nimmer neue guesse\nbringt er schnell herein,\nach. und hundert fluesse\nstuerzen auf mich ein.\nnein, nicht laenger\nkann ichs lassen \nwill ihn fassen.\ndas ist tuecke.\nach. nun wird mir immer baenger.\nwelche mine. welche blicke.\no du ausgeburt der hoelle.\nsoll das ganze haus ersaufen\n\nseh ich ueber jede schwelle\ndoch schon wasserstroeme laufen.\nein verruchter besen,\nder nicht hoeren will.\nstock, der du gewesen,\nsteh doch wieder still.\nwillst am ende\ngar nicht lassen\n\nwill dich fassen,\nwill dich halten\nund das alte holz behende\nmit dem scharfen beile spalten.\nseht da kommt er schleppend wieder.\nwie ich mich nur auf dich werfe,\ngleich, o kobold, liegst du nieder \nkrachend trifft die glatte schaerfe.\nwahrlich, brav getroffen.\nseht, er ist entzwei.\nund nun kann ich hoffen,\nund ich atme frei.\nwehe. wehe.\nbeide teile\nstehn in eile\nschon als knechte\nvoellig fertig in die hoehe.\nhelft mir, ach. ihr hohen maechte.\nund sie laufen. nass und naesser\nwirds im saal und auf den stufen.\nwelch entsetzliches gewaesser.\nherr und meister. hoer mich rufen.  \nach, da kommt der meister.\nherr, die not ist gross.\ndie ich rief, die geister\nwerd ich nun nicht los.\nin die ecke,\nbesen, besen.\nseids gewesen.\ndenn als geister\nruft euch nur zu diesem zwecke,\nerst hervor der alte meister.\n";
        String sPlainIn = "hat der alte hexenmeister\nsich doch einmal wegbegeben.\nund nun sollen seine geister\nauch nach meinem willen leben.";
        //String sPlainIn = "{ abcdefghijklmnopqrstuvwxyz";
       
  
        
        String sCrypted     = new String( encrypt( sPlainIn.replace(' ', '{') ) );
        String sTemp        = new String( decrypt(sCrypted) );
        String sPlainOut    = new String( sTemp.replace('{', ' '));
        
        if(debug) System.out.println("PlainIn:  ["+ sPlainIn.length()+"]\n" + sPlainIn);
        if(debug) System.out.println("Crypted:  ["+ sCrypted.length()+"]\n" + sCrypted);
        if(debug) System.out.println("PlainOut: ["+ sPlainOut.length()+"]\n" + sPlainOut);
    
    
    
    
    }
}