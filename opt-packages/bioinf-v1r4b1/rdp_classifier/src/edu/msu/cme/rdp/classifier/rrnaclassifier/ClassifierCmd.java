/*
 * Created on Feb 20, 2006
 *
 */
/**
 * This is a simple command line class to do classification.
 */
package edu.msu.cme.rdp.classifier.rrnaclassifier;

import java.io.BufferedWriter;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.Iterator;

import edu.msu.cme.rdp.classifier.readseqwrapper.ParsedSequence;
import edu.msu.cme.rdp.classifier.readseqwrapper.SequenceParser;
import edu.msu.cme.rdp.classifier.readseqwrapper.SequenceParserException;


/**
 * This is the command line class to do the classification.
 * @author wangqion
 */
public class ClassifierCmd {


    /** It classifies query sequences from the input file.
     * If the property file of the mapping of the training files is not null, the default property file will be override.
     * The classification results will be writen to the output file.
     */
    public void doClassify( String inputFile, String outFile, String propfile) throws IOException, TrainingDataException, SequenceParserException{
	    	if ( propfile != null){
	    		ClassifierFactory.setDataProp(propfile);
	    	}
    		ClassifierFactory factory = ClassifierFactory.getFactory();                
        Classifier aClassifier = factory.createClassifier();       
        SequenceParser parser = new SequenceParser(new FileInputStream(inputFile));
        BufferedWriter wt = new BufferedWriter(new FileWriter(outFile));        
        ParsedSequence pSeq = null;
        
        try{
            while (true){
                try {
                    pSeq = parser.getNextSequence();
                    
                    if ( pSeq == null ) {
                        break;
                    }                  
                    ClassificationResult result = aClassifier.classify(pSeq);                   
                    
                    displayResult(result, wt);
                    
                } catch ( ShortSequenceException e){
                    System.out.println( e.getMessage());
                } catch (Exception e){
                    e.printStackTrace();
                }
            }
        }finally {
            parser.close();
            wt.close();
        }
       
    }
    
    /**
     * Writes the classificatio results of one sequence to a writer.
     */
    private void displayResult(ClassificationResult result, Writer wt) throws IOException{  
        StringBuffer buf = new StringBuffer();      
        buf.append(">" + result.getSequence().getName()+ " reverse=" + result.getSequence().isReverse() +"\n");
        
        Iterator it =  result.getAssignments().iterator();
        RankAssignment assign ;
        while (it.hasNext()){
            assign = (RankAssignment) it.next();           
            buf.append(assign.getName() + "; " + assign.getConfidence() + "; ");            
        }       
        buf.append("\n");       
        wt.write(buf.toString());        
    }
    
    /**
     * Prints the license information to std err.
     */
    public static void printLicense(){
     	  String license = "Copyright 2006 Michigan State University Board of Trustees.\n\n" + 
  	  "This program is free software; you can redistribute it and/or modify it under the " +
  	  "terms of the GNU General Public License as published by the Free Software Foundation; " +
  	  "either version 2 of the License, or (at your option) any later version.\n\n" +   	  
  	  "This program is distributed in the hope that it will be useful, " +
  	  "but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY " +
  	  "or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.\n\n" +
  	  "You should have received a copy of the GNU General Public License along with this program; " +
  	  "if not, write to the Free Software Foundation, Inc., 59 Temple Place, "+
  	  "Suite 330, Boston, MA 02111-1307 USA\n\n" +
  	  "Authors's mailng address:\n" +
  	  "Center for Microbial Ecology\n" +
  	  "2225A Biomedical Physical Science\n" +
  	  "Michigan State University\n" +
  	  "East Lansing, Michigan USA 48824-4320\n" +
  	  "E-mail: James R. Cole at colej@msu.edu\n" +
        "\tQiong Wang at wangqion@msu.edu\n" +
        "\tGeorge M. Garrity at garrity@msu.edu\n" +
        "\tJames M. Tiedje at tiedjej@msu.edu\n\n";
     	  
     	  System.err.println(license);
     }
    
    /**
     * This is the main method to do classification.
     * <p>Usage: java ClassifierCmd queryFile outputFile [property file].
     * <br>
     * queryFile can be one of the following formats: Fasta, Genbank and EMBL. 
     * <br>
     * outputFile will be used to save the classification output.
     * <br>
     * property file contains the mapping of the training files.
     * <br>
     * Note: the training files and the property file should be in the same directory.
     * The default property file is set to data/classifier/rRNAClassifier.properties.
     */
    public static void main(String[] args) throws Exception{
        if (args.length < 2) {
            System.out.println("Usage: java ClassifierCmd <queryFile> <outputFile> [propertyFile]");
            System.err.println("Command line arguments:");
            System.out.println("--queryFile contains sequences in one of the following formats: Fasta, Genbank and EMBL."); 
            System.err.println("--outputFile specifies the output file name.");
            System.out.println("--propertyFile contains the mapping of the training files.");
            System.out.println("   Note: the training files and the property file should be in the same directory.");
            System.out.println("   The default property file is set to data/classifier/rRNAClassifier.properties.");              
            System.exit(-1);
        }
        
        ClassifierCmd classifierCmd =  new ClassifierCmd();
        String propfile = null;
        if (args.length == 3){
            propfile = args[2];
        }             
      
        printLicense();
        classifierCmd.doClassify(args[0], args[1], propfile);
        
    }
}
