/*
 * TreeFactory.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 * Created on June 24, 2002, 5:01 PM
 */

package edu.msu.cme.rdp.classifier.train;
import java.io.*;
import java.util.*;

/**
 * A TreeFactory reads the raw taxonomic information and creates the RawHierarchyTree nodes.
 * @author  wangqion
 * @version
 */
public class TreeFactory {
  
  private List genusNodeList = new ArrayList();   // list of all the genus nodes
  private List genus_wordConditionalProbList = new ArrayList(); // list of word
  //conditional probability and the corresponding genus node index,
  //starting from word 0 to word 65535.
  private int[] wordProbPointerArr = new int[65537];   // an array of index, each points to the start of
  // GenusIndexWordConditionalProb for each word in the ArrayList
  private float[] logArr;  // a list of log value of integers
 
  private RawHierarchyTree rootTree;
  private Map taxidMap = new HashMap();  // contains the taxname and the taxonomy
  private float[] wordPriorArr = new float[65536];    // an array of prior for words
  // the index is the integer form of the word . for size 8, 65536 possible words
  /** The depth of root of the RawHierarchyTree is set to 0 */
  private int ROOT_DEPTH = 0;
  private int totalSequences = 0;
  /** A factor for probability correction*/
  private final float WF1 = (float)0.5;  
  /** A factor for probability correction*/
  private final float WF2 = (float)1;
  
  private BufferedWriter treeFile;
  private String trainingVersion ;
  
  
  /** Creates new TreeFactory. */
  public TreeFactory(Reader taxReader, int trainsetNo, String version, String modification) throws IOException {
    trainingVersion = "<trainsetNo>" + trainsetNo + "</trainsetNo>" + "<version>" + version + "</version><modversion>" + modification + "</modversion>";
  
    creatTaxidMap(taxReader);
  }
  
  
  /** It reads in a file containing the taxonomy information for all the nodes.
   * The taxonomy format is taxid(int), taxname(string), parentid(int),
   * depth(int) and hierarchy level(string) seperated by * in one line.
   * The information are kept in a hashMap, key: taxname, value: an array of
   * the Taxonomy(taxid, parentid, depth and hierarchy rank level).
   * Note: the depth for the root is 0.
   */
  private void creatTaxidMap(Reader taxReader) throws IOException {
    BufferedReader reader = new BufferedReader(taxReader);
    String line;
    
    while ( ( line = reader.readLine() ) != null ){
      if (line.length() == 0){ // skip the empty line
        continue;
      }
      
      StringTokenizer st = new StringTokenizer(line, "*");
      if ( st.countTokens() < 5 ){
        throw new IllegalArgumentException("\nIllegal taxonomy format at " + line);
      }
      try{
        int taxid = Integer.parseInt(st.nextToken().trim());
        String taxname = st.nextToken().trim();
        int pid = Integer.parseInt(st.nextToken().trim());
        int depth = Integer.parseInt(st.nextToken().trim());
        List taxList = (ArrayList)taxidMap.get(taxname);
        if (taxList == null){  // if this is an empty list, create a new one
          taxList = new ArrayList();
        }
        
        Taxonomy tax = new Taxonomy(taxid, taxname, pid, depth, st.nextToken().trim());
        taxList.add(tax);
        taxidMap.put(taxname, taxList );
        // check the root tree
        if ( tax.depth == this.ROOT_DEPTH){
	        	if ( rootTree == null){
	          rootTree = new RawHierarchyTree(taxname, null, tax);		
	        }else {
	        		throw new IllegalArgumentException("Error: taxon " + tax.getTaxID() + " has the depth set to '0'. Only the root taxon can have the depth set to '0'");
	        }
        }
      } catch ( NumberFormatException e){
        throw new IllegalArgumentException("\nError: "
        + "The value for taxid, parentid and the depth should be integer in : " + line);
      }
    }
    
    if ( rootTree == null){
    		throw new IllegalArgumentException("Error: no root taxon with depth '0' defined in the taxonomy file.");
    }
  }
  
 
  /** For the given sequence name, its ancestors, and the sequence string, creates a
   * HierarchyTree for each ancestor,
   * If the root does not exist, creates the root with a null parent.
   * If the root already exists, checks the ParsedSequence to see if its
   * highest rank ancestor is the same as the previous root.
   */
  void addSequence(ParsedRawSequence pSeq) throws IOException{
    int size = pSeq.ancestors.size();    
    	if ( !((String) pSeq.ancestors.get(0)).equalsIgnoreCase( rootTree.getName() ) ){
      throw new IllegalArgumentException("Sequence " + pSeq.name
      + " has conflicting root name: " + (String) pSeq.ancestors.get(0));
    }
    RawHierarchyTree curTree = rootTree;
    // add each ancestor
    for (int i = 1 ; i < size; i++){
      RawHierarchyTree tmp = curTree.getSubclassbyName( (String)pSeq.ancestors.get(i) );
      if ( tmp == null ){
        Taxonomy tax = getTaxonomy(pSeq, ((Taxonomy)curTree.getTaxonomy()).taxID, i);
        curTree = new RawHierarchyTree((String)pSeq.ancestors.get(i), curTree, tax);
      } else{
        curTree = tmp;
      }
      // for the lowest level, count the word occurrence.
      if (i == size -1){
        curTree.initWordOccurrence(pSeq, wordPriorArr);
        //    new SequenceLeaf(pSeq.name, curTree, pSeq.sequence);  // ?? this can be removed after testing
        totalSequences ++ ;
      }
    }
  }
  
    /**
     * Gets the Taxonomy for the tree node in the ancestor list.
     */
  private Taxonomy getTaxonomy(ParsedRawSequence pSeq , int pid, int index){
    List ancestor = pSeq.ancestors;
    if (ancestor.isEmpty() ){
      throw new IllegalArgumentException("Error: No ancestors found for sequence: " + pSeq.name
      + "! Please check the source file.");
    }
    String name = (String) ancestor.get(index);
    List taxList = (ArrayList)taxidMap.get(name);
    if ( taxList == null ){
      throw new IllegalArgumentException("\nThe taxID for ancestor: " + name + " of sequence: " + pSeq.name
      + " at depth: " + index + " with parent id: " + pid + " is not found!" );
    }
    
    Taxonomy result = null;
    for (int i = 0; i < taxList.size(); i++){
      Taxonomy tax = (Taxonomy) taxList.get(i);
      if ( tax.parentID == pid && tax.depth == index ){
        result = tax;
        break;
      }
    }
    if ( result == null ){
      throw new IllegalArgumentException("\nThe taxID for ancestor: " + name + " of sequence: " + pSeq.name
      + " at depth: " + index + " with parent id: " + pid + " is not found!" );
    }
    return result;
  }
  
  /** Gets the root of the tree */
  RawHierarchyTree getRoot(){
    return rootTree;
  }
  
  /** This method does all the setup work for wordPrior and word conditional probability.
   * 1. It calculates the prior for each word and keeps the value in an array
   * 2. for each word, it calculates the conditional probability for
   *    non-zero occurrence genus, and keeps the value in an array.
   */
 void createGenusWordConditionalProb(){
    createNodeList(this.getRoot(), "GENUS", genusNodeList);
    
    if (genusNodeList.size() == 0) {
      throw new IllegalArgumentException("\nThere is no node in GENUS level!");
    }
    int maxNumOfLeaves = 0;
    
    for (int i = 0; i < wordPriorArr.length; i++){
      //calculate the prior probability for each word
      wordPriorArr[i] = ( wordPriorArr[i] + WF1 )/(totalSequences + WF2);
      
      //calculate the conditional probability for each word in each genus.
      wordProbPointerArr[i] = genus_wordConditionalProbList.size() ;
      for(int index = 0; index < genusNodeList.size(); index++) {
        RawHierarchyTree aTree = ((RawHierarchyTree)genusNodeList.get(index));
        int wordOccurrence = aTree.getWordOccurrence(i);
        int numOfLeaves = aTree.getLeaveCount();
        if ( wordOccurrence > 0){
          float prob = (float)Math.log( (wordOccurrence + wordPriorArr[i]) / (numOfLeaves + WF2)) ;
          genus_wordConditionalProbList.add(new RawGenusWordConditionalProb(index, prob));
          //System.err.println("word=" + i + " genus=" + index + "  wo=" + wordOccurrence + " wp=" + wordPriorArr[i] + " leaves=" + aTree.getNumOfLeaves());
        }
        if (numOfLeaves > maxNumOfLeaves){
          maxNumOfLeaves = numOfLeaves;
        }
      }
      // change the wordPrior to log wordPrior for each calculate later
      wordPriorArr[i] = (float)Math.log(wordPriorArr[i]);
    }
    
    // the last pointer in wordProbPointerArr should have the value of the
    // size of the genus_wordConditionalProbList
    wordProbPointerArr[wordProbPointerArr.length -1] = genus_wordConditionalProbList.size();
    
    // release the space occupied by wordOccurrence for the genu nodes.
    for (int index = 0; index < genusNodeList.size(); index++) {
      ((RawHierarchyTree)genusNodeList.get(index)).releaseWordOccurrence();
    }
    
    // make a list of log value of integers for convience
    logArr = new float[++maxNumOfLeaves];
    for (int i = 0; i < maxNumOfLeaves; i++){
      logArr[i] = (float)Math.log(i+WF2);
    }
  }
  
  /**
   * Returns the log value for word prior probability for the given word index.
   */
  float getLogWordPrior(int wordIndex){
    return wordPriorArr[wordIndex];
  }
  
  /**
   * Return the list of geneus nodes.
   */
  List getGenusNodeList(){
    return genusNodeList;
  }
  
  
   /**
    * Returns the log value of ( number of leaves plus 1 ).
    */
  float getLogLeaveCount(int i){
    return logArr[i];
  }
  
   /** Returns the start index of RawGenusWordConditionalProb in the array for the
    * given wordIndex.
    */
  int getStartIndex(int wordIndex){
    return wordProbPointerArr[wordIndex];
  }
  
   /** Returns the stop index of RawGenusWordConditionalProb in the array for the
    * given wordIndex.
    */
  int getStopIndex(int wordIndex){
    return wordProbPointerArr[wordIndex +1];
  }
  
   /** Returns a GenusWordConditionalProb from the array given the postion.
    */
  RawGenusWordConditionalProb getWordConditionalProb(int posIndex ){
    return (RawGenusWordConditionalProb)genus_wordConditionalProbList.get(posIndex);
  }
  
  
  /** Gets all the lowest level nodes in given hierarchy level starting from the given root.
   */
  void createNodeList(RawHierarchyTree root, String level, List nodeList){
    if (root == null) {
      return;
    }
    
    if ( ((Taxonomy)root.getTaxonomy()).hierLevel.equalsIgnoreCase(level) ){
      nodeList.add(root);
      root.setGenusIndex(nodeList.size()-1);
      return;
    }
    //start from the root of the tree, get the subclasses.
    Collection al = new ArrayList();
    
    if( ( al = root.getSubclasses()).isEmpty() ){
      return;
    }
    Iterator i = al.iterator();
    while (i.hasNext()){
      createNodeList( (RawHierarchyTree) i.next(), level, nodeList);
    }
  }
          
  /**
   * Writes the entire phylogenetic taxonmic information to a file. 
   */
  void printTrainingFiles(String outdir) throws IOException{
    treeFile = new BufferedWriter(new FileWriter(outdir + "bergeyTrainingTree.xml"));
    treeFile.write(trainingVersion + "<file>bergeyTrainingTree</file>\n");
    displayTrainingTree(this.rootTree);
    treeFile.close();
  }
  
  /** Writes the phylogenetic taxonmic information of the given root and all the descendant nodes to a file.
   * For each node, display the index and the name.
   * For each sequence, display the name and the description.
   */
  private void displayTrainingTree(RawHierarchyTree root) throws IOException{
    Taxonomy taxon = ((Taxonomy)root.getTaxonomy());
    
    treeFile.write("<TreeNode name=\"" + root.getName() + "\" taxid=\"" +
    taxon.taxID + "\" rank=\"" + taxon.hierLevel + "\" parentTaxid=\"" +
    taxon.parentID + "\" leaveCount=\""  +
    root.getLeaveCount() + "\" genusIndex=\"" + root.getGenusIndex() +
    "\"></TreeNode>\n");
    
    Iterator i = root.getSubclasses().iterator();
    
    while (i.hasNext()){
      displayTrainingTree( (RawHierarchyTree)i.next() );
    }
  }
  
  /**
   * Writes the log values of the word prior probabilities to a file.
   */
  void printWordPriors(String outdir) throws IOException{
    BufferedWriter outfile = new BufferedWriter(new FileWriter(outdir + "logWordPrior.txt"));
    outfile.write(trainingVersion + "<file>logWordPrior</file>\n");
    for (int i = 0; i < wordPriorArr.length; i++){
      outfile.write( i + "\t" + wordPriorArr[i]  +"\n");
    }
    
    outfile.close();
  }
  
  /**
   * Writes the indices of words and the start indices of conditional probability of 
   * the genera containing these words to a file.
   */
  void printWordConditionalProbIndexArr(String outdir ) throws IOException {
    BufferedWriter outfile = new BufferedWriter(new FileWriter(outdir + "wordConditionalProbIndexArr.txt"));
    outfile.write(trainingVersion + "<file>wordConditionalProbIndexArr</file>\n");
    for (int i = 0; i < wordProbPointerArr.length; i++){
      outfile.write( i + "\t" + wordProbPointerArr[i]  +"\n");
    }
    
    outfile.close();
  }
  
  /**
   * Writes the indices of genus nodes and the conditional probabilities of words occurred in these
   *  genus nodes to a file.
   */
  void printGenusIndex_WordProbArr(String outdir) throws IOException{
    BufferedWriter outfile = new BufferedWriter(new FileWriter(outdir + "genus_wordConditionalProbList.txt"));
    outfile.write(trainingVersion + "<file>genus_wordConditionalProbList</file>\n");
    for (int i = 0; i < genus_wordConditionalProbList.size(); i++){
      RawGenusWordConditionalProb prob = (RawGenusWordConditionalProb) genus_wordConditionalProbList.get(i);
      outfile.write( prob.getGenusIndex() + "\t" + prob.getProbability()  +"\n");
    }
    
    outfile.close();
  }
    
  
}
