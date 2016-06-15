
CREATE procedure rapFisaTertipeIntervale(@sesiune varchar(50)=null,
	@cFurnBenef varchar(1),@cData datetime,@cTert varchar(50),@cFactura varchar(50),@cContTert varchar(50),
	@soldmin decimal(20,2),@soldabs int,@dDataFactJos datetime,@dDataFactSus datetime,@dDataScadJos datetime,@dDataScadSus datetime,
	@aviz_nefac int = 0,@grupa varchar(50) = null,@grupa_strict int, @exc_grupa varchar(50)=null,
	@fsolddata1 int, @fsold int=2,	--> @fsold=facturi pe sold; echivalenta cu : 1 => @soldmin=0.01 si @soldabs=1; 0 => @soldmin=0.00 si @soldabs=1
	@comanda varchar(50) = null,@indicator varchar(50) = null, @cDataJos datetime = null, 
	@tipdoc varchar(1) = 'F',	-->	sursa:	F=Facturi, E=Efecte, X=Toate
	@locm varchar(20) = null,
	@punctLivrare varchar(20) = null,
	@moneda bit=0, @valuta varchar(20)=null,
	@centralizare int=0,	--> prin parametrul centralizare se determina ordonarea datelor; daca 0=facturi se ord pe facturi, daca 1=documente se ord pe documente
	@gestiune varchar(20)=null,
	@tip_intervale varchar(1)='I',	--> I = zile introduse, S = saptamani
	@zile varchar(300)=null,	--> intervalele separate prin virgula
	@saptamani varchar(300)=null,	--> numarul de saptamani calendaristice pe care se va analiza scadenta; saptamana curenta este in mijloc, in capete se cumuleaza eventualele date din afara intervalului rezultat
	@detaliat bit=0,	--> daca sa apara doar valoarea (0) sau si achitari si sold (1)
	@siCoduri bit=0,
	@parXML xml='<row />',
	@soldmintert decimal(20,2)=null, --> nu apar tertii care au soldul mai mic decat @soldmintert in valoare absoluta
	@cuefecte bit = 0,		--> sa apara intr-o coloana, inainte de total, achitarea efectelor
	@ordonare int = 1,		-->0=cod, 1=denumire
	@tipdata varchar(1) ='s',	--> data in functie de care se calculeaza intervalul: 's' = scadentei, 'e' = emiterii
	@centralizat bit=0	--> centralizat pe terti
	)
as
begin
	select @cuefecte=isnull(@cuefecte,0)
set transaction isolation level read uncommitted
	IF OBJECT_ID('tempdb..#fisa') IS NOT NULL drop table #fisa
declare @eroare varchar(1000)
set @eroare=''
begin try
	--> tratare intervale:
	create table #zile(inceput int, sfarsit int, ordine int, ordine2 int, denInterval varchar(1000))
	
	if @tip_intervale='S'
	begin
		if isnull(@saptamani,0)<>0
			select @zile=@saptamani
		if @zile='' or charindex(',',@zile)>0
			raiserror('Pentru intervale de tip saptamana se specifica numarul de saptamani printr-o singura valoare completata in parametrul "Saptamani interval"!',16,1)
		declare @nrsaptamani int
		select @nrsaptamani=convert(int,@zile)
		insert into #zile (inceput, sfarsit, ordine, ordine2, denInterval)
		select (t.n-@nrsaptamani/2)*7,0 sfarsit, 0 ordine, row_number() over (order by t.n) as ordine2,
						'' denInterval
		from tally t where t.n<@nrsaptamani
		
		update z set z.sfarsit=100000
		from #zile z
		where ordine=(select max(ordine) from #zile)
		--/*
		insert into #zile(inceput, sfarsit, ordine, ordine2, deninterval)
		select -100000,z.inceput-1,0,0,'sub '+convert(varchar(1000),z.inceput-1)+' zile'
		from #zile z where ordine2=1
		/*union all
		select z.sfarsit+1,10000,z.ordine+1, z.ordine2+1,'sub '+convert(varchar(1000),z.inceput-1)+' zile'
		from #zile z where ordine=(select max(ordine) from #zile)
	*/	--*/
	end

	select @zile=',-100000,'+
		@zile+',100000,'	-- ma asigur ca acopar toate facturile
	
	if @tip_intervale='I' and @zile is not null
	begin
		insert into #zile (inceput, sfarsit, ordine, ordine2, denInterval)
		select convert(int,rtrim(ltrim(convert(varchar(200),
					SUBSTRING(@zile, t.n+1,charindex(',',@zile,n+1)-n-1))))) as inceput, 0 sfarsit, convert(int, 0) ordine, row_number() over (order by t.n) as ordine2,
					'' denInterval
		from tally t
		where t.N<LEN(@zile) and substring(@zile,t.N,1)=',' and substring(@zile,t.N-1,1)<>','
	end	
	
	update z set ordine=z1.ordine
	from #zile z inner join (select row_number() over (order by inceput) as ordine, ordine2 from #zile) z1
		on z.ordine2=z1.ordine2
	
	update z set sfarsit=z1.inceput-1
	from #zile z inner join #zile z1 on z.ordine=z1.ordine-1

	--> denumiri intervale
	if @tip_intervale='I'
	update z set denInterval=(case when z.sfarsit>=100000-1 then 'Peste '+convert(varchar(20),inceput)+' zile'
								when z.inceput<=-100000 and z.sfarsit=-1 then 'Nescadente'
								when z.inceput<=-100000 then 'Sub '+convert(varchar(20),sfarsit)+' zile'
								else 'Intre '+convert(varchar(20),inceput)+' si '+convert(varchar(20),sfarsit)+' zile' end)
	from #zile z
	else
	update z set denInterval=(case	when z.sfarsit=100000 then '...depasit '+convert(varchar(20),z.inceput/7)+' sapt.'
									when z.inceput=-100000 then 'peste '+convert(varchar(20),-(z.sfarsit-1)/7+1)+' sapt. ...'
									when z.inceput=0 then 'sapt. curenta'
									when z.inceput=7 then 'sapt. anterioara'
									when z.inceput=-7 then 'sapt. viitoare'
									else (case when z.inceput<0 then 'peste ' else 'depasit ' end)+convert(varchar(20),abs(z.inceput/7))+' sapt.'
								end),
				ordine=-ordine
	from #zile z
	
	--> pentru varianta pe saptamani avem nevoie de un offset (sa decalam incadrarea datelor in intervale astfel incat saptamanile sa coincida cu impartirea reala pe saptamani):
	declare @dataFisa datetime
	select @dataFisa=@cData
	if @tip_intervale='S'
	begin
		if @cData is null set @cData=convert(varchar(20),getdate(),102)
		--> calculez a cata zi din saptamana este data de referinta:
		declare @zi_saptamana int
		select @zi_saptamana=datepart(dw,@cData)
		select @zi_saptamana=(case when @zi_saptamana=1 then 7 else @zi_saptamana-1 end)	--> saptamana incepe duminica la sql server; aici am corectat sa inceapa luni (in speranta  ca nu s-a jucat nimeni cu setarea respectiva)
		--> modific data de referinta (cea din parametri) astfel incat sa fie de la inceputul saptamanii in care se afla, din punctul de vedere al intervalelor:
		select @cData=dateadd(d,7-@zi_saptamana,@cData)
		if @dataFisa is not null set @dataFisa=@cData	--> dataFisa trebuie sa se trimita null daca parametrul cData e null pentru a se lua datele din facturi in loc de pFacturi
	end
	
	create table #fisa(ceva char(1) default '')

	exec rapFisaTerti_structFisa
	
	exec rapFisaTerti @sesiune=@sesiune, @cFurnBenef=@cFurnBenef,@cData=@dataFisa,@cTert=@cTert,@cFactura=@cFactura,@cContTert=@cContTert,@soldmin=@soldmin,
		@soldabs=@soldabs,@dDataFactJos=@dDataFactJos,@dDataFactSus=@dDataFactSus,@dDataScadJos=@dDataScadJos,@dDataScadSus=@dDataScadSus,
		@aviz_nefac=@aviz_nefac,@grupa=@grupa,@grupa_strict=@grupa_strict,@exc_grupa=@exc_grupa,@fsolddata1=@fsolddata1,
		@comanda=@comanda,@indicator=@indicator,@cDataJos=@cDataJos, @tipdoc=@tipdoc, @locm=@locm, @punctLivrare=@punctLivrare,
		@fsold=@fsold, @moneda=@moneda, @valuta=@valuta, @centralizare=@centralizare, @gestiune=@gestiune, @cuefecte=@cuefecte,
		@ordonare=@ordonare
	
	alter table #fisa add data_intervale datetime
	
	if @tipdata='s'
		update #fisa set data_intervale=data_scadentei
	if @tipdata='e'
		update #fisa set data_intervale=data_facturii
	-- daca exista factura in tabela "facturi", se iau de acolo loc de munca si comanda
	update r set loc_de_munca=f.loc_de_munca, comanda=f.comanda
	from #fisa r inner join facturi f on f.tip=(case when @cFurnBenef='F' then 0x54 else 0x46 end) and
			f.subunitate='1' /*r.subunitate*/ and f.factura=r.factura and f.tert=r.tert
	
	if @centralizat=1
	update #fisa set factura='', data_scadentei='1901-1-1', data_facturii='1901-1-1'
	
	select tert, factura, max(data_facturii) data_facturii, max(data_scadentei) data_scadentei, (case when @moneda=0 then sum(total) else sum(total_valuta) end) valoare, max(denumire) denumire,
		1 tipValori, 'Valoare' denTipValori, isnull(i.ordine,0) interval, max(isnull(i.denInterval,'Nescadente')) denInterval,
		max(convert(varchar(200),comanda)) comanda, max(convert(varchar(200),loc_de_munca)) loc_de_munca,
		max(convert(varchar(200),comanda)) cod_comanda, max(convert(varchar(200),loc_de_munca)) cod_loc_de_munca,
		sum(achitat_efect) achitat_efect,
		(case when @ordonare=1 then max(denumire)+'|'+max(factura) else max(tert)+'|'+convert(varchar(20),max(data_facturii),102) end) as ordine
		,max(data_intervale) data_intervale
		--,(case when efect='' then)
	into #fisaIntervale
	from #fisa left join #zile i on datediff(day,isnull(data_intervale,'1901-1-1'),@cData) between inceput and sfarsit
		where @detaliat=1
	group by tert,factura, i.ordine
	union all
	select tert, factura, max(data_facturii) data_facturii, max(data_scadentei) data_scadentei, (case when @moneda=0 then sum(achitat) else sum(achitat_valuta) end) valoare, max(denumire) denumire,
		2 tipValori, 'Achitat', isnull(i.ordine,0) interval, max(isnull(i.denInterval,'Nescadente')),
		max(comanda), max(loc_de_munca),
		max(comanda) cod_comanda, max(loc_de_munca) cod_loc_de_munca, sum(achitat_efect)
		,(case when @ordonare=1 then max(denumire)+'|'+max(factura) else max(tert)+'|'+convert(varchar(20),max(data_facturii),102) end) as ordine
		,max(data_intervale) data_intervale
	from #fisa left join #zile i on datediff(day,isnull(data_intervale,'1901-1-1'),@cData) between inceput and sfarsit
		where @detaliat=1
	group by tert,factura, i.ordine
	union all
	select tert, factura, max(data_facturii) data_facturii, max(data_scadentei) data_scadentei, (case when @moneda=0 then sum(soldf) else sum(soldf_valuta) end) valoare, max(denumire) denumire,
		3 tipValori, 'Sold', isnull(i.ordine,0) interval, max(isnull(i.denInterval,'Nescadente')),
		max(comanda), max(loc_de_munca),
		max(comanda) cod_comanda, max(loc_de_munca) cod_loc_de_munca, sum(achitat_efect)
		,(case when @ordonare=1 then max(denumire)+'|'+max(factura) else max(tert)+'|'+convert(varchar(20),max(data_facturii),102) end) as ordine
		,max(data_intervale) data_intervale
	from #fisa left join #zile i on datediff(day,isnull(data_intervale,'1901-1-1'),@cData) between inceput and sfarsit
	group by tert,factura, i.ordine
	
	update f set comanda=(case when @siCoduri=1 then '('+rtrim(f.comanda)+') '+rtrim(isnull(c.descriere,'')) else rtrim(c.descriere) end),
				loc_de_munca=(case when @siCoduri=1 then '('+rtrim(f.loc_de_munca)+') '+rtrim(isnull(lm.denumire,'')) else rtrim(lm.denumire) end)
	from #fisaintervale f left join comenzi c on f.comanda=c.comanda and c.subunitate='1'
		left join lm on lm.cod=f.loc_de_munca --and lm.subunitate='1'

	if @soldmintert is not null
	delete i from #fisaIntervale i where (@soldmintert>abs((select sum(s.valoare) from #fisaIntervale s where i.tert=s.tert and s.tipvalori=3)))
	
	if isnull(@parXML.value('(row/@specific)[1]','bit'),0)=1
		and exists (select 1 from sys.objects where name='rapFisaTertipeIntervaleSP2')
		exec rapFisaTertipeIntervaleSP2 @parXML=@parXML
	else
		select tert, factura, data_facturii, data_scadentei, valoare, denumire, tipValori, denTipValori, interval, denInterval, isnull(comanda,'') comanda, isnull(loc_de_munca,'') loc_de_munca, ordine, data_intervale
			from #fisaIntervale where (abs(valoare)>0.001)
		union all
		select tert, factura, data_facturii, data_scadentei, achitat_efect valoare, denumire, tipValori, denTipValori, 1000 interval, 'Efecte' denInterval, isnull(comanda,'') comanda, isnull(loc_de_munca,'') loc_de_munca, ordine, data_intervale
			from #fisaIntervale where (@cuefecte=1 and abs(achitat_efect)>0.001)
		union all
		select tert, factura, data_facturii, data_scadentei, achitat_efect+valoare, denumire, tipValori, denTipValori, 1001 interval, 'Total' denInterval, isnull(comanda,'') comanda, isnull(loc_de_munca,'') loc_de_munca, ordine, data_intervale
			from #fisaIntervale
		order by ordine
			--*/	
			select 'test',@zi_saptamana,@cData,* from #zile order by ordine
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (rapFisaTertipeIntervale)'
end catch
	
IF OBJECT_ID('tempdb..#fisa') IS NOT NULL drop table #fisa
if (@eroare<>'')
	--raiserror(@eroare,16,1)
	select '<EROARE>' as tert, @eroare as denumire
end
