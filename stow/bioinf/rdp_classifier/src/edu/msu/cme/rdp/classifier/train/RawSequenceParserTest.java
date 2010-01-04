/*
 * RawSequenceParserTest.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 *
 * Created on June 27, 2002, 6:48 PM
 */

package edu.msu.cme.rdp.classifier.train;

import junit.framework.*;
import java.io.*;

/**
 * A test class for RawSequenceParser.
 * @author wangqion
 */
public class RawSequenceParserTest extends TestCase {
  
  public RawSequenceParserTest(java.lang.String testName) {
    super(testName);
  }
  
  public static void main(java.lang.String[] args) {
    junit.textui.TestRunner.run(suite());
  }
  
  /**
   * Tests RawSequenceParser next() method.
   */
  public void testNext() throws FileNotFoundException, IOException{
    System.out.println("testNext()");  
    InputStream aStream = System.class.getResourceAsStream("/test/classifier/testSeqParser.fasta");
    Reader in = new InputStreamReader( aStream );
    
    RawSequenceParser parser = new RawSequenceParser(in);
    boolean next = parser.hasNext();
    assertTrue(next);
    // test the first sequence
    ParsedRawSequence pSeq = parser.next();
    String name = "X53199";
    assertEquals(name, pSeq.name);
    assertEquals("AZOSPIRILLUM_GROUP", (String) pSeq.ancestors.get(4));  
    assertEquals("PROTEOBACTERIA", (String) pSeq.ancestors.get(2));   
    assertEquals("GAEA", (String) pSeq.ancestors.get(0) );
    
    //test the last sequence
    parser.next();
    pSeq = parser.next();
    name = "AB002485";
    assertEquals(name, pSeq.name);
    assertEquals("M.RRR_SUBGROUP", (String) pSeq.ancestors.get(5) );
    assertEquals("TTTT_GROUP", (String) pSeq.ancestors.get(4) );
    assertEquals("BELTA_SUBDIVISION", (String) pSeq.ancestors.get(3) );
    assertEquals("GAEA", (String) pSeq.ancestors.get(0) );
    String sequence = "AAAAUAtttAGUCCCCCCCCUG";
    assertEquals(sequence, pSeq.sequence);
    assertTrue(!parser.hasNext());
  }
  
  

  public static Test suite() {
    TestSuite suite = new TestSuite(RawSequenceParserTest.class);
    
    return suite;
  }
  
 
}
