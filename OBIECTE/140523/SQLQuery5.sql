select * -- update w set numetab=std.numetab
from webConfigTaburi w cross apply ( select * from webConfigstdTaburi std where
			(w.meniusursa=STD.meniusursa and w.TipSursa=STD.TipSursa
			and w.meniunou=STD.meniunou and w.Tipnou=STD.Tipnou) and w.NumeTab<>std.NumeTab) std