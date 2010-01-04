/*
 * ParsedRawSequence.java
 * 
 * Copyright 2006 Michigan State University Board of Trustees
 * 
 * Created on June 25, 2002, 10:28 AM
 */

package edu.msu.cme.rdp.classifier.train;
import java.util.*;

/**
 * A ParsedRawSequence holds the data for a raw sequence.
 * @author  wangqion
 * @version
 */
public class ParsedRawSequence {
  
  String name;
  List ancestors;  // the highest ranked ancestor first
  String sequence;
  
  /** Creates new ParsedRawSequence. */
  public ParsedRawSequence(String n, List al, String seq) {
    name = n;
    ancestors = al;
    sequence = seq;
  }
  
   /**
   * Returns the name of the sequence.
   */
  public String getName(){
  	return name;
  }
  /**
   * Returns the sequence string.
   */
  public String getSequence(){
  	return sequence;
  }
  
  /**
   * Returns the list of the ancestor taxa, with the highest ranked taxon first.
   */
  public List getAncestors(){
  	return ancestors;
  }
  
}
