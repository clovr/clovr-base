#ifndef MY_VERSION
#define MY_VERSION	"4.0"
#endif

//			Long name		Short		Default									Help
//FLAG_OPT(	someflag,		f,													"This is a flag option")

//			Long name		Short		Default		Min			Max				Help
//INT_OPT(	someint,		i,			-1,			INT_MIN,	INT_MAX,		"This is a signed integer option")

//			Long name		Short		Default		Min			Max				Help
//UNS_OPT(	someuns,		-,			0,			0,			UINT_MAX,		"This is an unsigned integer option")

//			Long name		Short		Default		Min			Max				Help
//FLT_OPT(	someflt,		f,			0.0,		-1,			+1,				"This is a floating-point option")

//			Long name		Short		Default									Help
//STR_OPT(	somestr,		s,			0,										"This is a string option")

//			Long name		Short		Default		Values						Help
//ENUM_OPT(	someenum,		e,			1,			"Value1=1|Value2=2",		"This is an enum option\nwith line break")

//			Long name		Short		Default									Help
STR_OPT(	input,			i,			0,										"Input file name")
STR_OPT(	query,			i,			0,										"Query file name")
STR_OPT(	test,			-,			0,										"")
STR_OPT(	db,				-,			0,											"Database")
STR_OPT(	sort,			-,			0,										"Sort sequences by length")
STR_OPT(	output,			-,			0,										"Output file (format varies by command)")
STR_OPT(	uc,				-,			0,										"Output file")
STR_OPT(	clstr2uc,		-,			0,										"")
STR_OPT(	uc2clstr,		-,			0,										"")
STR_OPT(	uc2fasta,		-,			0,										"")
STR_OPT(	uc2fastax,		-,			0,										"")
STR_OPT(	mergesort,		-,			0,										"")
STR_OPT(	tmpdir,			-,			".",									"")
STR_OPT(	staralign,		-,			0,										"")
STR_OPT(	sortuc,			-,			0,										"")
STR_OPT(	blastout,		-,			0,										"Output file, blast-like format")
STR_OPT(	blast6out,		-,			0,										"Output file, blast-like format")
STR_OPT(	fastapairs,		-,			0,										"Output file, FASTA pairs")
//STR_OPT(	types,			-,			"SH",									"")
STR_OPT(	idchar,			-,			"|",									"")
STR_OPT(	diffchar,		-,			" ",									"")
STR_OPT(	uchime,			-,			0,										"")
STR_OPT(	uchime3,		-,			0,										"")
STR_OPT(	henrik,			-,			0,										"")
STR_OPT(	threeway,		-,			0,										"")
STR_OPT(	gapopen,		-,			0,										"")
STR_OPT(	gapext,			-,			0,										"")
STR_OPT(	uhire,			-,			0,										"")
STR_OPT(	ids,			-,			"99,98,95,90,85,80,70,50,35",			"")
STR_OPT(	seeds,			-,			0,										"")
STR_OPT(	clump,			-,			0,										"")
STR_OPT(	clumpout,		-,			0,										"")
STR_OPT(	clump2fasta,	-,			0,										"")
STR_OPT(	clumpfasta,		-,			0,										"")
STR_OPT(	hireout,		-,			0,										"")
STR_OPT(	mergeclumps,	-,			0,										"")
STR_OPT(	ublast,			-,			0,										"")
STR_OPT(	ublastx,		-,			0,										"")
//STR_OPT(	logxlat,		-,			0,										"")
STR_OPT(	alpha,			-,			0,										"")
STR_OPT(	hspalpha,		-,			0,										"")
STR_OPT(	probmx,			-,			0,										"")
STR_OPT(	matrix,			-,			0,										"")
//STR_OPT(	freqs,			-,			0,										"")
STR_OPT(	tracestate,		-,			0,										"")
STR_OPT(	chainout,		-,			0,										"")
STR_OPT(	cluster,		-,			0,										"")
STR_OPT(	computekl,		-,			0,										"")
STR_OPT(	userout,		-,			0,										"")
STR_OPT(	userfields,		-,			0,										"")
STR_OPT(	seedsout,		-,			0,										"")
STR_OPT(	chainhits,		-,			0,										"")
STR_OPT(	findorfs,		-,			0,										"")
STR_OPT(	strand,			-,			0,										"")
STR_OPT(	getseqs,		-,			0,										"")
STR_OPT(	labels,			-,			0,										"")
STR_OPT(	doug,			-,			0,										"")
STR_OPT(	makeindex,		-,			0,										"")
STR_OPT(	indexstats,		-,			0,										"")
STR_OPT(	chsim,			-,			0,										"")
STR_OPT(	uchimeout,		-,			0,										"")
STR_OPT(	uchimealns,		-,			0,										"")

UNS_OPT(	band,			-,			16,			0,			UINT_MAX,		"D.P. band radius (0=don't band)")
UNS_OPT(	minlen,			-,			10,			1,			UINT_MAX,		"Minimum sequence length")
UNS_OPT(	maxlen,			-,			10000,		1,			UINT_MAX,		"Maximum sequence length")
UNS_OPT(	w,				-,			0,			1,			UINT_MAX,		"")
UNS_OPT(	k,				-,			0,			1,			UINT_MAX,		"")
UNS_OPT(	stepwords,		-,			8,			0,			UINT_MAX,		"")
UNS_OPT(	maxaccepts,		-,			1,			0,			UINT_MAX,		"")
UNS_OPT(	maxrejects,		-,			8,			0,			UINT_MAX,		"")
UNS_OPT(	maxtargets,		-,			0,			0,			UINT_MAX,		"")
UNS_OPT(	minhsp,			-,			32,			1,			UINT_MAX,		"")
UNS_OPT(	bump,			-,			50,			0,			100,			"")
UNS_OPT(	rowlen,			-,			64,			8,			UINT_MAX,		"Row length for blast-like alignment formats")
UNS_OPT(	idprefix,		-,			0,			0,			UINT_MAX,		"")
UNS_OPT(	chunks,			-,			4,			2,			UINT_MAX,		"")
UNS_OPT(	minchunk,		-,			64,			2,			UINT_MAX,		"")
UNS_OPT(	minchseg,		-,			32,			2,			UINT_MAX,		"")
UNS_OPT(	maxclump,		-,			1000,		1,			UINT_MAX,		"")
UNS_OPT(	diagr,			-,			16,			0,			UINT_MAX,		"")
UNS_OPT(	iddef,			-,			0,			0,			UINT_MAX,		"")
UNS_OPT(	mincodons,		-,			20,			1,			UINT_MAX,		"")
UNS_OPT(	maxovd,			-,			8,			0,			UINT_MAX,		"")
UNS_OPT(	max2,			-,			40,			0,			UINT_MAX,		"")
UNS_OPT(	querylen,		-,			500,		0,			UINT_MAX,		"")
UNS_OPT(	targetlen,		-,			500,		0,			UINT_MAX,		"")
UNS_OPT(	orfstyle,		-,			(1+2+4),	0,			UINT_MAX,		"")
UNS_OPT(	dbstep,			-,			1,			1,			UINT_MAX,		"")
UNS_OPT(	flank,			-,			10,			1,			UINT_MAX,		"")
UNS_OPT(	randseed,		-,			1,			1,			UINT_MAX,		"")
UNS_OPT(	bsreps,			-,			100,		1,			UINT_MAX,		"")
UNS_OPT(	maxp,			-,			2,			2,			UINT_MAX,		"")
UNS_OPT(	chsim_minm,		-,			0,			0,			UINT_MAX,		"")
UNS_OPT(	chsim_maxm,		-,			UINT_MAX,	0,			UINT_MAX,		"")
UNS_OPT(	chsim_acc,		-,			UINT_MAX,	0,			UINT_MAX,		"")
UNS_OPT(	chsim_iters,	-,			10,			0,			UINT_MAX,		"")
UNS_OPT(	chsim_nperiter,	-,			256,		0,			UINT_MAX,		"")
UNS_OPT(	idsmoothwindow,	-,			32,			1,			UINT_MAX,		"")
UNS_OPT(	mindiffs,		-,			3,			1,			UINT_MAX,		"")

INT_OPT(	frame,			-,			0,			-3,			+3,				"")

TOG_OPT(	trace,			-,			false,									"")
TOG_OPT(	logmemgrows,	-,			false,									"")
TOG_OPT(	trunclabels,	-,			false,									"Truncate FASTA labels at first whitespace")
TOG_OPT(	verbose,		-,			false,									"")
TOG_OPT(	wordcountreject,-,			true,									"")
TOG_OPT(	ovchunks,		-,			false,									"")

// Making --rev the default doubles memory use
TOG_OPT(	rev,			-,			false,									"")
TOG_OPT(	output_rejects,	-,			false,									"")
TOG_OPT(	blast_termgaps,	-,			false,									"")
TOG_OPT(	fastalign_chime,-,			false,									"")
TOG_OPT(	fastalign,		-,			true,									"")
TOG_OPT(	loghsps,		-,			false,									"")
TOG_OPT(	flushuc,		-,			false,									"")
TOG_OPT(	stable_sort,	-,			false,									"")
TOG_OPT(	minus_frames,	-,			true,									"")
TOG_OPT(	usort,			-,			true,									"")
TOG_OPT(	nb,				-,			false,									"")
TOG_OPT(	twohit,			-,			true,									"")
TOG_OPT(	ssort,			-,			false,									"")
TOG_OPT(	log_query,		-,			false,									"")
//TOG_OPT(	catorfs,		-,			false,									"")
TOG_OPT(	logwordstats,	-,			false,									"")
TOG_OPT(	ucl,			-,			false,									"")
TOG_OPT(	skipgaps2,		-,			true,									"")
TOG_OPT(	skipgaps,		-,			true,									"")

FLT_OPT(	id,				-,			0.0,		0.0,		1.0,			"")
FLT_OPT(	weak_id,		-,			0.0,		0.0,		1.0,			"")
FLT_OPT(	match,			-,			1.0,		0.0,		FLT_MAX,		"Match score (nucleotides only)")
FLT_OPT(	mismatch,		-,			-2.0,		0.0,		FLT_MAX,		"Mismatch score (nucleotides only)")
FLT_OPT(	hspscore,		-,			1.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	split,			-,			1000.0,		1.0,		FLT_MAX,		"Split size for --mergesort")
FLT_OPT(	mint,			-,			16.0,		1.0,		FLT_MAX,		"")
FLT_OPT(	evalue,			-,			10.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	weak_evalue,	-,			10.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	evalue_g,		-,			10.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	chain_evalue,	-,			10.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	xdrop_u,		-,			16.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	xdrop_g,		-,			32.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	xdrop_ug,		-,			16.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	xdrop_nw,		-,			16.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	ka_gapped_lambda,	-,		0.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	ka_ungapped_lambda,	-,		0.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	ka_gapped_k,		-,		0.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	ka_ungapped_k,		-,		0.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	ka_dbsize,		-,			0.0,		0.0,		FLT_MAX,		"")
//FLT_OPT(	scale,			-,			1.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	minscore,		-,			0.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	chain_targetfract,-,		0.0,		0.0,		1.0,			"")
FLT_OPT(	targetfract,	-,			0.0,		0.0,		1.0,			"")
FLT_OPT(	queryfract,		-,			0.0,		0.0,		1.0,			"")
FLT_OPT(	fspenalty,		-,			16.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	seedt1,			-,			13.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	seedt2,			-,			11.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	lopen,			-,			11.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	lext,			-,			1.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	minbs,			-,			90.0,		0.0,		100.0,			"")
FLT_OPT(	minsmoothid,	-,			0.95,		0.0,		1.0,			"")

FLT_OPT(	minh,			-,			0.3,		0.0,		FLT_MAX,		"")
//FLT_OPT(	miny,			-,			5.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	xn,				-,			8.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	dn,				-,			1.4,		0.0,		FLT_MAX,		"")
FLT_OPT(	xa,				-,			1.0,		0.0,		FLT_MAX,		"")
FLT_OPT(	mindiv,			-,			0.5,		0.0,		100.0,			"")
//FLT_OPT(	chimetopctl,	-,			0.5,		0.0,		100.0,			"")
FLT_OPT(	abskew,			-,			2,			0.0,		100.0,			"")
FLT_OPT(	abx,			-,			8.0,		0.0,		100.0,			"")
FLT_OPT(	chsim_divlo,	-,			0.0,		0.0,		100.0,			"")
FLT_OPT(	chsim_divhi,	-,			0.0,		0.0,		100.0,			"")

FLAG_OPT(	usersort,		-,													"")
FLAG_OPT(	exact,			-,													"")
FLAG_OPT(	optimal,		-,													"")
FLAG_OPT(	version,		-,													"Print version number and exit")
FLAG_OPT(	svnmods,		-,													"Print version number and exit")
FLAG_OPT(	libonly,		-,													"")
FLAG_OPT(	self,			-,													"")
FLAG_OPT(	ungapped,		-,													"")
FLAG_OPT(	global,			-,													"")
FLAG_OPT(	local,			-,													"")
//FLAG_OPT(	logtargetfract,	-,													"")
FLAG_OPT(	xlat,			-,													"")
FLAG_OPT(	realign,		-,													"")
