/*
	exec rapRaportProductieDinVanzari '02/25/2014','02/25/2014'
	
*/
CREATE procedure rapRaportProductieDinVanzari @datajos datetime, @datasus datetime,@numar_document varchar(20)=NULL, @gestiune varchar(20)=NULL, @cod_produs varchar(20)=NULL, @lm varchar(20)=NULL
as
	declare
		@sub varchar(9)
	exec luare_date_par 'GE','SUBPRO',0,0,@sub OUTPUT

	IF OBJECT_ID('tempdb..#date_raport') IS NOT NULL
		drop table #date_raport
	
	select
		p.numar doc_vanzare, p.data data_vanzare, p.tip tip_vanzare, p.gestiune gest_vanzare, p.cod cod_produs, t.cod cod_tehn,  
		p.cantitate cant_produs, pret_vanzare, p.pret_cu_amanuntul pret_amanunt,  idPozDoc idPozDoc_AC, Loc_de_munca lm, convert(float,0) val_aviz
	into #date_raport
	from PozDoc p
	JOIN Tehnologii t on p.cod=t.codNomencl
	where 
		p.subunitate=@sub and p.tip='AC' and p.data between @datajos and @datasus and (@gestiune IS NULL or p.gestiune=@gestiune) and (@cod_produs IS NULL or p.cod=@cod_produs) and
		(@numar_document IS NULL or p.numar=@numar_document) and  
		(@lm is null or p.Loc_de_munca=@lm)

	update dr
		set val_aviz=va.val_ac
	from #date_raport dr
	JOIN 
	(	
		select doc_vanzare, ISNULL(sum(dr.cant_produs*dr.pret_amanunt),0) val_ac
		from #date_raport dr
		group by doc_vanzare
	) va on va.doc_vanzare=dr.doc_vanzare

	alter table #date_raport add cod_articol varchar(20), cant_reteta float, gest_consum varchar(20), pret_stoc float

	insert into #date_raport(doc_vanzare,data_vanzare, tip_vanzare, gest_vanzare, cod_produs, cod_tehn, cant_produs, pret_vanzare, pret_amanunt, idPozDoc_AC,val_aviz, lm, cod_articol, cant_reteta)
	select 	
		doc_vanzare,data_vanzare, tip_vanzare, gest_vanzare, cod_produs, cod_tehn, cant_produs, pret_vanzare, pret_amanunt, idPozDoc_AC,val_aviz, lm, pr.cod, pr.cantitate*cant_produs
	from PozTehnologii pt
	JOIN #date_raport p on p.cod_tehn=pt.cod and pt.tip='T'
	JOIN PozTehnologii pr on pr.parinteTop=pt.id and pr.tip='M'

	delete #date_raport where cod_articol IS NULL

	alter table #date_raport add doc_consum varchar(20), data_consum datetime, cant_consum float, tip_consum varchar(20)
	
	update d
		set cant_consum=p.cantitate, doc_consum=p.numar, data_consum=p.data, gest_consum=p.gestiune, tip_consum=p.tip, pret_stoc=p.Pret_de_stoc
	from #date_raport d
	JOIN PozDoc p on d.doc_vanzare=p.numar and p.tip='CM' and p.cod=d.cod_articol and d.data_vanzare=p.data and d.idPozDoc_AC=p.detalii.value('(/*/@idPozDoc_AC)[1]','int')

	select 
		rank () over (partition by dr.gest_vanzare, dr.doc_vanzare, dr.cod_produs order by newid()) rk_val_prod,
		dr.doc_vanzare, dr.data_vanzare, dr.tip_vanzare, dr.gest_vanzare, dr.cod_produs, dr.cod_tehn, dr.cant_produs, dr.pret_vanzare, dr.pret_amanunt, dr.cod_articol, dr.cant_reteta, dr.gest_consum,dr.tip_consum,
		RTRIM(g.denumire_gestiune) dengestiunevanzare, RTRIM(n.denumire) denprodus, RTRIM(na.denumire) denarticol, RTRIM(gc.denumire_gestiune) dengestiuneconsum,
		rtrim(na.um) um, dr.pret_stoc pret_stoc, rtrim(lm.denumire) denlm, dr.cant_consum, rtrim(g.Cont_contabil_specific) cont,
		dr.cant_produs*dr.pret_amanunt valoare_produs, (case dr.tip_vanzare when 'AC' then 'Aviz chit.' when 'AP' then 'Aviz' end) dentip_vanzare,
		gs.val_consum, dr.val_aviz val_aviz
	from #date_raport dr
	INNER JOIN gestiuni g on g.cod_gestiune=dr.gest_vanzare
	INNER JOIN gestiuni gc on gc.cod_gestiune=dr.gest_consum
	INNER JOIN nomencl n on dr.cod_produs=n.cod
	INNER JOIN nomencl na on dr.cod_articol=na.cod
	INNER JOIN
	(
		select gest_vanzare gest, sum(cant_consum*pret_stoc) val_consum
		from #date_raport 
		group by gest_vanzare
	) gs on gs.gest=dr.gest_vanzare
	LEFT JOIN lm lm on lm.Cod=dr.lm
