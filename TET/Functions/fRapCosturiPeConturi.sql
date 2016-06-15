--***
create function fRapCosturiPeConturi (@sesiune varchar(50), @datajos datetime, @datasus datetime)
returns @costuri table(cont varchar(20), denCont varchar(500), tip_cheltuieli varchar(20), denCheltuieli varchar(500), 
	suma decimal(20,4), ordine int)
as
begin
	--if (dbo.fIaUtilizator(@sesiune)='') return
	declare @regieLM table(lm varchar(20), sumapedirecte decimal(20,4), procent float)
	insert into @regieLM (lm, sumapedirecte, procent)
	SELECT lm_inf as lm,SUM(CANTITATE*VALOARE) as sumapedirecte,CONVERT(FLOAT,0) AS procent
	FROM dbo.costsql cs
		INNER JOIN comenzi c ON c.Comanda=cs.COMANDA_SUP 
	WHERE cs.data BETWEEN @datajos AND @datasus AND c.Tip_comanda IN ('P','R','A') AND cs.ART_SUP='L'
		AND cs.COMANDA_INF='' AND cs.COMANDA_SUP!=''
	GROUP BY lm_inf

	declare @regiedincontpelm table(lm varchar(20), total decimal(20,4))
	insert into @regiedincontpelm(lm, total)
	SELECT lm,SUM(suma) AS total
	FROM dbo.FisaPeCont 
	WHERE tip='D' AND data BETWEEN @datajos AND @datasus AND lm!='' AND comanda=''
	GROUP BY lm
	ORDER BY lm

	UPDATE r SET r.procent=r.sumapedirecte/T.total
	FROM @regieLM r
		INNER JOIN @regiedincontpelm t ON t.lm=r.lm
	
	insert into @costuri(cont, denCont, tip_cheltuieli, denCheltuieli, suma, ordine)
	select p.cont as cont, max(rtrim(co.Denumire_cont)) as denCont,
		'T' as tip_cheltuieli, 'Total cheltuieli' as denCheltuieli,
		convert(decimal(20,4),sum(suma)) as suma,
		100 as ordine
	from fisapecont p
		left outer join comenzi c on p.comanda = c.comanda
		left join conturi co on co.Cont=p.Cont
	where data between @datajos and @datasus
		and (isnull(p.comanda,'') <> '' and isnull(p.lm,'')<>'' and c.tip_comanda in ('P','R','A'))
	group by p.cont
	union all
	select p.cont as cont, max(rtrim(co.Denumire_cont)) as denCont,
		'G' as tip_cheltuieli, 'Cheltuieli generale' as denCheltuieli,
		convert(decimal(20,4),sum(suma)) as suma,
		2 as ordine
	from fisapecont p
		left join conturi co on co.Cont=p.Cont
	where data between @datajos and @datasus and p.comanda = '' and p.lm= '' and Tip='D'
	group by p.cont
	union all
	select p.cont as cont, max(rtrim(co.Denumire_cont)) as denCont,
		'I' as tip_cheltuieli, 'Cheltuieli indirecte' as denCheltuieli,
		convert(decimal(20,4),sum(suma*procente.procent)),
		3 as ordine
	from fisapecont p
		LEFT OUTER JOIN @regieLM procente ON procente.lm=p.lm
		left join conturi co on co.Cont=p.Cont
	where p.comanda = '' and p.lm!='' and Tip='D' 
	group by p.cont
	order by p.cont

	insert into @costuri(cont, denCont, tip_cheltuieli, denCheltuieli, suma, ordine)
	select c.cont, MAX(c.denCont), 'D', 'Cheltuieli directe' as denCheltuieli,
		sum(isnull((case c.tip_cheltuieli when 'T' then suma else -suma end),0)),
		1 as ordine
	from @costuri c
	group by c.cont
	
	delete @costuri where abs(isnull(suma,0))<0.005

	return
end
