/*
 * SequenceParser.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 * 
 * Created on November 7, 2003, 5:42 PM
 */

package edu.msu.cme.rdp.classifier.readseqwrapper;

import java.io.*;
import java.util.regex.*;

/**
 * A class whick parses the input sequences and creates Sequence objects.
 * @author  wangqion
 */
public class SequenceParser {
    
    BufferedReader reader;
    Pattern pattern = null;
    Matcher matcher;
    String regexFasta = "^>[\\s]*([\\S]*)[\\s]*(.*)";  // pattern for fasta format
   
    String regexGenbank = "LOCUS\\s+([^ ]*)(.*)"; // pattern for Genbank format
   
    String regexEmbl = "ID\\s+([^ ]*)"; // pattern for EMBL format
    private static final String TEXT_FORMAT = "text";
    static final String UNKNOWN_SEQ = "unknown";
    
    private ParsedSequence curSeq = null;
  
    private String formatError = null;
    private String format = null;
    private String fastaErrorMsg = "Fasta format required, sequence header should start with '>'";
    private String genbankErrorMsg = "Genbank format required, sequence header should start with LOCUS and end with //";
    private String emblErrorMsg = "Embl format required, sequence header should start with ID and end with //";
    private static final int MAX_ASCII = 128;
    private static char[] charLookup = new char[MAX_ASCII];
    
    static {
        for (int i = 0; i < MAX_ASCII; i++){
            charLookup[i] = ' ';
        }
        
        for (int i = 65; i <= 90; i++){
            charLookup[i] = (char)(i+32);
        }
        
        for (int i = 97; i <= 122 ; i++){
            charLookup[i] = (char)i;
        }
        
    }
    
    /** Creates new SequenceParser to parse the sequences from an InputStream.
     * supported formats: Fasta, Genbank, EMBL or free text for single sequence. 
     */
    public SequenceParser(InputStream inStream) throws IOException, SequenceParserException{
        this.reader = new BufferedReader( new InputStreamReader(inStream) );
        this.init();
    }
    
    /** Creates new SequenceParser to parse the sequences from a Reader.
     * supported formats: Fasta, Genbank, EMBL or free text for single sequence.
     */
    public SequenceParser( Reader rhs ) throws IOException, SequenceParserException {
        if ( !(rhs instanceof  BufferedReader)) {
            this.reader = new BufferedReader( rhs );
        } else {
            this.reader = (BufferedReader)rhs;
        }
        this.init();
    }
    
    /**
     * Checks the format of the input. 
     * @throws exception if the format is not one of the 
     * supported formats: Fasta, Genbank, EMBL or free text for single sequence.
     */
    private void init() throws IOException, SequenceParserException {
        try {
            if( reader.markSupported() ) {
                //System.out.println("SequenceParser: markSupported:true: before mark(0)");
                reader.mark(5000);  // assume a sequence is less than 5000 bps
            }
           
            setSequenceFormat();
            if( reader.markSupported() ) {
                try {
                		reader.reset();  
                }catch (IOException e){
                		throw new SequenceParserException("Fasta, GenBank or EMBL are the only formats that our classifier can currently process.");
                }
            }
           
        } catch(PatternSyntaxException pse){
            throw new SequenceParserException("There is a problem with the regular expression! ");
        }
    }
    
    /**
     * Checks the format of the first input sequence. It assumes that all the sequences from the input
     * share the same format.
     */
    private void setSequenceFormat() throws IOException, SequenceParserException {
        String line = null;
        Matcher aMatcher = null;
        
        while ((line = reader.readLine()) != null) {
            //check for fasta format
            pattern = Pattern.compile(regexFasta);
            aMatcher = pattern.matcher(line);
            if ( aMatcher.find() ) {
                this.format = "fasta";
                this.formatError = this.fastaErrorMsg;
                break;
            }
            //check for genbank format
            pattern = Pattern.compile(regexGenbank);
            aMatcher = pattern.matcher(line);
            if ( aMatcher.find() ) {
                this.format = "genbank";
                this.formatError = this.genbankErrorMsg;
                break;
            }
            //check for embl format
            pattern = Pattern.compile(regexEmbl);
            aMatcher = pattern.matcher(line);
            if ( aMatcher.find() ) {
                this.format = "embl";
                this.formatError = this.emblErrorMsg;
                break;
            }
        }
        if ( line == null ) {
            // throw new SequenceParserException("Fasta, GenBank or EMBL are the only formats that our classifier can currently process.");
            this.format = TEXT_FORMAT;
        }
        
    }
    
    /** Returns the next available ParsedSequence from input. If no sequence is available, then null is returned. 
     */
    public ParsedSequence getNextSequence() throws IOException, SequenceParserException{
        ParsedSequence nextSeq = null;
        String line;
        String seqstring = "";
        boolean endoffile = true;
        boolean origin = false;
        
        
        while ( ( line = reader.readLine() ) != null ) {
            endoffile = false;
            matcher = pattern.matcher(line);
            if ( matcher.find()) {
                if ( curSeq != null ) {
                    // save the name for the next sequence
                    nextSeq = new ParsedSequence(matcher.group(1), "","", "");
                    break;
                } else {
                    curSeq = new ParsedSequence(matcher.group(1), "","", "");
                    
                }
            }
            else {
                if ( format.equals("genbank") ) {
                    // the line may contain spaces or data after "ORIGIN"
                    if ( line.startsWith("ORIGIN") ) { //sequence starts after ORIGIN line
                        origin = true;
                        continue;
                    } else if ( line.trim().equals("//") ) {
                        origin = false;
                        continue;
                    }
                } else if ( format.trim().equals("embl") ) {
                    if ( line.startsWith("SQ ") ) { //sequence starts after SQ line
                        origin = true;
                        continue;
                    } else if ( line.trim().equals("//") ) {
                        origin = false;
                        continue;
                    }
                } else if ( format.trim().equals("fasta") ) {
                    origin = true;
                }
                
                if ( origin ) {
                    if ( curSeq != null){
                        seqstring += line;
                    } else {
                        throw new SequenceParserException( this.formatError );
                    }
                }else if ( format.equals(TEXT_FORMAT)){   // the text format does not have origin
                    if ( curSeq == null){
                        curSeq = new ParsedSequence(UNKNOWN_SEQ, "");
                    }
                    seqstring += line;
                }
            }
        }
        
        ParsedSequence retval = curSeq;
        curSeq = nextSeq;
        if ( !endoffile && retval != null ) {
            seqstring = modifySequence(seqstring);          
            retval.setSeqString(seqstring) ;
        }
        
        return retval;
    }
    
    /**
     * Closes the reader.
     */
    public void close() throws IOException{
        reader.close();
    }
    
    /** Modifies the sequence string.
     * Removes -, ~ and digits. Returns a string.
     */
    private String modifySequence(String s) throws IOException {
        StringReader in = new StringReader(s);
        StringWriter out = new StringWriter();
        int c;
        while( (c = in.read()) != -1 ) {
            c = charLookup[c];
            if ( c == ' ' ) continue;
            out.write(c);
        }
        in.close();
        out.close();
        return out.toString();
    }
    
}
