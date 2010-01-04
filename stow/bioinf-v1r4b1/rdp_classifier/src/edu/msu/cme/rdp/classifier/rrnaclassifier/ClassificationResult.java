/*
 * ClassificationResult.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 * 
 * Created on October 29, 2003, 4:51 PM
 */

package edu.msu.cme.rdp.classifier.rrnaclassifier;
import java.util.List;
import edu.msu.cme.rdp.classifier.readseqwrapper.Sequence;

/**
 * This class holds the classification results for a query sequence.
 * @author  wangqion
 */
public class ClassificationResult {
  Sequence pSeq;
  List assignments;
  HierarchyVersion hVersion;
  
  /** Creates a new instance of ClassificationResult. 
   * This class holds the classification results for a query sequence.
   */
  ClassificationResult(Sequence p, List a, HierarchyVersion version) {
    pSeq = p;
    assignments = a;
    hVersion = version;
  }
  
  /**
   * Returns the query sequence 
   */
  public Sequence getSequence(){
    return pSeq;
  }
  /**
   * Returns a list of RankAssignments. The assignments are returned in 
   * the order of taxonomic ranks, from the highest to the lowest. 
   */
  public List getAssignments(){
    return assignments;
  }
  
  /** Returns the training set number of the taxonomy hierarchy from of the training file.
   */
  public int getTrainsetNo(){
  	return hVersion.getTrainsetNo();
  }
  
  /** Returns the version of the taxonomy hierarchy from of the training file.
   */
  public HierarchyVersion getHierarchyTrainsetNo(){
      return hVersion;
  }
  
}
