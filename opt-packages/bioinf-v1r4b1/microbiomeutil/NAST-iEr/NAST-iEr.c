#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>


static int DEBUG = 0;

/* data structures */
typedef struct  { 
  int score;
  int prev; } Cell;

typedef struct { 
  int x;
  int y; } Point;

typedef struct { 
  int G;
  int A;
  int T;
  int C;
  int gap;
} ntCounts;


void add_sequence_to_profile(ntCounts* template, char* seq, int lastIndex);
int extract_profile_from_file(char* filename, ntCounts* template); // returns alignment length
void report_profile_consensus(ntCounts* profile, int alignmentLength);

/* prototypes */
void usage (char*);
void extract_sequence_from_file (char* filename, char* acc, char* sequence);
void align_NASTy (ntCounts* templateSeq, int fixedAlignmentLength, char* querySeq, char* templateAlignment, char* queryAlignment);
Cell**  build_matrix (int x, int y); /* builds a 2D array of cell structs */
void init_matrix (Cell** matrix, int x, int y); // initializes the matrix cell values and boundary conditions.
void populate_matrix (Cell** matrix, int x, int y, ntCounts* templateSeq, char* querySeq); // builds the DP matrix, assigning scores and pointers.
Point get_highest_scoring_cell_coordinates (Cell** matrix, int x, int y); // examines boundary conditions and finds highest scoring global alignment
void extract_aligned_sequences (Cell** matrix, int x, int y, Point p, ntCounts* templateSeq, char* querySeq, char* templateAlignment, char* queryAlignment);
char* strrev (char* str); // reverse a string in-place.
void print_FASTA (char* acc, char* sequence);
int compute_match_score(ntCounts n, char c);
char get_max_char(ntCounts n);
void report_ntCounts_contents(ntCounts n);


/* global vars */
static int MAX_SEQ_LENGTH = 20000;
static int MAX_ACC_LENGTH = 100;
static int FASTA_LENGTH = 60; 

/* scores for computing alignment */
static int MATCH = 5;
static int MISMATCH = -4;
static int GAP = -4;

/* directions for trace in the matrix */
static int UP = 1;
static int DIAG = 2;
static int LEFT = 3;




int main (int argc, char* argv[]) {

  /* var declarations */
  char* templateSeqFilename;
  char* querySeqFilename;
  
  int print_both_alignments = 0; // by default, just print the query in NAST format.

  ntCounts templateSeq [MAX_SEQ_LENGTH];
  int i;
  for (i = 0; i < MAX_SEQ_LENGTH; i++) {
	ntCounts* n = &templateSeq[i];
	n->G = n->A = n->T = n->C = n->gap = 0;
  }
  
  char querySeq [MAX_SEQ_LENGTH];
  
  char queryAcc [MAX_ACC_LENGTH];

  char alignedTemplateSeq [2 * MAX_SEQ_LENGTH];
  char alignedQuerySeq [2 * MAX_SEQ_LENGTH];

  // other option processing
  int c;
  
  while ((c = getopt (argc, argv, "M:N:G:b")) != -1) {
	switch (c) {
	case 'M':
	  MATCH = atoi(optarg);
	  break;
	case 'N':
	  MISMATCH = atoi(optarg);
	  break;
	case 'G':
	  GAP = atoi(optarg);
	  break;
	case 'b':
	  print_both_alignments = 1;
	  break;
	  
	case '?':
	  if (isprint (optopt)) {
		fprintf (stderr, "Unknown option `-%c'.\n", optopt);
	  } 
	  else {
		fprintf (stderr,
				 "Unknown option character `\\x%x'.\n",
				 optopt);
	  }
	}
  }

  if (argc < optind + 1) {
	usage(argv[0]);
	exit(1);
  }
  
  templateSeqFilename = argv[optind];
  querySeqFilename = argv[optind + 1];
  
  fprintf(stderr, "Alignment parameters:\nMATCH: %d\nMISMATCH: %d\nGAP: %d\n\n", MATCH, MISMATCH, GAP);
  
  /* get sequences from files */
  int fixedAlignmentLength = extract_profile_from_file(templateSeqFilename, templateSeq);
  extract_sequence_from_file(querySeqFilename, queryAcc, querySeq);
    
  if (DEBUG) {
	printf ("Parsed profile of length: %d\n", fixedAlignmentLength);
	report_profile_consensus(templateSeq, fixedAlignmentLength);

	printf ("\n\nAnd parsed query sequence acc: %s:\n%s\n\n", queryAcc, querySeq);
	
  }
  

  /* perform NASTy alignment */
  align_NASTy(templateSeq, fixedAlignmentLength, querySeq, alignedTemplateSeq, alignedQuerySeq);
  
  /* output the aligned sequences in fasta format */
  if (print_both_alignments) {
	print_FASTA("template", alignedTemplateSeq);
  }
  
  print_FASTA(queryAcc, alignedQuerySeq);

  return(0);
}







void usage (char* progname) {
  fprintf(stderr, "\n\nusage: %s [options] templateSeqFilename  querySeqFilename\n\n", progname);
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "\t-M   Match score (default: 5)\n");
  fprintf(stderr, "\t-N   Mismatch score (default: -4)\n");
  fprintf(stderr, "\t-G   Gap penalty (default: -4)\n\n");
  fprintf(stderr, "\t-b   print both the template profile consensus and the query in NAST format\n\n\n");
  
}


int extract_profile_from_file(char* filename, ntCounts* templateSeq) {
  FILE* fp;
  int letter;
  int pos = -1;
  
  char currSeq [MAX_SEQ_LENGTH];
  
  

  if ( (fp = fopen(filename, "r")) == NULL) {
	fprintf (stderr, "Error, cannot open filename %s", filename);
	exit(2);
  }

  while ( (letter = getc(fp)) != EOF) {
	if (letter == '>') {
	  if (pos != -1) {
		add_sequence_to_profile(templateSeq, currSeq, pos);
	  }
	  pos = -1; // reinit
	  
	  // advance the line
	  while ( (letter = getc(fp)) != '\n') { ; }
	}
	else if (letter != ' ' && letter != '\n') {
	  pos++;
	  currSeq[pos] = letter;
	}
  }
  
  // get last one
  add_sequence_to_profile(templateSeq, currSeq, pos);
  
  fclose(fp);
  
  return(pos + 1);
}



void extract_sequence_from_file (char* filename, char* acc, char* sequence) {
  FILE* fp;
  int letter;
  int pos = -1;

  if ( (fp = fopen(filename, "r")) == NULL) {
	fprintf (stderr, "Error, cannot open filename %s", filename);
	exit(2);
  }
  
  /* read in the accession */
  if ( (letter = getc(fp)) != '>') {
	fprintf (stderr, "Error, filename %s does contain a fasta sequence beginning with '>'", filename);
	exit(3);
  }
  while ( ((letter = getc(fp)) != EOF) && (letter != ' ' && letter != '\n')) {
	acc[++pos] = letter;
  }
  acc[++pos] = '\0'; // terminate the acc string.
  
  /* read in rest of sequence */
  while (letter != '\n') {
	// advance to next line.
	letter = getc(fp);
  }
  pos = -1; // reset to just before sequence
  while ( (letter = getc(fp)) != EOF) {
	if (letter != '\n' && letter != ' ') {
	  sequence[++pos] = letter;
	}
  }
  sequence[++pos] = '\0';

  fclose(fp);
}


void align_NASTy (ntCounts* templateSeq, int templateSeqLength, char* querySeq, char* templateAlignment, char* queryAlignment) {
  
  int querySeqLength = strlen(querySeq);
  
  if (DEBUG) {
	fprintf (stdout, "lengths:\ntemplate: %d\nquery: %d\n\n", templateSeqLength, querySeqLength);
  }
  /* matrix boundaries */
  int x = templateSeqLength;
  int y = querySeqLength;

  Cell** matrix = build_matrix(x, y); // need seqlength + 1 for cols and rows, the extra for the boundaries.
  populate_matrix(matrix, x, y, templateSeq, querySeq);
  
  Point p = get_highest_scoring_cell_coordinates(matrix, x, y);
  
  extract_aligned_sequences(matrix, x, y, p, templateSeq, querySeq, templateAlignment, queryAlignment);
    
  
}


void populate_matrix (Cell** matrix, int x, int y, ntCounts* templateSeq, char* querySeq) {  
  
  int i, j;
      
  for (i = 1; i <= x; i++) {
	ntCounts a = templateSeq[i-1];
	int numChars = a.G + a.A + a.T + a.C;
	int numGaps = a.gap;
	

	for (j = 1; j <= y; j++) {
	  	  
	  char b = querySeq[j-1];

	  if (DEBUG > 1) {
		printf ("computing match score of NTs ");
		report_ntCounts_contents(a);
		printf ("compared to char: %c\n", b);
	  }
	  

	  // score the match (or mismatch)
	  int max_score = compute_match_score(a, b) + matrix[i-1][j-1].score;
	  int max_dir = DIAG; // init for this round.  
	  
	  // insert gap against a template character, penalized for number of non-gap characters.  If all gap, there is no penalty at all.
	  int score = matrix[i-1][j].score + (numChars * GAP);
	  if (score > max_score) {
		max_score = score;
		max_dir = LEFT;
	  }
	  	  
	  
	  if (DEBUG > 1) {
		fprintf (stdout, "max score(%d,%d): %i, %i\n", i, j, max_score, max_dir);
	  }
	  
	  matrix[i][j].score = max_score;
	  matrix[i][j].prev = max_dir;
	
	  //fprintf(stdout, "setting matrix[%d][%d] = %d\n", i, j, max_dir);
	  
	} // end of for j 
	
  } // end of for i
  
}

Cell** build_matrix (int x, int y) {
    
  Cell** matrix = (Cell**) malloc (sizeof(Cell*) * (x+1));
  
  int i;
  for (i = 0; i <= x; i++) {
	matrix[i] = (Cell*) malloc (sizeof(Cell) * (y+1));
  }

  
  init_matrix(matrix, x, y);
  
  

  return(matrix);
}


void init_matrix (Cell** matrix, int x, int y) {
  
  /* init all cells */
  int i,j;
  
  for (i = 0; i <= x; i++) {
	
	for (j = 0; j <= y; j++) {
	  Cell* cell = &(matrix[i][j]);
	  cell->score = 0;
	  cell->prev = 0;
	}
  }

  /* establish boundary conditions for not penalizing end gaps */
  for (i = 1; i <= x; i++) {
	matrix[i][0].prev = LEFT;
  }
  for (j = 1; j <= y; j++) {
	matrix[0][j].prev = UP;
  }
  

}


Point get_highest_scoring_cell_coordinates (Cell** matrix, int x, int y) {
  
  int best_score = -9999999;  // short for minus infinity.
  Point p;
  int i,j;
 

  for (i = 1; i <= x; i++) {
	int score = matrix[i][y].score;
	if (score > best_score) {
	  best_score = score;
	  p.x = i;
	  p.y = y;
	}
  }

  for (j = 1; j <= y; j++) {
	int score = matrix[x][j].score;
	if (score > best_score) {
	  best_score = score;
	  p.x = x;
	  p.y = j;
	}
  }
  
  fprintf (stderr, "Highest score: %d\n", best_score);
  
  return(p);
}


void extract_aligned_sequences (Cell** matrix, int x, int y, Point p, ntCounts* templateSeq, char* querySeq, char* templateAlignment, char* queryAlignment) {

  int pos_x = p.x;
  int pos_y = p.y;

  int align_pos = 0;
  
  if (DEBUG) {
	fprintf (stdout, "beginning traceback at (%d, %d)\n", pos_x, pos_y);
  }
  
  /* build the 3' end-gapped portion of the alignment. */
  
  int i,j;
  if (pos_x < x) { // add gap chars at the end of the query alignment, populate reference chars.
	for (i = x; i > pos_x; i--) {
	  templateAlignment[align_pos] = get_max_char(templateSeq[i-1]);
	  queryAlignment[align_pos] = '.';
	  align_pos++;
	}
  }
  
  
  /* begin traceback of global alignment */

  Cell c = matrix[pos_x][pos_y];

  while (c.prev != 0) {
	
	if (DEBUG) {
	  fprintf(stdout, "matrix[%d][%d] == %d\n", pos_x, pos_y, c.prev);
	}
	
	char a,b;
	
	if (c.prev == DIAG) {
	  // matching current positions.
	  a = get_max_char(templateSeq[pos_x-1]);
	  b = querySeq[pos_y-1];
	  pos_x--;
	  pos_y--;
	}

	else if (c.prev == UP) {
	  // no gaps added to end of template, even at ends
	  if (pos_x != 0) {
		fprintf(stderr, "trying to add gaps to the template and query sequence not fully traversed (pos_x: %d)", pos_x);
		exit(1);
	  }
	  break;

	 
	}
	
	else if (c.prev == LEFT) {
	  // gap in query sequence
	  char gapchar = (pos_y == 0) ? '.' : '-';
	  a = get_max_char(templateSeq[pos_x-1]);
	  b = gapchar;
	  pos_x--;
	}
	
	else {
	  fprintf (stderr, "Error, cannot determine matrix direction: %d at (%d, %d)\n", c.prev, pos_x, pos_y);
	  exit(10);
	}
	
		
	templateAlignment[align_pos] = a;
	queryAlignment[align_pos] = b;
	align_pos++;
	
	c = matrix[pos_x][pos_y]; // reset for next round.

	if (DEBUG > 1) {
	  fprintf (stdout, "assigning alignment [%d] = %c <-> %c\n", align_pos, a, b);
	  fprintf (stderr, "alignpos: %d, (%d, %d)\n", align_pos, pos_x, pos_y);
	}
  }
  
  // terminate the alignment strings.
  templateAlignment[align_pos] = '\0';
  queryAlignment[align_pos] = '\0';

  int templateAlignmentLength = strlen(templateAlignment);
  int queryAlignmentLength = strlen(queryAlignment);
  
  if (DEBUG) {
	fprintf (stdout, "templateLen: %d\n", templateAlignmentLength);
	fprintf (stdout, "queryAlignmentLen: %d\n", queryAlignmentLength);
  }
  
  if (templateAlignmentLength != queryAlignmentLength) {
	fprintf (stderr, "Error, template alignment length %d != query alignment length %d", 
			 templateAlignmentLength, queryAlignmentLength);
	exit(1);
  }


  templateAlignment = strrev(templateAlignment);
  queryAlignment = strrev(queryAlignment);
  
}

char* strrev(char* str)  {
  
  int i,j;
  
  for (i = 0, j = strlen(str) - 1; i < j; i++, j--) {
	
	char c = str[j];
	str[j] = str[i];
	str[i] = c;
  }
  
  return str;
}


void print_FASTA (char* acc, char* sequence) {
  
  fprintf (stdout, ">%s\n", acc);
  int i;
  for (i = 0; i < strlen(sequence); i++) {
	if (i != 0 && i % FASTA_LENGTH == 0) {
	  fprintf (stdout, "\n"); // spacer
	}
	fprintf (stdout, "%c", sequence[i]);
  }
  fprintf (stdout, "\n");

}


int compute_match_score (ntCounts n, char c) {

 
  if (c == 'g' || c == 'G') {
	return (MATCH * n.G + MISMATCH * (n.A + n.T + n.C + n.gap));
  }
  else if (c == 'a' || c == 'A') {
	return (MATCH * n.A + MISMATCH * (n.G + n.T + n.C + n.gap));
  }
  else if (c == 't' || c == 'T') {
	return (MATCH * n.T + MISMATCH * (n.G + n.A + n.C + n.gap));
  }
  else if (c == 'c' || c == 'C') {
	return (MATCH * n.C + MISMATCH * (n.G + n.A + n.T + n.gap));
  }
  else {
	
	// pretend the character is an A
	return (MATCH * n.A + MISMATCH * (n.G + n.T + n.C + n.gap));
	
	//fprintf (stderr, "Error, do not recognize character: %c\n", c);
	//exit(3);
  }

}


char get_max_char(ntCounts n) {
  int max = n.G;
  char max_char = 'G';
  
  if (n.A > max) {
	max = n.A;
	max_char = 'A';
  }
  else if (n.T > max) {
	max = n.T;
	max_char = 'T';
  }
  else if (n.C > max) {
	max = n.C;
	max_char = 'C';
  }
  else if (n.gap > max) {
	max = n.gap;
	max_char = '-';
  }
  
  return (max_char);
}

void add_sequence_to_profile(ntCounts* template, char* seq, int lastIndex) {
  
  if (DEBUG) {
	printf ("Adding sequence to profile:\n%s\n\n", seq);
  }


  int i;
  
  for (i = 0; i <= lastIndex; i++) {
	char c = seq[i];
	//printf ("char: %c\n", c);
	ntCounts* n = &template[i];
	if (c == 'g' || c == 'G') {
	  n->G++;
	}
	else if (c == 'a' || c  == 'A') {
	  n->A++;
	}
	else if (c == 't' || c == 'T') {
	  n->T++;
	}
	else if (c == 'c' || c == 'C') {
	  n->C++;
	}
	else if (c == '.' || c == '-') {
	  n->gap++;
	}
	else {
	  //fprintf (stderr, "Error, do not recognize char: %c, treating as an \'A\'\n", c);
	  // exit(3);
	}
  }
}

	
void report_profile_consensus (ntCounts* profile, int alignmentLength) {
  
  int i;
  for (i = 0; i < alignmentLength; i++) {
	printf ("%c", get_max_char(profile[i]));
  }
  printf ("\n\n");
  
  return;
}

void report_ntCounts_contents (ntCounts n) {
  
  printf ("G:%d A:%d T:%d C:%d gap:%d\n", n.G, n.A, n.T, n.C, n.gap);
  
}
