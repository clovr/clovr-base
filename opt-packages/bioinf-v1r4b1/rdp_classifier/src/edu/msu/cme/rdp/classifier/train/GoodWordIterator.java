/*
 * GoodWordIterator.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 * Created on June 26, 2002, 12:27 PM
 */

package edu.msu.cme.rdp.classifier.train;

import java.util.*;
import java.io.*;

/**
 * A GoodWordIterator creates a list of valid words from the input string.
 * @author  wangqion
 */
public class GoodWordIterator {
    private int curIndex = 0;
    private int numOfWords = 0;
    private int [] wordIndexArr;
    static final int WORDSIZE = 8;    // the size of a word
    static final int MASK = ( 1 << (WORDSIZE*2) ) -1;
    static final int MAX_ASCII = 128;
    
    private static int[] charIntegerLookup = new int[MAX_ASCII];
    
    static {
        // initialize the char to integer mapping table
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
        
    }
    
    
    /** Creates a new instance of GoodWordIterator */
    public GoodWordIterator(String seq) throws IOException {
        wordIndexArr = new int[seq.length()];
        createWordIndex(seq);
    }
    
    /** Returns true if the iteration has more good element on deck.
     */
    public boolean hasNext() {
        if ( curIndex < numOfWords){
            return true;
        }
        else{
            return false;
        }
    }
    
    /** Returns the next good element in the iteration. */
    public int next() throws NoSuchElementException{
        int tmp;
        if ( hasNext()){
            tmp = curIndex;
            curIndex ++;
            return wordIndexArr[tmp];
        } else{
            throw new NoSuchElementException();
        }
    }
    
    
    /** Fetches every overlapping word, change the string to integer and saves in an array.
     */
    private void createWordIndex(String seq) throws IOException{
        StringReader in = new StringReader(seq);
        int count = 0;
        int wordIndex = 0;
        int charIndex = 0;
        int c;
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
                    wordIndexArr[numOfWords] = wordIndex;
                    numOfWords ++;
                    count --;
                }
            }
        }
        in.close();
    }
    
    /** Returns the size of word.
     */
    int getWordsize(){
        return WORDSIZE;
    }
    
    /** Returns the mask.
     */
    int getMask(){
        return MASK;
    }
    
    /** Returns the number of unique words.
     */
    int getNumofWords(){
        return numOfWords;
    }
    
    /** Reset the current index to 0.
     */
    void resetCurIndex(){
        curIndex = 0;
    }
    
    
}
