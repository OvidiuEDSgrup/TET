--***
create procedure wScriuNcon @sesiune varchar(50), @parXML xml output
as 

declare @subunitate varchar(20),@Bugetari int,@eroare xml,@lmproprietate varchar(20),@utilizator varchar(50)
--
begin try
		
	if app_name() not like '%unipaas%'
		EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT  
	else
		select top 1 @Utilizator=rtrim(utilizator) from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
		
	exec luare_date_par 'GE','BUGETARI', @Bugetari output, 0, ''
	exec luare_date_par 'GE','SUBPRO', 0,0,@Subunitate output

	set @lmproprietate=isnull((select max(l.cod) from lmfiltrare l where l.utilizator=@utilizator),'')
		
--> citire si organizare parametri:
	
	CREATE TABLE [dbo].[#pozncon](
		[Subunitate] [varchar](9) NOT NULL,
		[Tip] [varchar](2) NOT NULL,
		[Numar] [varchar](13) NOT NULL,
		[Data] [datetime] NOT NULL,
		[Cont_debitor] [varchar](40) NOT NULL,
		[Cont_creditor] [varchar](40) NOT NULL,
		[Suma] [float] NOT NULL,
		[Valuta] [varchar](3) NOT NULL,
		[Curs] [float] NOT NULL,
		[Suma_valuta] [float] NOT NULL,
		[Explicatii] [varchar](50) NOT NULL,
		[Utilizator] [varchar](10) NOT NULL,
		[Data_operarii] [datetime] NOT NULL,
		[Ora_operarii] [varchar](6) NOT NULL,
		[Nr_pozitie_primit] [int],
		[Nr_pozitie_calculat] [int] NOT NULL,
		[Loc_munca] [varchar](9) NOT NULL,
		[Comanda] [varchar](20) NOT NULL,
		[Indbug] [varchar](20) NOT NULL,
		[Tert] [varchar](13) NOT NULL,
		[Jurnal] [varchar](3) NOT NULL,
		[Detalii] [xml],
		[idPozncon] [int], 
		_update [int],
		pid [int]
	)

	declare @iDoc int,@rootDoc varchar(20),@multiDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	if @parXML.exist('(/Date)')=1 --Daca exista parametrul Date inseamna ca avem date multiple de introdus in tabela
	begin
		set @rootDoc='/Date/row/row'
		set @multiDoc=1
	end
	else
	begin
		set @rootDoc='/row/row'
		set @multiDoc=0
	end

	insert into #pozncon(subunitate, tip, numar, data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, Utilizator,
		Data_operarii, Ora_operarii, Nr_pozitie_primit, Nr_pozitie_calculat, Loc_munca, Comanda, Indbug, Tert, Jurnal, Detalii, idPozncon, _update, pid)
	select 	@subunitate,
		isnull(nullif(tip,''),'NC'), 
		upper(numar), 
		data, 
		isnull(cont_debitor, '') as cont_debitor, 
		isnull(cont_creditor, '') as cont_creditor,
		isnull(suma,0) as suma,
		upper(isnull(valuta,'')) as valuta,
		isnull(curs,0) as curs,
		isnull(suma_valuta,0) as suma_valuta,
		isnull(explicatii,'') as explicatii,
		@utilizator,
		convert(datetime, convert(char(10), getdate(), 104), 104),
		RTrim(replace(convert(char(8), getdate(), 108), ':', '')),
		/*Linia de mai jos citeste numarul de pozitie (din XML) sau in cazul in care este NULL il face cu ROW_NUMBER
			In momentul adaugarii liniilor noi se va pune aceasta pozitie (1 spre exemplu) la numarul maxim de pe acel document pentru a elimina dublurile
		*/
		nr_pozitie as nr_pozitie_primit,
		ROW_NUMBER() over (PARTITION BY numar ORDER BY isnull(nr_pozitie,0),cont_debitor,cont_creditor) as nr_pozitie_calculat,
		upper(case when loc_munca is null then @lmproprietate else isnull(loc_munca,'') end) as loc_munca,
		upper(isnull(comanda,'')) as comanda,
		upper(isnull(indbug,'')) as indbug,
		upper(isnull(tert,'')) as tert,
		upper(isnull(jurnal,'')) as jurnal,
		detalii as detalii,
		idPozncon as idPozncon,
		_update,
		dense_rank() over (order by pid) pid
	from OPENXML(@iDoc, @rootDoc)
		WITH 
		(
			pid int '@mp:parentid',
			detalii xml 'detalii/row',
			tip char(2) '../@tip', 
			numar char(13) '../@numar',
			data datetime '../@data',
			cont_debitor varchar(40) '@cont_debitor',
			cont_creditor varchar(40) '@cont_creditor', 
			suma float '@suma',
			valuta char(3) '@valuta',
			curs float '@curs',
			suma_valuta float '@suma_valuta',
			explicatii char(50) '@ex', 
			nr_pozitie int '@nr_pozitie',
			loc_munca char(9) '@lm',
			comanda char(20) '@comanda',
			indbug char(20) '@indbug',
			tert char(13) '@tert',
			jurnal char(3) '@jurnal',
			idpozncon int '@idpozncon',
			_update int '@update'
		)
		exec sp_xml_removedocument @iDoc 
--> validari (care nu se pot face in trigger):
		if exists(select 1 from #pozncon p2 where _update=1 and nr_pozitie_primit is null)
			raiserror('Nu se poate update fara numar de pozitie!',16,1)

--> completare numar NC
		if exists (select 1 from #pozncon where isnull(numar,'')='')
		begin
			declare @nr decimal(13)
			set @nr=(select max(cast(numar as decimal(13))) 
							from pozncon where isnumeric(rtrim(numar))<>0 and rtrim(numar) not in ('.',',') 
							   and charindex('-',rtrim(numar))=0 and charindex(',',rtrim(numar))=0 
							   and charindex('.',rtrim(numar))=0 
					 group by subunitate)
			set @nr=@nr+1
			update #pozncon set numar=ltrim(str(convert(decimal(13),@nr)+pid-1,13))
			where isnull(numar,'')=''
		end

--> prelucrari de date:
		/*In tabela temporara #nrpozitii fac join pe pozncon doar pentru documentele de adaugat (de regula unul) pentru a lua numarul maxim de pozitii*/
		select p1.subunitate,p1.tip,p1.numar,p1.data,isnull(max(p2.nr_pozitie),0) as maxpoz
		into #nrpozitii
		from #pozncon p1
			left outer join pozncon p2 on p1.Subunitate=p2.Subunitate and p1.tip=p2.tip and p1.Data=p2.Data and p1.Numar=p2.Numar
		group by p1.subunitate,p1.tip,p1.numar,p1.data
	
		/*Rog scrierea unor specificatii pentru bugetari
			Nu inteleg exact din ce tabele isi ia datele 
			Traduc doar ceea ce am vazut in codul wFormezIndicatorBugetar dar nefiind date specificatiile nu stiu daca este bine sau nu.
			Cred ca linia de mai jos rezolva oarecum cazul general in loc de 4 apeluri la wFormezIndicatorBugetar dar nu sunt sigur.
		*/
		if @Bugetari=1 and 1=0
		begin
			-- scos completarea indicatorului bugetar. Indicatorul va fi completat doar in tabela conturi (detalii).
			-- completare indicator bugetar - m-am inspirat din procedura wFormezIndicatorBugetar: 
			-- in varianta anterioara de wScriuPozNCon se luau, in ordine: cazul contdeb=6, apoi contcre=7, apoi cazul de mai jos
			-- se presupune ca exista asociere de ind. bug. pe cont debit, iar daca nu pe cont credit - daca nu exista se lasa necompletat
			-- daca exista ind. bug. asociat conturilor, acesta se modifica prin inlocuirea primelor caratere cu cele de pe locul de munca 	
			-- ex. pe contul deb. ar fi indicatorul 512.3456, pe locul de munca ar fi prefixul 455 => indicator calculat 455.3456
			update p1 set Indbug=(case when isnull(ccd.Cont_strain,isnull(ccc.cont_strain,''))='' then '' 
				else rtrim(isnull(substring(sp.Comanda,21,20),''))+substring(isnull(ccd.Cont_strain,isnull(ccc.cont_strain,'')),LEN(rtrim(isnull(substring(sp.Comanda,21,20),'')))+1,20) end)
			from #pozncon p1
				left outer join speciflm sp on p1.Loc_munca=sp.loc_de_munca
				left outer join contcor ccd on p1.Cont_debitor=ccd.ContCG
				left outer join contcor ccc on p1.Cont_debitor=ccc.ContCG
			where p1.Indbug=''
		end

--> scrierea propriu-zisa:
		/*In cazul update-ului se va face un DELETE si un INSERT. Nu avem de unde sti exact ce campuri ar dori sa fie actualizate
		Linia de mai jos face delete from p1,p2 where p2._update=1 (adica XML.update=1)*/
		/* Am tratat similar cu wScriuDoc, cu update si insert */
		begin tran scpozncon
			IF OBJECT_ID('tempdb..#poznconIns') is not null drop table #poznconIns
			create table #poznconIns (idpozncon int, nr_pozitie int)

			/*delete p1 
			from pozncon p1,#pozncon p2 
			where p2._update=1 and p1.Subunitate=p2.Subunitate and p1.tip=p2.tip and p1.Data=p2.Data and p1.Numar=p2.Numar and p1.Nr_pozitie=p2.Nr_pozitie_primit*/
			if (select count(*) from #pozncon where _update=1)>0 /*Se va modifica pozitia din tabela pozncon*/
				update pozncon  
					set Cont_debitor=isnull(#pozncon.cont_debitor,pozncon.cont_debitor), 
						Cont_creditor=isnull(#pozncon.cont_creditor,pozncon.cont_creditor), 
						Suma=isnull(#pozncon.suma,pozncon.suma), 
						Valuta=isnull(#pozncon.valuta,pozncon.valuta), 
						Curs=isnull(#pozncon.curs,pozncon.curs), 
						Suma_valuta=isnull(#pozncon.suma_valuta,pozncon.suma_valuta), 
						Explicatii=isnull(#pozncon.explicatii,pozncon.explicatii), 
						Utilizator=@utilizator,
						Data_operarii=convert(datetime, convert(char(10), getdate(), 104), 104), 
						Ora_operarii=RTrim(replace(convert(char(8), getdate(), 108), ':', '')),
						Nr_pozitie=isnull(#pozncon.Nr_pozitie_primit,pozncon.Nr_pozitie),
						Loc_munca=isnull(#pozncon.Loc_munca,pozncon.Loc_munca), 
						Comanda=isnull(#pozncon.comanda+(case when #pozncon.tip in ('AO','AL') then #pozncon.indbug else '' end),pozncon.comanda), 
						Tert=isnull(#pozncon.tert,pozncon.tert), 
						Jurnal=isnull(#pozncon.jurnal,pozncon.jurnal), 
						Detalii=isnull(#pozncon.detalii,pozncon.detalii)
				from #pozncon
				where pozncon.idPozncon=#pozncon.idpozncon
			else
				insert into pozncon
					(Subunitate,Tip,Numar,Data,Cont_debitor,Cont_creditor,Suma,Valuta,Curs,Suma_valuta,Explicatii,Utilizator,Data_operarii,Ora_operarii,Nr_pozitie,Loc_munca,Comanda,Tert,Jurnal,Detalii)
				OUTPUT inserted.idPozncon, inserted.Nr_pozitie INTO #poznconIns (idPozncon, nr_pozitie) 
				select p1.Subunitate,p1.Tip,p1.Numar,p1.Data,p1.Cont_debitor,p1.Cont_creditor,p1.Suma,p1.Valuta,p1.Curs,p1.Suma_valuta,p1.Explicatii,p1.Utilizator,p1.Data_operarii,p1.Ora_operarii,
					(case when p1._update=1 or isnull(p1.nr_pozitie_primit,0)<>0 then p1.nr_pozitie_primit else p2.maxpoz+p1.Nr_pozitie_calculat end),
					p1.Loc_munca,p1.Comanda+(case when p1.tip in ('AO','AL') then p1.indbug else '' end),p1.Tert,p1.Jurnal,p1.Detalii
				from #pozncon p1
					 inner join #nrpozitii p2 on p1.Subunitate=p2.Subunitate and p1.tip=p2.tip and p1.Data=p2.Data and p1.Numar=p2.Numar

			/* Pentru bugetari se apeleaza procedura ce scrie in pozncon.detalii, a indicatorului bugetar stabilit in mod unitar prin procedura indbugPozitieDocument. */
			if @bugetari=1 and exists (select 1 from #pozncon where isnull(_update,0)=0)
				and exists (select 1 from sysobjects where [type]='P' and [name]='indbugPozitieDocument')
			begin
				declare @parXMLIndbug xml
				IF OBJECT_ID('tempdb..#indbugPozitieDoc') is not null drop table #indbugPozitieDoc
				create table #indbugPozitieDoc (furn_benef char(1), tabela varchar(20), idPozitieDoc int, indbug varchar(20))
				insert into #indbugPozitieDoc (furn_benef, tabela, idPozitieDoc)
				select '', 'pozncon', idpozncon from #poznconIns
				
				set @parXMLIndbug=(select 1 as scriere for xml raw)
				exec indbugPozitieDocument @sesiune=@sesiune, @parXML=@parXMLIndbug
			end

		commit tran scpozncon
--> pentru apel direct din macheta:
		if @multiDoc=0
		begin
			declare @numar varchar(20),@data datetime
			select top 1 @numar=numar,@data=data from #pozncon

			declare @docXMLIaPozNcon xml
			set @docXMLIaPozNcon = '<row subunitate="' + rtrim(@subunitate) + '" tip="' + 'NC' + '" numar="' + rtrim(@numar) + '" data="' + convert(char(10), @data, 101) +'"/>'
			exec wIaPozNcon @sesiune=@sesiune, @parXML=@docXMLIaPozNcon
		end
		drop table #pozncon
		drop table #nrpozitii
end try
begin catch
	if EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'scpozncon')
		ROLLBACK TRAN scpozncon
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
