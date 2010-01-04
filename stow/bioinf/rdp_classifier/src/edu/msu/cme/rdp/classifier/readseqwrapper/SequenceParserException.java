/*
 * SequenceParserException.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 * 
 * Created on November 7, 2003, 5:47 PM
 */

package edu.msu.cme.rdp.classifier.readseqwrapper;

/**
 * A class to handle the exception during sequence parsing.
 * @author  wangqion
 */
public class SequenceParserException extends Exception {
    
    /**
     * Creates a new instance of SequenceParserException with detail message.
     */
    public SequenceParserException(String msg) {
       super(msg);
    }           
  
}

