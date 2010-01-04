/*
 * HierarchyTree.java
 *
 * Copyright 2006 Michigan State University Board of Trustees
 * 
 * Created on June 24, 2002, 2:36 PM
 */

package edu.msu.cme.rdp.classifier.rrnaclassifier;

import java.util.*;

/**
 * A HierarchyTree holds the taxonomic information of a taxon.
 * @author  wangqion
 * @version
 */
class HierarchyTree {
  
  private String name;
  private String rank;
  private int taxid;
  private int leaveCount;
  private HierarchyTree parent;
  private List subclasses = new ArrayList();
  /**-1 means not a genus node. If this node is a genus node, the genusIndex indicates the index of this node among all the genera */
  private int genusIndex = -1;  
  
  /** Creates new HierarchyTree given the taxonomic information. */
  
  HierarchyTree(String n, int taxid, String rank, int leaves, int gIndex) {
    name = n;
    this.taxid = taxid;
    this.rank = rank;
    leaveCount = leaves;
    genusIndex = gIndex;
  }
  
  /** Adds the parent HierarchyTree, also adds this node to the parent treenode as a child. */
  void addParent(HierarchyTree p){
    parent = p;
    if( parent != null)
      parent.addSubclass(this);
  }
  
  
  /** Adds a child treenode to subclass. */
  private void addSubclass(HierarchyTree c){
    subclasses.add(c);
  }
  
  
  /** Gets the name of the treenode. */
  String getName(){
    return name;
  }
  
  /** Gets the parent treenode. */
  HierarchyTree getParent(){
    return parent;
  }
  
  /** Gets the rank of the treenode. */
  String getRank(){
    return rank;
  }
  
  /** Gets the taxon id of the treenode. */
  int getTaxid(){
    return taxid;
  }
  
  /** Gets the name of the treenode. */
  List getSubclasses(){
    return subclasses;
  }
  
  /** Gets the list of the child treenodes. */
  int getSizeofSubclasses() {
    return subclasses.size();
  }
  
  /** Gets the size of sequence leaves directly belong to this treenode.
   */
  int getLeaveCount(){
    return leaveCount;
  }
  
  /** Gets the index of the genus treenode in the genusNodeList.
   * Returns -1 if not a genus node.
   */
  int getGenusIndex(){
    return genusIndex;
  }
  
  
}
