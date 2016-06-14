declare @p2 xml
set @p2=convert(xml,N'<row tipMacheta="D" codMeniu="CO" tip="BK" subtip="BK" update="1" subunitate="1" numar="9860030" data="06/05/2013" explicatii="0" termen="06/05/2013" dengestiune="GESTIUNE TRANSFERURI" gestiune="400" dentert="TRUST EURO THERM SRL" factura="" tert="RO6610440" contractcor="" punctlivrare="" denpunctlivrare="" denlm="LG-TRANSFERURI 400" lm="1LG_TE" dengestprim="AG FILIALA PITESTI" gestprim="211.AG" valuta="" curs="0.0000" valoare="417.88" valtva="80.88" valtotala="498.76" scadenta="0" contclient="" procpen="0" contr_cadru="" ext_camp4="" ext_camp5="01/01/1901" ext_modificari="" ext_clauze="" valabilitate="01/01/1901" pozitii="1" discount="0" comspec="0" stare="0" categpret="1" dencategpret="Lista unica-Pret catalog  RON (1)" denstare="0-Operat" info1="" info2="0.00" info3="0.000000000000000e+000" info4="0.0000000e+000" info5="0.00" info6="" culoare="#000000" _nemodificabil="0" codfarastoc="0" cantitate="0" pret="0" cod="RB-HFF34" searchText="RB-HFF34 "/>')
exec wACNomenclator @sesiune='E0A24CFA74D92',@parXML=@p2
		--@sesiune	E0A24CFA74D92	varchar
		--@parXML	<row tipMacheta="D" codMeniu="CO" tip="BK" subtip="BK" update="1" subunitate="1" numar="9860030" data="06/05/2013" explicatii="0" termen="06/05/2013" dengestiune="GESTIUNE TRANSFERURI" gestiune="400" dentert="TRUST EURO THERM SRL" factura="" tert="RO66104	xml
		--@FltStocPred	0	int
		--@searchText	RB-HFF34%	varchar
		--@subunitate	1	varchar
		--@tip	BK	varchar
		--@gestiune	400	varchar
		--@gestutiliz	700.AG              	varchar
		--@categoriePret	1	int
		--@codfarastoc	0	bit
		--@aplicatie		varchar
		--@subtip	BK	varchar
		--@utilizator	FILIALA_AG	varchar
		--@lista_gestiuni	1	int
