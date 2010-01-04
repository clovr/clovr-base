/*
 * ParsedSequence.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 * 
 * Created on November 7, 2003, 5:46 PM
 */

package edu.msu.cme.rdp.classifier.readseqwrapper;

import java.io.StringReader;
import java.io.IOException;

/**
 * A Sequence containing the sequence information.
 * @author  wangqion
 * @version
 */
public class ParsedSequence implements Sequence{
    
    private String name ="";
    private String title ="";
    private String seqString ="";
    private String docText ="";
    private boolean reverse = false;
    private Integer goodWordCount = null; // the number of words with only valid bases
    
    private static final int MAX_ASCII = 128;
    private static char[] complementLookup = new char[MAX_ASCII];
    private static int[] charIntegerLookup = new int[MAX_ASCII];
    private static int[] intComplementLookup = new int[RNA_BASES];
    
    static {
        // initialize the integer complement look up table
        intComplementLookup[0] = 1;
        intComplementLookup[1] = 0;
        intComplementLookup[2] = 3;
        intComplementLookup[3] = 2;
        
        // initializes the char to integer mapping table
        for (int i = 0; i < MAX_ASCII; i++){
            charIntegerLookup[i] = -1;
        }
        charIntegerLookup['A'] = 0;
        charIntegerLookup['U'] = 1;
        charIntegerLookup['T'] = 1;
        charIntegerLookup['G'] = 2;
        charIntegerLookup['C'] = 3;
        
        charIntegerLookup['a'] = 0;
        charIntegerLookup['u'] = 1;
        charIntegerLookup['t'] = 1;
        charIntegerLookup['g'] = 2;
        charIntegerLookup['c'] = 3;
        
        
        // initializes the char complement look up table
        for (int i = 0; i < MAX_ASCII; i++){
            complementLookup[i] = (char)i;
        }
        complementLookup['A'] = 'u';  // A
        complementLookup['T'] = 'a';  // T
        complementLookup['U'] = 'a';  // U
        complementLookup['G'] = 'c';  // G
        complementLookup['C'] = 'g';  // C
        complementLookup['Y'] = 'r';
        complementLookup['R'] = 'y';
        complementLookup['K'] = 'm';
        complementLookup['M'] = 'k';
        complementLookup['B'] = 'v';
        complementLookup['V'] = 'b';
        complementLookup['D'] = 'h';
        complementLookup['H'] = 'd';
        complementLookup['N'] = 'n';
        
        complementLookup['a'] = 'u';  // a
        complementLookup['t'] = 'a';  // t
        complementLookup['u'] = 'a';  // u
        complementLookup['g'] = 'c';  // g
        complementLookup['c'] = 'g';  // c
        complementLookup['y'] = 'r';
        complementLookup['r'] = 'y';
        complementLookup['k'] = 'm';
        complementLookup['m'] = 'k';
        complementLookup['b'] = 'v';
        complementLookup['v'] = 'b';
        complementLookup['d'] = 'h';
        complementLookup['h'] = 'd';
        complementLookup['n'] = 'n';
    }
    
    /** Creates new ParsedSequence. */
    public ParsedSequence(String name, String seq) {
        this.name = name;
        seqString = seq;
    }
    
    /** Creates new ParsedSequence. */
    public ParsedSequence(String name, String title, String doc, String seq){
        this.name = name;
        this.title = title;
        docText = doc;
        seqString = seq;
    }
    
    /** Sets the sequence string.
     */
    protected void setSeqString(String s){
        seqString = s;
    }
    
    /** Returns the name of the sequence record.
     */
    public String getName(){
        return name;
    }
    
    /** Returns the sequence string.
     */
    public  String getSeqString(){
        return seqString;
    }
    
    
    /** Returns the title of the documentation of the sequcence record.
     */
    public  String getTitle(){
        return title;
    }
    
    /** Returns the whole documentation in text.
     */
    public String getDocumentText(){
        return docText;
    }
    
    /**
     * Returns true if the sequence string is a minus strand.
     */
    public boolean isReverse(){
        return reverse;
    }
    
    /** Returns a Sequence object whose sequence string is the reverse complement of the current rRNA sequence string. 
     */
    public Sequence getReversedSeq(){
        String reverseSeqString = getReversedSeqString(seqString);
        ParsedSequence retval = new ParsedSequence(this.name, title, docText, reverseSeqString);
        retval.reverse = true;
        return retval;
    }
    
    /** Returns the reverse complement string of the given rRNA sequence string .
     */
    public static String getReversedSeqString(String seqString){
        int len = seqString.length();
        StringBuffer reverseBuf = new StringBuffer(len);
        char base;
        
        for (int i = len - 1; i >= 0; i--){
            base = seqString.charAt(i);
            base = complementLookup[base];
            reverseBuf.append(base);
        }
        return reverseBuf.toString();
    }
     
    
  /**Returns the reverse complement of the word in an integer array format.
   */
    public static int[] getReversedWord(int [] word){
        int length = word.length;
        int[] reverseWord = new int[length];
        for (int w = 0; w < length; w++){
            reverseWord[length -1 - w] = intComplementLookup[ word[w] ];
        }
        return  reverseWord;
    }
    
  /**
   * Returns an integer representation of a single word.
   */
    public static int getWordIndex( int [] word){
        int wordIndex = 0;
        for (int w = 0; w < word.length; w++){
            wordIndex <<= 2;
            wordIndex = wordIndex & (MASK);
            wordIndex = wordIndex | word[w];
        }
        return wordIndex;
    }
    
    
    /** Fetches every overlapping word from the sequence string, 
     * changes each word to integer format and saves in an array.
     */
    public int[] createWordIndexArr() {
        int [] wordIndexArr  = new int[this.seqString.length()];
        for (int w = 0; w < wordIndexArr.length; w++){
            wordIndexArr[w] = -1;
        }
        
        StringReader in = new StringReader(this.seqString);
        int wordCount = 0;  // number of good words in a query sequence
        int count = 0;
        int wordIndex = 0;
        int charIndex = 0;
        int c;
        try {
            while ( (c = in.read()) != -1 ){
                charIndex = charIntegerLookup[c];
                
                if (charIndex == -1){
                    wordIndex = 0;
                    count = 0;
                } else {
                    count ++;
                    wordIndex <<= 2;
                    wordIndex = wordIndex & (MASK);
                    wordIndex = wordIndex | charIndex;
                    
                    if (count == WORDSIZE ){
                        wordIndexArr[wordCount] = wordIndex;
                        wordCount ++;
                        count --;
                    }
                }
            }
            this.goodWordCount = new Integer(wordCount);
        }catch(IOException ex){
            throw new RuntimeException(ex);
        }finally{
            in.close();
        }
        return wordIndexArr;
    }
    
    /**
     * Returns the number of words with valid bases.
     */
    public int getGoodWordCount(){
        if ( goodWordCount == null){
            this.createWordIndexArr();
        }
        return goodWordCount.intValue();
    }
    
   
}
