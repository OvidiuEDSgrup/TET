select SUM(s.stoc)--, @dencod=max(n.Denumire), @tipcod=max(n.Tip)
FROM stocuri s 
	right join nomencl n on n.Cod=s.Cod
WHERE n.Cod='PPR-L20' and (s.Stoc is null or s.Subunitate='1' AND s.Tip_gestiune NOT IN ('F','T') 
	and s.Cod_gestiune='211.NT' AND s.Stoc>=0.001 )
	--AND (isnull('9813865','')=''
	--	or 1=0 
	--	or CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM('300;900;700;700.NT;700.CJ;700.DJ;700.SV;700.SB;700.AG;700.GL;700.BN;700.BV;700.IS;700.IF')+';')=0
	--	or s.contract='9813865'))