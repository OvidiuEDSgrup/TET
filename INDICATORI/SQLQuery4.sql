declare @p2 xml
set @p2=convert(xml,N'<row cod="MB1" denumire="test marja cu echipa" expresie="select sum(p.Cantitate*p.Pret_vanzare-p.Cantitate*p.Pret_de_stoc) &#x0A;from pozdoc p inner join calstd c on c.Data=p.Data left join nomencl n on n.Cod=p.Cod &#x0A;where p.tip in (''AP'',''AS'',''AC'')&#x0A; EXPANDEZ({c.DATA_LUNII},{(select max(valoare) from proprietati where Cod_proprietate=''ECHIPA'' and tip=''TERT'' and cod=p.tert)}&#x0A;&#x09;,{p.LOC_DE_MUNCA},{p.tert},{n.grupa})" detalieredata="Da" cudata="1" gaugeinvers="1" descriere="" dataJos="01/01/2012" dataSus="10/09/2012" tip="CT" tipMacheta="C" codMeniu="CT" TipDetaliere="CT" subtip="RC"/>')
exec wCalculezIndicatori @sesiune='385E2FC1B39C7',@parXML=@p2