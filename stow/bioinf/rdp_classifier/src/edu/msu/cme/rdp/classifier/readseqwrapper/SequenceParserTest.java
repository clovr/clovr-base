/*
 * SequenceParserTest.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 * 
 * Created on September 17, 2004, 2:22 PM
 */

package edu.msu.cme.rdp.classifier.readseqwrapper;

import junit.framework.*;
import java.io.StringReader;
import java.io.IOException;


/**
 * A test class for SequenceParser.
 * @author  wangqion
 */

public class SequenceParserTest extends TestCase {
    
    public SequenceParserTest(java.lang.String testName) {
        super(testName);
    }
    
    public static void main(java.lang.String[] args) {
        junit.textui.TestRunner.run(suite());
    }
    
    public static Test suite() {
        TestSuite suite = new TestSuite(SequenceParserTest.class);
        return suite;
    }
    
    /**
     * Test of getNextSequence method, of class edu.msu.cme.rdp.classifier.readseqwrapper.SequenceParser.
     */
    public void testGetNextSequence() throws IOException, SequenceParserException {
        System.out.println("testGetNextSequence");
        
        String seq1 = "> seq1 tt\nAAAAAAAAAGG-CCCCCCCCUn\n>   seq2\nNNaAAAAAAA11AATT~CCCCCCCCU";
        StringReader reader = new StringReader(seq1);
        SequenceParser parser = new SequenceParser( reader );
        Sequence pSeq = parser.getNextSequence();
        assertEquals( pSeq.getName(), "seq1");
        assertEquals( pSeq.getSeqString(), "aaaaaaaaaggccccccccun" );
        
        pSeq = parser.getNextSequence();
        assertEquals( pSeq.getName(), "seq2");
        assertEquals( pSeq.getSeqString(), "nnaaaaaaaaaattccccccccu" );
        pSeq = parser.getNextSequence();
        assertNull(pSeq);
        
        // now test some empty sequence
        String seqfile = ">s3\n>s4\nGGGGGGGGCCCCCCCCC\n>s5\nattcaattcgccctttgtgagtcgtat\n>s6\n>s7\ntttttttt";
        reader = new StringReader(seqfile);
        parser = new SequenceParser(reader);
        try {
            pSeq = parser.getNextSequence();
            fail("Failed to report empty sequence");
        } catch(SequenceParserException ex){
            ;
        }
        pSeq = parser.getNextSequence();
        assertEquals(pSeq.getName(), "s4");
        assertEquals(pSeq.getSeqString(), "ggggggggccccccccc");
        
        pSeq = parser.getNextSequence();
        assertEquals(pSeq.getName(), "s5");
        assertEquals(pSeq.getSeqString(), "attcaattcgccctttgtgagtcgtat");
        
        try {
            pSeq = parser.getNextSequence();
            fail("Failed to report empty sequence");
        } catch(SequenceParserException ex){
            ;
        }
        
        pSeq = parser.getNextSequence();
        assertEquals(pSeq.getName(), "s7");
        assertEquals(pSeq.getSeqString(), "tttttttt");
        
        
        String textfile = "attcaattcgccctttgtgag\ntcgtattttttttt";
        reader = new StringReader(textfile);
        parser = new SequenceParser(reader);
        
        pSeq = parser.getNextSequence();
        assertEquals(pSeq.getName(), SequenceParser.UNKNOWN_SEQ);
        assertEquals(pSeq.getSeqString(), "attcaattcgccctttgtgagtcgtattttttttt");
     
        pSeq = parser.getNextSequence();
        assertNull(pSeq);
        
        // test genbank format
        String gbfile = "LOCUS       testseq1\n" +
                        "DEFINITION  Aquificales str. CIR3017HO90.\n" +
                        "ORIGIN\n" +
                        "        1 ACGCTGGCGG CGTGCCTAAC ACATGCAAGT\n" +
                        "       31 GGTGCTGAGC\n" +
                        "//\n" +
                        "LOCUS       testseq2\n" +
                        "DEFINITION  Aquificales str. CIR3017HO90.\n" +
                        "ORIGIN\n" +
                        "        1 CGCGAACGCT GGCGGCGTGC CTAACACATG\n" +
                        "       31 AGCGGCAAAC GGGTGAGTAA CACGTGAGTA\n" +
                        "//\n";
        
        
        reader = new StringReader(gbfile);
        parser = new SequenceParser(reader);
        
        pSeq = parser.getNextSequence();
        assertEquals(pSeq.getName(), "testseq1");        
        assertEquals(pSeq.getSeqString().toUpperCase(), "ACGCTGGCGGCGTGCCTAACACATGCAAGTGGTGCTGAGC");
     
        pSeq = parser.getNextSequence();
        assertEquals(pSeq.getName(), "testseq2");        
        assertEquals(pSeq.getSeqString().toUpperCase(), "CGCGAACGCTGGCGGCGTGCCTAACACATGAGCGGCAAACGGGTGAGTAACACGTGAGTA");
     
    }
}
