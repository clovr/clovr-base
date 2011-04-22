#include "myutils.h"
#include "alpha.h"

static bool *g_IsChar = g_IsAminoChar;

double GetFractIdGivenPathDiffs(const byte *A, const byte *B, const char *Path,
  char *ptrDesc)
	{
	unsigned PosA = 0;
	unsigned PosB = 0;
	unsigned Ids = 0;
	unsigned Diffs = 0;
	unsigned Cols = 0;
	for (const char *p = Path; *p; ++p)
		{
		++Cols;
		char c = *p;
		if (c == 'M')
			{
			byte a = toupper(A[PosA]);
			byte b = toupper(B[PosB]);
			if (g_IsChar[a] && g_IsChar[b])
				{
				if (a == b)
					++Ids;
				else
					++Diffs;
				}
			else
				--Cols;
			}
		if (c == 'D' || c == 'I')
			++Diffs;
		if (c == 'M' || c == 'D')
			++PosA;
		if (c == 'M' || c == 'I')
			++PosB;
		}

	double FractId = (Cols == 0 ? 0.0 : 1.0 - double(Diffs)/double(Cols));
	if (ptrDesc != 0)
		sprintf(ptrDesc, "(ids=%u/cols=%u)", Ids, Cols);
	return FractId;
	}

static double GetFractIdGivenPathInternalDiffs(const byte *A, const byte *B,
  const char *Path, char *ptrDesc)
	{
	unsigned i = 0;
	unsigned FirstM = UINT_MAX;
	unsigned LastM = UINT_MAX;
	for (const char *p = Path; *p; ++p)
		{
		if (*p == 'M')
			{
			if (FirstM == UINT_MAX)
				FirstM = i;
			LastM = i;
			}
		++i;
		}
	if (FirstM == UINT_MAX)
		{
		if (ptrDesc != 0)
			strcpy(ptrDesc, "(no matches)");
		return 0.0;
		}

	unsigned PosA = 0;
	unsigned PosB = 0;
	unsigned Ids = 0;
	unsigned Diffs = 0;
	unsigned Cols = 0;
	for (unsigned i = 0; i < FirstM; ++i)
		{
		char c = Path[i];
		if (c == 'M' || c == 'D')
			++PosA;
		if (c == 'M' || c == 'I')
			++PosB;
		}

	for (unsigned i = FirstM; i <= LastM; ++i)
		{
		++Cols;
		char c = Path[i];
		if (c == 'M')
			{
			byte a = toupper(A[PosA]);
			byte b = toupper(B[PosB]);
			if (g_IsChar[a] && g_IsChar[b])
				{
				if (a == b)
					++Ids;
				else
					++Diffs;
				}
			else
				--Cols;
			}
		if (c == 'D' || c == 'I')
			++Diffs;
		if (c == 'M' || c == 'D')
			++PosA;
		if (c == 'M' || c == 'I')
			++PosB;
		}

	double FractId = (Cols == 0 ? 0.0 : 1.0 - double(Diffs)/double(Cols));
	if (ptrDesc != 0)
		sprintf(ptrDesc, "(ids=%u/cols=%u)", Ids, Cols);
	return FractId;
	}

static double GetFractIdGivenPathMBL(const byte *A, const byte *B, const char *Path,
  char *ptrDesc)
	{
	unsigned PosA = 0;
	unsigned PosB = 0;
	unsigned Mismatches = 0;
	unsigned Gaps = 0;
	for (const char *p = Path; *p; ++p)
		{
		char c = *p;
		if (c == 'M' && toupper(A[PosA]) != toupper(B[PosB]))
			++Mismatches;
		if (c == 'D' || c == 'I' && (p == Path || p[-1] == 'M'))
			++Gaps;
		if (c == 'M' || c == 'D')
			++PosA;
		if (c == 'M' || c == 'I')
			++PosB;
		}
	unsigned Diffs = Gaps + Mismatches;
	double FractDiffs = (PosB == 0 ? 0.0 : double(Diffs)/double(PosB));
	if (ptrDesc != 0)
		sprintf(ptrDesc, "Gap opens %u, Id=1 - [(diffs=%u)/(target_length=%u)]",
		  Gaps, Diffs, PosB);
	double FractId = 1.0 - FractDiffs;
	if (FractId < 0.0)
		return 0.0;
	return FractId;
	}

static double GetFractIdGivenPathBLAST(const byte *A, const byte *B, const char *Path,
  char *ptrDesc)
	{
	unsigned PosA = 0;
	unsigned PosB = 0;
	unsigned Ids = 0;
	unsigned Wilds = 0;
	unsigned Cols = 0;
	for (const char *p = Path; *p; ++p)
		{
		++Cols;
		char c = *p;
		if (c == 'M')
			{
			byte a = toupper(A[PosA]);
			byte b = toupper(B[PosB]);
			if (g_IsChar[a] && g_IsChar[b])
				{
				if (a == b)
					++Ids;
				}
			else
				++Wilds;
			}
		if (c == 'M' || c == 'D')
			++PosA;
		if (c == 'M' || c == 'I')
			++PosB;
		}
	asserta(Cols >= Wilds);
	Cols -= Wilds;
	double FractId = Cols == 0 ? 0.0f : float(Ids)/float(Cols);
	if (ptrDesc != 0)
		sprintf(ptrDesc, "(ids=%u/cols=%u)", Ids, Cols);
	return FractId;
	}

static double GetFractIdGivenPathDefault(const byte *A, const byte *B, const char *Path,
  char *ptrDesc)
	{
	unsigned PosA = 0;
	unsigned PosB = 0;
	unsigned Ids = 0;
	unsigned Wilds = 0;
	for (const char *p = Path; *p; ++p)
		{
		char c = *p;
		if (c == 'M')
			{
			byte a = toupper(A[PosA]);
			byte b = toupper(B[PosB]);
			if (g_IsChar[a] && g_IsChar[b])
				{
				if (a == b)
					++Ids;
				}
			else
				++Wilds;
			}
		if (c == 'M' || c == 'D')
			++PosA;
		if (c == 'M' || c == 'I')
			++PosB;
		}
	unsigned MinLen = min(PosA, PosB) - Wilds;
	double FractId = (MinLen == 0 ? 0.0 : double(Ids)/double(MinLen));
	if (ptrDesc != 0)
		sprintf(ptrDesc, "(ids=%u/shorter_length=%u)", Ids, MinLen);
	return FractId;
	}

double GetFractIdGivenPath(const byte *A, const byte *B, const char *Path,
  bool Nucleo, char *ptrDesc, unsigned IdDef)
	{
	if (Nucleo)
		g_IsChar = g_IsACGTU;
	else
		g_IsChar = g_IsAminoChar;

	if (Path == 0)
		{
		if (ptrDesc != 0)
			strcpy(ptrDesc, "(NULL path)");
		return 0.0;
		}

	double FractId = 0.0;
	if (opt_idprefix > 0)
		{
		for (unsigned i = 0; i < opt_idprefix; ++i)
			{
			char c = Path[i];
			if (c != 'M' || toupper(A[i]) != toupper(B[i]))
				{
				if (ptrDesc != 0)
					sprintf(ptrDesc, "Prefix ids %u < idprefix(%u)",
					  i, opt_idprefix);
				return 0.0;
				}
			}
		}

	switch (IdDef)
		{
	case 0:
		FractId = GetFractIdGivenPathDefault(A, B, Path, ptrDesc);
		break;

	case 1:
		FractId = GetFractIdGivenPathDiffs(A, B, Path, ptrDesc);
		break;

	case 2:
		FractId = GetFractIdGivenPathInternalDiffs(A, B, Path, ptrDesc);
		break;

	case 3:
		FractId = GetFractIdGivenPathMBL(A, B, Path, ptrDesc);
		break;

	case 4:
		FractId = GetFractIdGivenPathBLAST(A, B, Path, ptrDesc);
		break;

	default:
		Die("--iddef %u invalid", opt_iddef);
		}

	return FractId;
	}

double GetFractIdGivenPath(const byte *A, const byte *B, const char *Path,
  bool Nucleo, char *ptrDesc)
	{
	return GetFractIdGivenPath(A, B, Path, Nucleo, ptrDesc, opt_iddef);
	}

double GetFractIdGivenPath(const byte *A, const byte *B, const char *Path, bool Nucleo)
	{
	return GetFractIdGivenPath(A, B, Path, Nucleo, (char *) 0);
	}

double GetFractIdGivenPath(const byte *A, const byte *B, const string &Path)
	{
	return GetFractIdGivenPath(A, B, Path.c_str(), true);
	}

double GetFractIdGivenPath(const byte *A, const byte *B, const char *Path)
	{
	return GetFractIdGivenPath(A, B, Path, true);
	}
