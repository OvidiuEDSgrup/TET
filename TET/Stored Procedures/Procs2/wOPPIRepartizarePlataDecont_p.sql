CREATE PROCEDURE wOPPIRepartizarePlataDecont_p @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	DECLARE @sub varchar(9), @bugetari int, @mesaj VARCHAR(400), @tipOperatiune VARCHAR(2), @utilizator varchar(50), @data datetime, @valuta varchar(3), 
		@marca varchar(6), @decont varchar(40), @dataDecont datetime, @densalariat varchar(200), @numar varchar(13), @curs float, 
		@valoare float, @decontat float, @sold float, @lm varchar(13), @denlm varchar(30), @lmalternativ varchar(13), @contCasa varchar(40), @conditie482 int
	
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @sub OUTPUT --> citire subunitate din proprietati 
	EXEC luare_date_par 'GE', 'BUGETARI', @bugetari OUTPUT, 0, '' --> citire specific bugetari din parametrii

	/* am creat posibilitatea apelarii SP, pentru a putea modifica continutul @parXML: modificare cont CASA. */
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPPIRepartizarePlataDecont_pSP')
		exec wOPPIRepartizarePlataDecont_pSP @sesiune=@sesiune, @parXML=@parXML output

	SET @marca = isnull(@parXML.value('(/*/*/@marca)[1]', 'varchar(6)'),'')
	SET @numar = isnull(@parXML.value('(/*/*/@numar)[1]', 'varchar(13)'),'')
	SET @valuta = isnull(@parXML.value('(/*/*/@valuta)[1]', 'varchar(3)'),'')
	SET @lm = isnull(@parXML.value('(/*/*/@lm)[1]', 'varchar(13)'),'')
	SET @lmalternativ = isnull(@parXML.value('(/*/*/detalii/row/@lmalternativ)[1]', 'varchar(13)'),'')
	SET @curs = isnull(@parXML.value('(/*/*/@curs)[1]', 'float'),'') 
	SET @data = isnull(@parXML.value('(/*/*/@data)[1]', 'datetime'),'') 
	SET @decont = @parXML.value('(/*/*/@decont)[1]', 'varchar(40)')
	SET @contCasa = @parXML.value('(/*/*/@cont)[1]', 'varchar(40)')
	SET @tipOperatiune = 'PA'

	if ISNULL(@valuta,'')<>'' and ISNULL(@curs,0)=0
		raiserror('Pentru plati/incasari in valuta trebuie sa introduceti cursul valutar!',11,1)

	set @densalariat=(select RTRIM(nume) from personal where marca=@marca)

	if object_id('tempdb..#docdeconturi') is not null 
		drop table #docdeconturi
	if object_id('tempdb..#repdecont') is not null 
		drop table #repdecont

	set @parXML=(select @data as datasus, @marca as marca, @decont as decont for xml raw)
	if object_id('tempdb..#docdeconturi') is not null 
		drop table #docdeconturi
	create table #docdeconturi (subunitate varchar(9))
	exec CreazaDiezDeconturi @numeTabela='#docdeconturi'
	exec pDeconturi @sesiune=null, @parxml=@parXML

	/*	daca este apelata operatia dinspre macheta de deconturi (si daca nu s-a modificat prin SP), contul de antet este atribuit de tip decont */
	if @bugetari=1 and exists (select 1 from conturi c where c.subunitate=@sub and c.cont=@contCasa and c.Sold_credit=9)
	begin
		select top 1 @contCasa = cont_coresp from #docdeconturi where valoare<>0 and cont_coresp not like '482%'
		if exists (select 1 from conturi c where c.subunitate=@sub and c.cont=@contCasa and c.Sold_credit=9)
			set @contCasa='5310101'
	end
	select @dataDecont=data from deconturi where marca=@marca and decont=@decont

	/*	calcul sold decont */
	select @valoare=0, @decontat=0, @sold=0
	select @valoare=@valoare + (case when isnull(d.Valuta,'')<>'' then d.Valoare_valuta else d.Valoare end)
		, @decontat=@decontat + (case when isnull(d.Valuta,'')<>'' then d.Achitat_valuta else d.Achitat end)
		, @sold=@sold + (case when isnull(d.Valuta,'')<>'' then d.Valoare_valuta-Achitat_valuta else d.Valoare-Achitat end)
	from #docdeconturi d
	where ((d.Valuta=@valuta and ISNULL(@valuta,'')<>'') or (d.Valuta='' and isnull(@valuta,'')='')) 
	select @sold=convert(decimal(12,2),@sold)

	select @tipOperatiune as subtip, CONVERT(float,0) as suma, ROW_NUMBER() OVER (ORDER BY max(idPozitieDoc)) as nrp, ROW_NUMBER() OVER (ORDER BY sum(achitat), max(idPozitieDoc) desc) as nrp_desc,  
		max(d.numar_document) as numar,d.marca,d.decont,max(d.Data) as data,
		d.loc_de_munca, d.valuta, max(d.curs) as curs, 
		sum(case when isnull(d.Valuta,'')<>'' then d.Valoare_valuta else d.Valoare end) as valoare,
		sum(case when isnull(d.Valuta,'')<>'' then d.Achitat_valuta else d.Achitat end) as achitat,
		sum(case when isnull(d.Valuta,'')<>'' then d.Valoare_valuta-d.Achitat_valuta else d.Valoare-d.Achitat end) as sold, 
		0 as selectat, d.cont, d.indbug as indicator, max(idPozitieDoc) as idPozitieDoc,
		(case when Valoare<>0 then 'Valoare' when Achitat<>0 then 'Decontat' else '' end) as tipSuma, convert(varchar(50),'') as expl
	into #repdecont
	from #docdeconturi d
	where (abs(d.Valoare_valuta-d.Achitat_valuta)>0.001 or (d.Valuta='' and abs(d.Valoare-d.Achitat)>0.001))   
		and (d.Valuta=@valuta or (d.Valuta='' and isnull(@valuta,'')='')) 
	group by d.marca, d.decont, d.loc_de_munca, d.cont, d.valuta, d.indbug, (case when Valoare<>0 then 'Valoare' when Achitat<>0 then 'Decontat' else '' end) 

	/*	sterg pozitiile cu sold 0 pe indicator. Cele cu sold 0 inseamna ca nu mai trebuie prelucrate */
	delete r
	from #repdecont r
		inner join (select marca, decont, indicator, sum(sold) as sold from #repdecont group by marca, decont, indicator) s on s.marca=r.marca and s.decont=r.decont and s.indicator=r.indicator and s.sold=0

	/*	calculam suma pentru fiecare pozitie de repartizat. Sumele constituite (campul Valoare) se vor storna de pe vechii indicatorii, iar ceea ce este pe coloana Achitat se pune cu plus).*/
	update #repdecont set suma=(case when valoare<>0 then (case when valoare>@decontat then -@decontat else -valoare end) when achitat<>0 then achitat else 0 end)

	/*	daca soldul decontului este >0, suma de restituit se face pe indicatorul pe care s-a acordat */
	/*	daca soldul decontului este <0, sparg in prealabil sumele decontate pe indicatori, astfel incat suma de dat salariatului sa fie completata pe indicatori cu sumele cele mai mari decontate */
	if @sold<0
	begin
		if object_id('tempdb..#decDeRep') is not null 
			drop table #decDeRep
		if object_id('tempdb..#decTotal') is not null 
			drop table #decTotal

		--tabela cu sumele decontate care trebuie repartizate ca si plata decont
		select ROW_NUMBER() over (partition by a.Marca, a.Decont order by a.suma,a.idPozitieDoc) as nrp, nrp_desc, 0 as nrmin, 0 as nrmax,
			a.subtip, a.numar, a.Marca, a.Decont, a.data, a.loc_de_munca, a.valuta, a.curs, a.indicator, a.idPozitieDoc, a.cont, 
			a.Suma, a.Valoare, a.Achitat, a.Sold, @valoare as cumulat, convert(float,0) as cumulat_partial, 1 as se_repartizeaza
		into #decDeRep
		from #repdecont a
		where a.achitat>0
		order by a.suma, a.idPozitieDoc

		--tabela cu valoarea totala a decontului in limita caruia se va face repartizarea.
		select 1 as nrp, @Marca as marca, @Decont as decont, (case when @valoare=0 then @decontat else @valoare end) as suma, (case when @valoare=0 then @decontat else @valoare end) as cumulat
		into #decTotal 

		--solduri cumulate pe care se fac repartizarile
		update #decDeRep set 
			cumulat=cumulat.cumulat
		from (select d2.Marca, d2.decont, d2.nrp, sum(d1.suma) as cumulat 
				from #decDeRep d1, #decDeRep d2 
				where d1.Marca=d2.Marca and d1.Decont=d2.Decont and d1.nrp<=d2.nrp 
				group by d2.Marca, d2.Decont, d2.nrp) cumulat
		where cumulat.Marca=#decDeRep.Marca and cumulat.Decont=#decDeRep.Decont
			and cumulat.nrp=#decDeRep.nrp

	--calcul numar min
		update #decDeRep 
			set nrmin=st.nrp--,nrmax=dr.nrp
		from #decDeRep c
			cross apply
				(select top 1 smin.nrp from #decTotal smin where smin.Marca=c.Marca and smin.Decont=c.Decont and c.cumulat-c.suma<smin.cumulat order by smin.cumulat) st 

	--calcul numar max
		update #decDeRep 
			set nrmax=dr.nrp
		from #decDeRep c	
			cross apply
				(select Top 1 smax.nrp from #decTotal smax where smax.Marca=c.Marca and smax.Decont=c.Decont and (smax.cumulat<=c.cumulat or smax.cumulat-smax.suma<c.cumulat) order by smax.cumulat desc) dr

	--imperechere deconturi de platit pe indicatori functia de valoarea decontului
		delete from #repdecont where achitat>0
		insert into #repdecont
		select r.subtip, s.sumarepartizata as suma, r.nrp, nrp_desc, r.Numar, r.Marca, r.Decont, r.Data, 
			r.Loc_de_munca, r.valuta, r.curs, r.valoare as valoare, r.achitat as achitat, r.sold as sold, 0 as selectat, r.cont, r.indicator, r.idPozitieDoc, 
			'Valoare', (case when @valoare=0 then 'Plata dif. decont' else '' end)
		from #decDeRep r
			inner/*left outer*/ join #decTotal dt on r.Marca=dt.Marca and r.Decont=dt.Decont and dt.nrp between r.nrmin and r.nrmax and r.nrmin<>0
			cross apply (select round((case when r.cumulat<=dt.cumulat then r.cumulat else dt.cumulat end)
					-(case when r.cumulat-r.suma>dt.cumulat-dt.suma then r.cumulat-r.suma else dt.cumulat-dt.suma end),2) as sumarepartizata) s
			--cross apply (select round((case when r.cumulat_partial<=r.cumulat or r.cumulat=0 then r.suma else r.suma-(r.cumulat_partial-r.cumulat) end),2) as sumarepartizata) s
		order by r.nrp
	end

	/*	diferenta, functie de semn, o inseram ca si PA (plata decont) pt. sold negativ / IA (Restituire decont) pt. sold pozitiv	*/
	if @sold>0
		insert into #repdecont
		select top 1 'IA' as subtip, @sold as sold, 999, 999, numar, marca, decont, data, loc_de_munca, valuta, curs, 
			0 as valoare, 0 as achitat, 0 as sold, 0 as selectat, cont, indicator, idPozitieDoc, 'Valoare', ''
		from #repdecont
		order by nrp
	else 
		insert into #repdecont
		select 'PA' as subtip, achitat-suma as sold, nrp_desc+1, nrp_desc+1, numar, marca, decont, data, loc_de_munca, valuta, curs, 
			0 as valoare, 0 as achitat, 0 as sold, 0 as selectat, cont, indicator, idPozitieDoc, 'Valoare', 'Plata dif. decont'
		from #repdecont
		where achitat>0 and achitat<>suma
		order by suma, nrp_desc
	delete from #repdecont where suma=0

	--updatam campul selectat in functie de sumele repartizate pe indicatori
	update #repdecont set selectat=1 where abs(isnull(suma,0))>0.001

	alter table #repdecont add detalii xml
	update #repdecont set detalii='<row />' where detalii is null
	update #repdecont set detalii.modify('insert attribute indicator {sql:column("indicator")} into (/row)[1]')
	where indicator<>''

	/*	pun intr-o variabila conditia de 482 pentru a nu multiplica aceeasi conditie in mai multe locuri */	
	set @conditie482=(case when left(@lm,1)<>left(@lmalternativ,1) and left(@lmalternativ,1)<>'' then 1 else 0 end)
	/*	Completez tot timpul lmalternativ daca locul de munca difera de loc de munca alternativ (pentru a se inchide sumele corect pe contul de casa/banca pe locul de munca de PLATA).
		Nu doar pe pozitiile ce reprezinta RESTITUIRE DECONT sau PLATA DIFERENTA DECONT.
		@lmalternativ exista in detalii din @parXML, doar daca se apeleaza operatia dinpre macheta de Registru (se completeaza in macheta).
		La apelul operatiei dinspre macheta de deconturi se va putea culege in macheta de repartizare LOC DE MUNCA PLATA. */
	update #repdecont set detalii.modify('insert attribute lmalternativ {sql:variable("@lmalternativ")} into (/row)[1]')
	where @conditie482=1 --and (1=1 or subtip='IA' or expl='Plata dif. decont')

	/* am creat posibilitatea apelarii SP1, pentru a putea altera (la nevoie) continutul tabelei #repdecont. */
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPPIRepartizarePlataDecont_pSP1')
		exec wOPPIRepartizarePlataDecont_pSP1 @sesiune=@sesiune, @parXML=@parXML output

	select @denlm=rtrim(denumire) from lm where cod=@lm
	--date pentru form
	select convert(varchar(10),(case when @sold<0 then getdate() else @data end),101) as data, @valuta as valuta, 
		rtrim(@marca) as marca, rtrim(@marca)+' - '+rtrim(@densalariat) as densalariat, rtrim(@decont) as decont, convert(char(10),@dataDecont,101) as datadecont, 
		convert(decimal(17,2),@valoare) as valoare, convert(decimal(17,2),@decontat) as decontat, convert(decimal(17,2),@sold) as sold, 
		@contCasa as cont, @numar as numar, CONVERT(decimal(12,5),@curs) as curs, 
		(case when @conditie482=1 then @lm else '' end) as lm, (case when @conditie482=1 then @denlm else '' end) as denlm
	for xml raw, root('Date')	

	--date pentru grid
	SELECT (   
		SELECT
			row_number() over (order by p.nrp) as nrcrt,
			rtrim(p.numar) as numar,
			RTRIM(p.marca) as marca,
			RTRIM(p.decont) as decont,
			RTRIM(subtip) as subtip,
			RTRIM(case when subtip='PA' then 'Plata decont' else 'Restituire decont' end) as densubtip,
			RTRIM(p.cont) as contcorespondent,
			convert(decimal(17,2),p.suma) as suma,
			CONVERT(decimal(12,5),@curs) as curs,
			RTRIM(@valuta) as valuta,
			(case when ISNULL(@valuta,'')='' then 'RON' else @valuta end) as denvaluta,
			convert(int,selectat) as selectat,	--	momentan nu este utilizat acest camp in grid
			RTRIM(case when p.detalii.value('(/row/@lmalternativ)[1]','varchar(20)')<>'' then @lm else p.Loc_de_munca end) as lm, rtrim(p.cont) as cont, rtrim(p.indicator) as indicator, 
			p.detalii, rtrim(expl) as expl
		FROM  #repdecont p
		order by nrp_desc
		FOR XML RAW, TYPE  
		)  
	FOR XML PATH('DateGrid'), ROOT('Mesaje')

	SELECT '1' AS areDetaliiXml FOR XML raw, root('Mesaje')
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wOPPIRepartizarePlataDecont_p)'
	select 1 as inchideFereastra for xml raw,root('Mesaje')
	RAISERROR (@mesaj, 11, 1)
END CATCH
/*
	select * from deconturi
*/
