--***
create procedure wOPGenerareDocDinBF @sesiune varchar(50), @parXML xml 
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareDocDinBFSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPGenerareDocDinBFSP @sesiune, @parXML output
	return @returnValue
end

declare @userASiS varchar(200),@datNumar int,@numar_documente_de_generat int
set @datNumar=0
begin try
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	declare @sub varchar(20),@TermPeSurse int
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output 
	exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''


	declare @lGenBKdinBF int,@lGenAPdinBF int,@dataJos datetime,@dataSus datetime,@filtruLocMuncaUtilizator int,
		@fGestiune varchar(20),@fTert varchar(20),@fContract varchar(20),@fValuta varchar(20),@Curs float
	declare @fLM varchar(20),@lm varchar(20),@serie varchar(20)

	select @filtruLocMuncaUtilizator=dbo.f_areLMFiltru(@userASiS)
	select
		 @lGenBKdinBF=ISNULL(@parXML.value('(/*/@lGenBKdinBF)[1]', 'int'), 0),
		 @lGenAPdinBF=ISNULL(@parXML.value('(/*/@lGenAPdinBF)[1]', 'int'), 0),
		 @dataJos=isnull(@parXML.value('(/*/@datajos)[1]','datetime'),'1901-01-01'),
		 @dataSus=isnull(@parXML.value('(/*/@datasus)[1]','datetime'),'2901-01-01'),
		 @fGestiune=@parXML.value('(/*/@f_gestiune)[1]','varchar(20)'),
		 @fTert=@parXML.value('(/*/@f_tert)[1]','varchar(20)'),
		 @fContract=@parXML.value('(/*/@f_contract)[1]','varchar(20)'),
		 @fValuta=@parXML.value('(/*/@f_valuta)[1]','varchar(20)'),
		 @Curs=isnull(@parXML.value('(/*/@curs)[1]','float'),0),
		 @fLm=isnull(@parXML.value('(/*/@f_lm)[1]','varchar(20)'),'')

	select c.subunitate,t.termen,c.tert,c.contract,c.punct_livrare,
		p.cod,t.cantitate,t.pret,c.loc_de_munca,c.gestiune,c.valuta,n.cota_tva,c.scadenta,(case when @fValuta is null or @curs=0 then v.curs_curent else @Curs end) as curs,p.discount
	into #contractate
	from termene t 
	inner join pozcon p on p.subunitate=t.subunitate and p.tip='BF' and p.tert=t.tert and p.contract=t.contract 
							and t.cod=(case when @TermPeSurse=0 then p.cod else ltrim(str(p.numar_pozitie)) end)
	inner join con c on t.subunitate=c.subunitate and t.tert=c.tert and t.contract=c.contract and t.data=c.data and c.stare='1'
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and c.Loc_de_munca=lu.cod
	left join nomencl n on p.cod=n.cod
	left outer join valuta v on c.valuta=v.valuta
	where t.tip='BF' 
	and t.termen between @datajos and @datasus and t.cant_realizata=0 -- un termen se factureaza o singura data 
	and (@fTert is null or c.tert=@fTert)
	and (@fContract is null or c.contract=@fContract)
	and (@fValuta is null or c.Valuta=@fValuta)
	and (@fGestiune is null or c.gestiune=@fGestiune)
	and (isnull(@flm,'')='' or c.loc_de_munca like rtrim(@flm)+'%')
	and (@filtruLocMuncaUtilizator=0 or lu.cod is not null)

	select @numar_documente_de_generat=count(*),@lm=max(c1.loc_de_munca) from 
		(select c.subunitate,c.tert,c.contract,c.punct_livrare,c.termen,c.loc_de_munca,c.gestiune,c.valuta
			from #contractate c
			left outer join valuta v on c.valuta=v.valuta
			group by c.subunitate,c.tert,c.contract,c.punct_livrare,c.termen,c.loc_de_munca,c.gestiune,c.termen,c.valuta) c1

	if @numar_documente_de_generat=0
		return

	/* Pentru luare numere. Vom lua primul loc de munca de pe max(loc_de_munca) - vezi mai sus
		Jurnal nu are.
	*/

	declare @fXML xml, @NrDocPrimit varchar(20),@tip varchar(20),@numarinitial int,@serieinnr int

	if @lGenAPdinBF=1
		set @tip='AP'
	else
		set @tip='BK'			
	set @fXML = '<row/>'
	set @fXML.modify ('insert attribute codMeniu {"CO"} into (/row)[1]')
	set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')
	set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
	set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
	set @fXML.modify ('insert attribute documente {sql:variable("@numar_documente_de_generat")} into (/row)[1]')
	exec wIauNrDocFiscale @parXML=@fXML, @numar=@numarinitial output,@serie=@serie,@NrDoc=@NrDocPrimit output
	
	select top 1 @serieinnr=isnull(serieinnumar,0) from docfiscale where TipDoc=@tip and serie=@serie
	
	alter table #contractate add numarDoc varchar(20),total_contractat float,total_tva float

	update #contractate
	set numarDoc=(case when @serieinnr=1 then rtrim(@serie) else '' end)+ltrim(str(@numarinitial+contr.nrrand)),
		total_contractat=tcon,total_tva=ttva
			from (select c.subunitate,c.tert,c.contract,c.punct_livrare,c.termen,row_number() over (order by c.subunitate,c.tert,c.contract,c.punct_livrare,c.termen) as nrrand,
			sum(round(c.cantitate*c.pret,2)) as tcon,sum(round(c.cantitate*c.pret*c.cota_tva/100,2)) as ttva
			from #contractate c
		group by c.subunitate,c.tert,c.contract,c.punct_livrare,c.termen
		) contr where #contractate.subunitate=contr.subunitate and #contractate.tert=contr.tert and #contractate.contract=contr.contract and 
		#contractate.punct_livrare=contr.punct_livrare and #contractate.termen=contr.termen

	--------------Gata luare numar-----------------------------------------------------
	
	if @lGenBKdinBF=1 or @lGenAPdinBF=1 --Se vor genera contracte
	begin

		insert into con (Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Stare,Loc_de_munca,Gestiune,
		Termen,Scadenta,Discount,Valuta,Curs,
		Mod_plata,Mod_ambalare,Factura,Total_contractat,Total_TVA,Contract_coresp,Mod_penalizare,
		Procent_penalizare,Procent_avans,Avans,Nr_rate,Val_reziduala,Sold_initial,Cod_dobanda,Dobanda,Incasat,
		Responsabil,Responsabil_tert,Explicatii,Data_rezilierii)
		select c.subunitate,'BK',c.numarDoc,
		c.tert,c.punct_livrare,c.termen,'1',c.loc_de_munca,c.gestiune,
		c.termen,0, 0, c.valuta, max(isnull(c.curs,0)),'','','',max(c.total_contractat),max(c.total_tva),c.contract,'',
					0,0,0,0,0,0,'',1,0,	'','','Generat','1901-01-01'	
		from #contractate c
		group by c.subunitate,c.tert,c.contract,c.numarDoc,c.punct_livrare,c.termen,c.loc_de_munca,c.gestiune,c.termen,c.valuta


		insert into pozcon 
		(Subunitate,Tip,Contract,Tert,Punct_livrare,Data,Cod,Cantitate,
		Pret,Pret_promotional,Discount,Termen,Factura,Cant_disponibila,Cant_aprobata,Cant_realizata,
		Valuta,Cota_TVA,Suma_TVA,Mod_de_plata,UM,Zi_scadenta_din_luna,Explicatii,Numar_pozitie,Utilizator,
		Data_operarii,Ora_operarii) 
		select c.subunitate, 'BK', c.numardoc, c.tert, c.punct_livrare, c.termen, c.cod, c.cantitate, c.pret, 0, 0, c.termen, (case when @lGenAPdinBF=1 then c.numardoc else '' end), 0, c.cantitate, 0,
		c.valuta,c.cota_tva, round((c.cantitate*c.pret*c.cota_tva/100),2), '', '', 0, 'Generate', row_number() over (order by c.subunitate,c.tert,c.contract,c.numarDoc,c.cod),
		@userASiS,convert(datetime, convert(char(10), getdate(), 104), 104), RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
		from #contractate c


	end

	if @lGenAPdinBF=1 --Se vor genera facturi
	begin

		declare @pX xml
		set @pX=
			(
			select rtrim(c.subunitate) as '@subunitate','AP' as '@tip',rtrim(c.numardoc) as '@numar',convert(datetime,c.termen,101) as '@data',c.loc_de_munca as '@loc_de_munca',
			rtrim(c.tert) as '@tert',rtrim(c.punct_livrare) as '@punctlivrare',rtrim(c.numardoc) as '@contract',c.scadenta as '@zilescadenta',c.gestiune as '@gestiune'
				,(select	convert(varchar(20),c.pret) as '@pvaluta', rtrim(c.valuta) as '@valuta',convert(varchar(20),c.curs) as '@curs',
					CONVERT(decimal(5,2),c.Discount) as '@discount', rtrim(c.cod) as '@cod', 
					rtrim(convert(varchar(20),c.cantitate)) as '@cantitate'
				from #contractate c1 where c1.numardoc=c.numardoc
				for xml path,type)
			from #contractate c
			left outer join valuta v on c.valuta=v.valuta
			for xml path,type
			)
		-- merge doar pentru un contract!
		exec wScriuPozdoc @sesiune=@sesiune, @parXML=@pX
		--select @px
	end
	drop table #contractate
end try
begin catch
	declare @mesaj varchar(1000)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
