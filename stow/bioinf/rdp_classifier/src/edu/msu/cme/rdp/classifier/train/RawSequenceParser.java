/*
 * RawSequenceParser.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 * 
 * Created on June 24, 2002, 2:13 PM
 */

package edu.msu.cme.rdp.classifier.train;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.io.*;

/**
 * A parser to parse a reader containing the raw sequences.
 * @author  wangqion
 * @version
 */
public class RawSequenceParser {
  
  public static final String delimiter = ";";
  private Pattern pattern = null;
  private Matcher matcher;
  private String regexFasta = "^>[\\s]*([\\S]*)[\t]*(.*)";  // pattern for header
  private BufferedReader reader;
  private ParsedRawSequence onDeck;  
  private ParsedRawSequence curSeq = null;
  
  /** Creates new RawSequenceParser to parse the input fasta file. */
  public RawSequenceParser(Reader in) {
    reader = new BufferedReader(in);
    pattern = Pattern.compile(regexFasta);
  }
  
  /** Returns true if there is a parsed sequence available.
   */
  public boolean hasNext() throws IOException {
    if ( onDeck != null){
      return true;
    }
    if ( (onDeck = getNextElement()) != null){
      return true;
    }
    return false;
  }
  
  /** Returns the next parsed sequence. */
  public ParsedRawSequence next() throws NoSuchElementException, IOException {
    ParsedRawSequence tmp;
    if (onDeck != null){
      tmp = onDeck;
      onDeck = null;
    }else {
      tmp = getNextElement() ;
    }
    if (tmp == null) {
      throw new NoSuchElementException();
    }
    
    return tmp;
  }
  
  
  /** Reads from the input stream and returns a parsed sequence.
   * Header format: seqID followed by a tab, followed by a list of ancestor nodes
   * Reads one line for the header and decompose the header into
   * a list of ancestors. Then reads the following lines for the sequence string
   * and modifies the sequence string.
   */   
  private ParsedRawSequence getNextElement() throws IOException{
  	  ParsedRawSequence nextSeq = null;
      String line;
      String seqstring = "";
      boolean endoffile = true;
      boolean origin = false;      
      
      while ( ( line = reader.readLine() ) != null ) {
          endoffile = false;
          matcher = pattern.matcher(line);
          if ( matcher.find()) {          	
          	List ancestors = decomposeHeader(matcher.group(2));
              if ( curSeq != null ) {
                  // save the name for the next sequence
                  nextSeq = new ParsedRawSequence(matcher.group(1), ancestors , "");
                  break;
              } else {
                  curSeq = new ParsedRawSequence(matcher.group(1), ancestors, "");
                  
              }
          }
          else {                           
              if ( curSeq != null){
                  seqstring += line;
              } else {
                  throw new IllegalArgumentException( "Error: Fasta format is expected.");
              }              
          }
      }
      
      ParsedRawSequence retval = curSeq;
      curSeq = nextSeq;
      if ( !endoffile && retval != null ) {
          seqstring = modifySequence(seqstring);
          if ( seqstring.length()>0 ) {
              retval.sequence = seqstring ;
          } else {
              throw new IllegalArgumentException("Empty Sequence: the sequence string for ID: " + retval.name + " is empty");
          }          
      }
      
      return retval;
  }
  
  /** Takes a string of sequence header( ancestors seperated by delimiter, 
   * such as ";" in our case).
   * It returns an array of ancestors with root ancestor first.
   */  
  private List decomposeHeader(String s){
    List al = new ArrayList();
   
    String[] values = s.split(delimiter);
    for ( int i = 0; i < values.length; i++){
    		al.add(values[i].trim());
    }    
    return al;
  }
  
  
  /** Modifies the sequence. Removes - and ~. It returns a string.
   */
  private String modifySequence(String s){
    try{
      StringReader in = new StringReader(s);
      StringWriter out = new StringWriter();
      int c;
      while( (c = in.read()) != -1 ){       
        if( c =='-' || c == '~' ) continue;
        out.write(c);
      }
      in.close();
      out.close();
      return out.toString();
    } catch(IOException e){
      System.out.println("In StringReader or StringWriter exception : "+e.getMessage());
    }
    return null;
  }
  
}
