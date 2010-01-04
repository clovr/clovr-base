/*
 * Sequence.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 * 
 * Created on November 7, 2003, 5:41 PM
 */

package edu.msu.cme.rdp.classifier.readseqwrapper;

/**
 * An abstract class, providing an interface for accessing a sequence.
 * @author  wangqion
 */
public interface Sequence {
    
	/** The number of rna bases (ATGC). Initially set to 4. */
	static final int RNA_BASES = 4; 
	/** The size of a word. Initially set to 8. */
    static final int WORDSIZE = 8;    
    /** The mask for converting a string to integer */
    static final int MASK = ( 1 << (WORDSIZE*2) ) -1;
    
    /** Returns the name of the sequence record.    */
    String getName();    
    /** Returns the title of the sequence record.     */
    String getTitle();
    /** Returns the sequence string of the sequence record.   */
    String getSeqString();  
    /** Returns a Sequence object whose sequence string is the 
     * reverse complement of the current sequence string. 
     */
    Sequence getReversedSeq();       
    /** Fetches every overlapping word from the sequence string, 
     * changes each word to integer format and saves in an array.
     */
    int[] createWordIndexArr();
    /** Returns the number of words without invalid base(s). */
    int getGoodWordCount();
    /** Returns true if the sequence string is a minus strand.   */
    boolean isReverse();    
}

