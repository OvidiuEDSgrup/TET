--***
create procedure indbugPozitieDocument @sesiune varchar(50), @parXML xml
as
begin try
/*
	Aceasta procedura primeste o tabela #ingbugPozitieDoc (furn_benef, tabela, idPozitieDoc, indbug)
	Pe care o altereaza punand in dreptul campului indbug indicatorul bugetar aferent pozitiei de document
	ex.
	create table #ingbugPozitieDoc (furn_benef char(1), tip varchar(20), idPozitieDoc int, indbug varchar(20))
	insert #ingbugPozitieDoc values ('', 'pozdoc', 15475, '')
	exec indbugPozitieDocument @sesiune=null, @parXML
	select * from #ingbugPozitieDoc
	drop table #ingbugPozitieDoc*/
	set nocount on
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	declare @pozitiiRamaseNecompletate int, @actualizareTabele int	--Procedura se va apela cu @actualizareTabele=1 la adaugare documente
	select	@pozitiiRamaseNecompletate=isnull(@parXML.value('(row/@ramase)[1]','int'),0), 
			@actualizareTabele=isnull(@parXML.value('(row/@scriere)[1]','int'),0)

	if @pozitiiRamaseNecompletate=0
	begin
		/* stabilire indicator bugetar pentru pozitiile de documente (pozdoc) */
		update ib 
			set ib.indbug=rtrim(isnull(nullif(pd.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),
				(case	when pd.tip in ('RM','RS','RC','RP','RQ') then isnull(nullif(cf.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(cs.detalii.value('(/row/@indicator)[1]','varchar(20)'),'')) 
						when pd.tip in ('AP','AS','AC') then isnull(nullif(cf.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(cv.detalii.value('(/row/@indicator)[1]','varchar(20)'),isnull(cs.detalii.value('(/row/@indicator)[1]','varchar(20)'),'')))
						when pd.tip in ('DF') and nullif(cv.detalii.value('(/row/@indicator)[1]','varchar(20)'),'') is not null then cv.detalii.value('(/row/@indicator)[1]','varchar(20)')
						when pd.tip in ('CM','AE','CI','AI','TE','PF','DF') then isnull(nullif(ccor.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(cs.detalii.value('(/row/@indicator)[1]','varchar(20)'),'')) 
					else '' end)))
		from #indbugPozitieDoc ib
			inner join pozdoc pd on ib.tabela='pozdoc' and pd.idpozdoc=ib.idPozitieDoc
			left outer join conturi cf on cf.Subunitate=pd.Subunitate and cf.Cont=pd.cont_factura
			left outer join conturi cs on cs.Subunitate=pd.Subunitate and cs.Cont=pd.cont_de_stoc
			left outer join conturi cv on cv.Subunitate=pd.Subunitate and cv.Cont=pd.cont_venituri
			left outer join conturi ccor on ccor.Subunitate=pd.Subunitate and ccor.Cont=pd.cont_corespondent  

		/* stabilire indicator bugetar pentru pozitiile de alte documente (pozadoc) */
		update ib
			set ib.indbug=rtrim(isnull(nullif(pd.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),
					(case when pd.tip in ('FF','FB') then isnull(nullif(cc.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(cd.detalii.value('(/row/@indicator)[1]','varchar(20)'),'')) 
						when pd.tip in ('CO','C3') and isnull(substring(f.comanda,21,20),'')<>'' then isnull(substring(f.comanda,21,20),'')
						when ib.furn_benef in ('F','B') or pd.tip in ('CF','FX','SF','SX','CB','BX','IF','IX') 
							then isnull(nullif(cc.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),isnull(nullif(cd.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),
								(case when pd.Data<'2014-01-01' then '' else isnull(substring(f.comanda,21,20),'') end)))
						else '' end)))
		from #indbugPozitieDoc ib
			inner join pozadoc pd on ib.tabela='pozadoc' and pd.idPozadoc=ib.idPozitieDoc
			left outer join conturi cd on cd.subunitate = pd.subunitate and cd.cont = pd.cont_deb
			left outer join conturi cc on cc.subunitate = pd.subunitate and cc.cont = pd.Cont_cred
			left outer join facturi f on f.subunitate = pd.subunitate 
		/* din procedura pFacturi trimit furn_benef F sau B. Din restul procedurilor ne bazam doar pe tip. Avem nevoie de furn_benef pentru CO si C3. */
				and f.tip = (case when ib.furn_benef='F' or pd.tip in ('CF','SF','SX','FX') then 0x54 when ib.furn_benef='B' or pd.tip in ('CB','BX','IF','IX') then 0x46 else '' end) 
				and f.tert=pd.tert and f.factura=(case when ib.furn_benef='F' or pd.tip in ('CF','SF') then pd.factura_stinga 
					when ib.furn_benef='B' or pd.tip in ('CB','SI') then pd.Factura_dreapta else '' end)

		/* stabilire indicator bugetar pentru pozitiile de plati incasari (pozplin) */
		update ib
			set ib.indbug=rtrim(isnull(nullif(pp.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),
					(case	when left(pp.Cont,1) in ('6','7') and nullif(ca.detalii.value('(/row/@indicator)[1]','varchar(20)'),'') is not null then isnull(ca.detalii.value('(/row/@indicator)[1]','varchar(20)'),'') 
							else isnull(nullif(cc.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),
								(case when pp.Data<'2014-01-01' then '' else isnull(substring(f.comanda,21,20),'') end)) 
							end)))
		from #indbugPozitieDoc ib
			inner join pozplin pp on ib.tabela='pozplin' and pp.idPozplin=ib.idPozitieDoc
			left outer join conturi ca ON ca.subunitate = pp.subunitate and ca.cont = pp.cont
			left outer join conturi cc ON cc.subunitate = pp.subunitate and cc.cont = pp.cont_corespondent
			left outer join facturi f on f.subunitate=pp.subunitate 
				and f.tip=(case when pp.plata_incasare in ('IB','IR','PS') or pp.plata_incasare='ID' and pp.Cont_corespondent like '482%' then 0x46 --	ID/PD cu 482 reprezinta dedublarea incasarilor/platilor prin 482 la ANAR
							when pp.plata_incasare in ('PF','PR','IS') or pp.plata_incasare='PD' and pp.Cont_corespondent like '482%' then 0x54 else '' end) 
				and f.tert=pp.tert and f.factura=pp.factura

		/* stabilire indicator bugetar pentru pozitiile de note contabile (pozncon) */
		update ib
			set ib.indbug=rtrim(case when pn.detalii.value('(/row/@fara_indicator)[1]','int')=1 then ''
				when pn.tip in ('AO','AL') then substring(pn.comanda,21,20)			--pentru documente de ALOP ramine sa citim inca indicatorul bugetar din comanda
				else isnull(nullif(pn.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),		--indicator din pozncon.detalii
					isnull(nullif(cd.detalii.value('(/row/@indicator)[1]','varchar(20)'),''),		--indicator din cont debitor.detalii
						isnull(cc.detalii.value('(/row/@indicator)[1]','varchar(20)'),''))) end)	--indicator din cont creditor.detalii
		from #indbugPozitieDoc ib
			inner join pozncon pn on ib.tabela='pozncon' and pn.idPozncon=ib.idPozitieDoc
			left outer join conturi cd ON cd.subunitate = pn.subunitate and cd.cont = pn.cont_debitor
			left outer join conturi cc ON cc.subunitate = pn.subunitate and cc.cont = pn.cont_creditor
	end

	/*	stabilire indicator bugetar pentru pozitiile de alte documente (pozadoc) la care nu s-a reusit completarea indicatorului prin update-urile initiale
		Acest caz apare la refacere facturi, cand nu exista in tabela facturi pozitii pentru factura stinga/dreapta */
	if @pozitiiRamaseNecompletate=1 and object_id('tempdb..#docfac') is not null
	begin
		/*	mai intai completez indicatorul pe pozitiile care preiau indicatorul de pe pozitii cu indicator completate anterior. 
			Ex. factura stinga de la SF preia indicatorul de la factura operata pe receptia nesosita  */
		update a
			set a.indbug=rtrim(b.indbug), a.comanda=isnull(left(a.comanda,20)+rtrim(b.indbug),a.comanda)
		from #docfac a
			cross apply (select top 1 indbug from #docfac b where b.tert=a.tert and b.factura=a.factura and b.fel in ('2','4') and b.tip<>a.tip and b.idPozitieDoc<>a.idPozitieDoc
				and nullif(b.indbug,'') is not null) b
		where a.tip in ('CF','FX','SF','SX','CB','BX','IF','IX') and nullif(a.indbug,'') is null

		/*	completez indicatorul pe pozitiile corespondente celor preluate mai sus. Ex. factura dreapta de la SF preia indicatorul de la factura stinga */
		update a
			set a.indbug=rtrim(b.indbug), a.comanda=isnull(left(a.comanda,20)+rtrim(b.indbug),a.comanda)
		from #docfac a
			left outer join #docfac b on b.idPozitieDoc=a.idPozitieDoc and nullif(b.indbug,'') is not null
		where a.tip in ('CF','FX','SF','SX','CB','BX','IF','IX') and nullif(a.indbug,'') is null
	end

	/*	Daca se apeleaza procedura cu parametru de actualizare tabele=1, punem indicatorul in detalii. */
	if @actualizareTabele=1
	begin
	/*	Completare indicator bugetar in POZDOC.detalii.	
		Am tratat cu if exists ca sa functioneze mai repede, update-urile la apelare dinspre o singura tabela.*/
		if exists (select 1 from #indbugPozitieDoc where tabela='pozdoc')
		begin
			update p 
				set p.detalii='<row />'
			from pozdoc p
				inner join #indbugPozitieDoc ib on ib.tabela='pozdoc' and ib.idPozitieDoc=p.idPozdoc
			where p.detalii is null 
		/*	In caz ca in detalii existau deja atribute cu valori, inserez indicatorul bugetar.	*/
			update p 
				set detalii.modify('insert attribute indicator {sql:column("ib.indbug")} into (/row)[1]') 
			from pozdoc p
				inner join #indbugPozitieDoc ib on ib.tabela='pozdoc' and ib.idPozitieDoc=p.idPozdoc
			where p.detalii.value('(/row/@indicator)[1]','varchar(20)') is null and ib.indbug is not null
		/*	Tratam si cazul pozitiilor deja operate care au detalii.indicator='' si pentru care prin scriptul specific, vom completa indicatorul in detalii.*/
			update p 
				set detalii.modify('replace value of (/row/@indicator)[1] with sql:column("ib.indbug")') 
			from pozdoc p
				inner join #indbugPozitieDoc ib on ib.tabela='pozdoc' and ib.idPozitieDoc=p.idPozdoc
			where p.detalii.value('(/row/@indicator)[1]','varchar(20)')='' and ib.indbug is not null
		end

	/*	Completare indicator bugetar in POZADOC.detalii.	*/
		if exists (select 1 from #indbugPozitieDoc where tabela='pozadoc')
		begin
			update p 
				set p.detalii='<row />'
			from pozadoc p
				inner join #indbugPozitieDoc ib on ib.tabela='pozadoc' and ib.idPozitieDoc=p.idPozadoc
			where p.detalii is null 
		/*	In caz ca in detalii existau deja atribute cu valori, inserez indicatorul bugetar.	*/
			update p 
				set detalii.modify('insert attribute indicator {sql:column("ib.indbug")} into (/row)[1]') 
			from pozadoc p
				inner join #indbugPozitieDoc ib on ib.tabela='pozadoc' and ib.idPozitieDoc=p.idPozadoc
			where p.detalii.value('(/row/@indicator)[1]','varchar(20)') is null and ib.indbug is not null
		/*	Tratam si cazul pozitiilor deja operate care au detalii.indicator='' si pentru care prin scriptul specific, vom completa indicatorul in detalii.*/
			update p 
				set detalii.modify('replace value of (/row/@indicator)[1] with sql:column("ib.indbug")') 
			from pozadoc p
				inner join #indbugPozitieDoc ib on ib.tabela='pozadoc' and ib.idPozitieDoc=p.idPozadoc
			where p.detalii.value('(/row/@indicator)[1]','varchar(20)')='' and ib.indbug is not null
		end

	/*	Completare indicator bugetar in POZPLIN.detalii.	*/
		if exists (select 1 from #indbugPozitieDoc where tabela='pozplin')
		begin
			update p 
				set p.detalii='<row />'
			from pozplin p
				inner join #indbugPozitieDoc ib on ib.tabela='pozplin' and ib.idPozitieDoc=p.idPozplin
			where p.detalii is null 
		/*	In caz ca in detalii existau deja atribute cu valori, inserez indicatorul bugetar.	*/
			update p 
				set detalii.modify('insert attribute indicator {sql:column("ib.indbug")} into (/row)[1]') 
			from pozplin p
				inner join #indbugPozitieDoc ib on ib.tabela='pozplin' and ib.idPozitieDoc=p.idPozplin
			where p.detalii.value('(/row/@indicator)[1]','varchar(20)') is null and ib.indbug is not null
		/*	Tratam si cazul pozitiilor deja operate care au detalii.indicator='' si pentru care prin scriptul specific, vom completa indicatorul in detalii.*/
			update p 
				set detalii.modify('replace value of (/row/@indicator)[1] with sql:column("ib.indbug")') 
			from pozplin p
				inner join #indbugPozitieDoc ib on ib.tabela='pozplin' and ib.idPozitieDoc=p.idPozplin
			where p.detalii.value('(/row/@indicator)[1]','varchar(20)')='' and ib.indbug is not null
		end

	/*	Completare indicator bugetar in POZNCON.detalii.	*/
		if exists (select 1 from #indbugPozitieDoc where tabela='pozncon')
		begin
			update p 
				set p.detalii='<row />'
			from pozncon p
				inner join #indbugPozitieDoc ib on ib.tabela='pozncon' and ib.idPozitieDoc=p.idPozncon
			where p.detalii is null 
		/*	In caz ca in detalii existau deja atribute cu valori, inserez indicatorul bugetar.	*/
			update p 
				set detalii.modify('insert attribute indicator {sql:column("ib.indbug")} into (/row)[1]') 
			from pozncon p
				inner join #indbugPozitieDoc ib on ib.tabela='pozncon' and ib.idPozitieDoc=p.idPozncon
			where p.detalii.value('(/row/@indicator)[1]','varchar(20)') is null and ib.indbug is not null
		/*	La note contabile pot fi cazuri in care la adaugare este indicatorul bugetar in pozitii si atunci trebuie actualizat indicatorul din detalii cu indicatorul conturilor (daca nu s-a completat).	*/
			update p 
				set detalii.modify('replace value of (/row/@indicator)[1] with sql:column("ib.indbug")') 
			from pozncon p
				inner join #indbugPozitieDoc ib on ib.tabela='pozncon' and ib.idPozitieDoc=p.idPozncon
			where p.detalii.value('(/row/@indicator)[1]','varchar(20)')='' and ib.indbug is not null
		end
	end

	if exists (select 1 from sysobjects where [type]='P' and [name]='indbugPozitieDocumentSP2')
		exec indbugPozitieDocumentSP2 @sesiune, @parXML output
		
end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj = ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 11, 1)
end catch
