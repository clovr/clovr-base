#ifndef orf_h
#define orf_h

#include "alpha.h"

// NucStartPos = 0-based offset from start (end) of NucSeq
// if frame is plus (minus).
struct ORFData
	{
	const byte *NucSeq;
	unsigned NucL;
	unsigned NucStartPos;
	const byte *AminoSeq;
	unsigned CodonCount;
	int Frame;
	ORFData *Next;

	void LogMe() const
		{
		Log("ORF seqlen %unt frame %d pos %u aas %u\n", NucL, Frame, NucStartPos, CodonCount);
		}

	void LogMe2() const
		{
		Log("ORF seqlen %unt frame %d pos %u aas %u\n", NucL, Frame, NucStartPos, CodonCount);
		if (Frame > 0)
			{
			unsigned p = NucStartPos;
			for (unsigned i = 0; i < CodonCount; ++i)
				{
				asserta(p+2 < NucL);
				byte c1 = NucSeq[p++];
				byte c2 = NucSeq[p++];
				byte c3 = NucSeq[p++];
				byte a = GetAminoCharFrom3NucChars(c1, c2, c3);
				Log("%c", a);
				}
			}
		else
			{
			int p = int(NucL) - int(NucStartPos) - 1;
			for (unsigned i = 0; i < CodonCount; ++i)
				{
				asserta(p-2 >= 0);
				byte c1 = NucSeq[p--];
				byte c2 = NucSeq[p--];
				byte c3 = NucSeq[p--];
				byte r1 = g_CharToCompChar[c1];
				byte r2 = g_CharToCompChar[c2];
				byte r3 = g_CharToCompChar[c3];
				byte a = GetAminoCharFrom3NucChars(r1, r2, r3);
				Log("%c", a);
				}
			}
		Log("\n");
		Log("%*.*s\n", CodonCount, CodonCount, AminoSeq);
		}
	};

const byte ORFEND = '.';

void GetORFs(const byte *NucSeq, unsigned NucL, vector<ORFData> &ORFs,
  unsigned ORFStyle, int FindFrame, int Sign);
unsigned ORFPosToNucPos(unsigned AAPos, const ORFData &ORF);

#endif // orf_h
