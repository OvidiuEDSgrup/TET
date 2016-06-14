IF EXISTS (SELECT *	FROM sysobjects	WHERE NAME = 'RezervaLaIntrareInStocSP')
	DROP PROCEDURE RezervaLaIntrareInStocSP 
GO

/*
	Procedura interpreteaza o tabela temporara numita #tmpderezervat similara cu tabela pozdoc doar ca e inserted din trigger. 
	Liniile curente nu sunt inca scrise in tabela pozdoc.TipLinie - I=Inserted,D=Deleted
	Ea sparge cantitatile pe coduri si comenzi de livrare neinchise
*/
CREATE PROCEDURE RezervaLaIntrareInStocSP
AS
BEGIN TRY
	/*Stocul de rezervat

		daca triggerul este pe POZDOC vine din documentele de intrare in stoc
		daca triggerul este pe jurnalContracte vine din tabela stocuri aferent codurilor la care s-a efectuat definitivarea

	*/
	if trigger_nestlevel()>1
		return
	
	select t.cod,t.gestiune,sum(t.cantitate) as receptionat, t.[contract] --t.cod_intrare, 
	into #derezervatpecoduri
	from #tmpderezervatRN t
	where t.tiplinie='I'
	group by t.cod, t.gestiune, t.[contract] --t.cod_intrare, 
	having sum(t.cantitate)>0
	
	declare @gestiuneRezervari varchar(20),@stareDefinitiva int,@idplajaptrezervari int
	EXEC luare_date_par 'GE', 'REZSTOCBK', 0, @idplajaptrezervari OUTPUT, @gestiuneRezervari OUTPUT
	/*Starea definitiva este prima stare nemodificabila*/
	select top 1 @stareDefinitiva=stare from StariContracte where tipContract='RN' and modificabil=0 and transportabil=1 order by stare
	
	/*Contractele deschise*/
	select pt.idpozcontract,pt.cod,pt.cantitate as necesar,isnull(nullif(pt.detalii.value('(/row/@gestiune)[1]','varchar(20)'),''),ct.gestiune) as gestiune
	into #necesar
	from PozContracte pt join Contracte ct on ct.idContract=pt.idContract 
		join necesaraprov na on na.Numar=ct.numar and na.Data=ct.data and na.Numar_pozitie=pt.idPozContract
		join pozaprov pa on pa.Tip='N' and pa.Comanda_livrare=na.Numar and pa.Data_comenzii=na.Data and pa.Beneficiar='' and pa.Cod=na.Cod
		join pozcon pn on pn.Subunitate='1' and pn.tip='FC' and pn.Contract=pa.Contract and pn.Data=pa.Data and pn.Tert=pa.Furnizor and pn.Cod=pa.Cod 
		join con cn on cn.Subunitate=pn.Subunitate and cn.Tip=pn.tip and cn.Contract=pn.Contract and cn.data=pn.data and pn.Tert=cn.Tert 
		join #tmpderezervatRN t on pt.cod=t.cod and isnull(nullif(pt.detalii.value('(/row/@gestiune)[1]','varchar(20)'),''),ct.gestiune)=t.gestiune
			and T.contract = cn.numar
	outer apply (select top 1 jc.idContract as idCI
		from jurnalcontracte jc 
		inner join staricontracte sc on jc.stare=sc.stare and sc.tipContract='RN'
		where ct.idcontract=jc.idcontract and sc.inchisa=1) ci 
	outer apply (select top 1 jc.idContract as idCD
		from jurnalcontracte jc 
		inner join staricontracte sc on jc.stare=sc.stare and sc.tipContract='RN'
		where ct.idcontract=jc.idcontract and sc.stare=@stareDefinitiva) cd
	where 		
		ci.idCI is null /*Nu e intr-o stare inchsia*/
		and cd.idCD is not null /*Este intr-o stare definitiva*/
		and ct.tip='RN' and cn.Tip='FC'
	order by pc.cod

	alter table #necesar add rezervatdeja float,sumacantitate float,derezervat float,idLinie int identity
	
	update n set rezervatdeja=pd.rezervat
		from #necesar n
		inner join 
			(select n2.idpozcontract,sum(pd.cantitate) as rezervat
			from #necesar n2
			inner join LegaturiContracte lc on n2.idpozContract=lc.idpozcontract
			inner join pozdoc pd on lc.idpozdoc=pd.idpozdoc
		-- orice legatura cu PozDoc (TE=rezervare, AP= factura, AC ...)
			group by n2.idpozcontract
			)pd on n.idpozContract=pd.idpozcontract

	update #necesar set sumacantitate=sc
	from #necesar 
		inner join 
			(select n1.idpozcontract,sum(isnull(n1.necesar,0)-isnull(n1.rezervatdeja,0)) 
				over (partition by n1.cod,n1.gestiune /*order by n1.idpozcontract ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW*/) as sc
			from #necesar n1)
			#neccalc on #neccalc.idPozContract=#necesar.idPozContract

	update n
		set derezervat=(case when t.receptionat>n.sumacantitate then isnull(n.necesar,0)-isnull(n.rezervatdeja,0)
							when t.receptionat-n.sumacantitate+isnull(n.necesar,0)+isnull(n.rezervatdeja,0)>0 then t.receptionat-n.sumacantitate+isnull(n.necesar,0)-isnull(n.rezervatdeja,0)
							else 0
							end)
	from #necesar n,#derezervatpecoduri t
	where n.cod=t.cod and t.gestiune=n.gestiune
		
	declare
		@xml xml, @numar varchar(20)

	select top 1 @numar = p.numar
			from  #tmpderezervatRN t
				inner join pozdoc p on p.tip='TE' and t.data=p.data and p.Gestiune=t.gestiune and p.gestiune_primitoare=@gestiuneRezervari
			where t.tiplinie='I'
	
	select @xml = 
		(select
			'TE' as tip,
			@numar as numar,
			convert(varchar(10),t.data,101) as data,
			rtrim(t.gestiune) as gestiune,
			rtrim(@gestiuneRezervari) as gestprim,
			'1' AS 'fara_luare_date','1' as 'returneaza_inserate', 
			nullif(@idplajaptrezervari,0) as 'idplaja',
			(select
				rtrim(n.cod) as cod,
				convert(decimal(15,2),n.derezervat) as cantitate,
				n.idlinie,
				'TE' as subtip,
				(select 1 _nuRezervaStoc for xml raw, type) detalii
			from #necesar n
			where n.derezervat > 0 and n.gestiune=rtrim(t.gestiune)
			for xml raw, type)
		from #tmpderezervat t
		where tiplinie='I'
		group by data,rtrim(t.gestiune)
		for xml raw, root('Date'))

	/*	Verificam sa avem date si pozitii	*/
	if @xml is not null and @xml.exist('(/Date/row/row)')=1
	begin
		  exec wScriuPozDoc '',@xml OUTPUT
	
			declare @ddoc int,@xml_proc xml

			EXEC sp_xml_preparedocument @ddoc OUTPUT, @xml
			IF OBJECT_ID('tempdb..#xmlPozitiiReturnate') IS NOT NULL
				DROP TABLE #xmlPozitiiReturnate
	
			SELECT
				idlinie, idPozDoc
			INTO #xmlPozitiiReturnate
			FROM OPENXML(@ddoc, '/row/docInserate/row')
			WITH
			(
				idLinie int '@idlinie',
				idPozDoc	int '@idPozDoc'

			)
			EXEC sp_xml_removedocument @ddoc 
		
			create table #Legaturi (a bit)
			exec CreazaDiezLegaturi

			insert into #Legaturi (idPozContract, idPozDoc)
			select
				it.idPozContract, pr.idPozDoc
			from #necesar it
			JOIN #xmlPozitiiReturnate pr on pr.idlinie=it.idLinie
	
			set @xml_proc= (select 'Generare rezervare' explicatii,@stareDefinitiva as stare for xml raw)
			exec wOPTrateazaLegaturiSiStariContracte @sesiune='', @parXML=@xml_proc	
	end
	/*
		Dupa scrierea rezervarilor, se mai actualizeaza odata tabela cu necesar.
		Daca este rezervat totul inseamna ca se trece comanda intr-o noua stare - De Pregatit...
	*/

		update n set rezervatdeja=pd.rezervat
		from #necesar n
		inner join 
			(select n2.idpozcontract,sum(pd.cantitate) as rezervat
			from #necesar n2
			inner join LegaturiContracte lc on n2.idpozContract=lc.idpozcontract
			inner join pozdoc pd on lc.idpozdoc=pd.idpozdoc
			where pd.tip='TE' and pd.Gestiune=n2.gestiune and pd.Gestiune_primitoare=@gestiuneRezervari
			group by n2.idpozcontract
			)pd on n.idpozContract=pd.idpozcontract

	/*Gasim contractele in intregime, nu doar cele la care s-a schimbat stocul*/
	select distinct pc.idcontract
		into #ContracteDeVerificat
		from #necesar n
		inner join pozcontracte pc on pc.idpozcontract=n.idpozcontract
		
		truncate table #necesar
		
		insert into #necesar(idpozcontract,cod,necesar,gestiune)
		select pc.idpozcontract,pc.cod,pc.cantitate as necesar,isnull(nullif(pc.detalii.value('(/row/@gestiune)[1]','varchar(20)'),''),c1.gestiune) as gestiune
		from pozcontracte pc
		inner join #ContracteDeVerificat c on c.idContract=pc.idContract
		inner join Contracte c1 on c1.idContract=c.idContract

		update n set rezervatdeja=pd.rezervat
		from #necesar n
		inner join 
			(select n2.idpozcontract,sum(pd.cantitate) as rezervat
			from #necesar n2
			inner join LegaturiContracte lc on n2.idpozContract=lc.idpozcontract
			inner join pozdoc pd on lc.idpozdoc=pd.idpozdoc
			where pd.tip='TE' and pd.Gestiune=n2.gestiune and pd.Gestiune_primitoare=@gestiuneRezervari
			group by n2.idpozcontract
			)pd on n.idpozContract=pd.idpozcontract
		
	delete cv
	from #necesar n 
	inner join PozContracte pc on n.idPozContract=pc.idPozContract
	inner join #ContracteDeVerificat cv on cv.idContract=pc.idContract
	where abs(n.necesar-isnull(rezervatdeja,0))>0.01

	/*Le trecem in starea de In Pregatire*/
	if (select count(*) from #contractedeverificat)>0
	begin
		declare @starePicking varchar(2),@docJurnal xml
		select @starePicking=max(stare) from staricontracte where tipcontract='CL' and transportabil=1
		SELECT @docJurnal = (
			SELECT idContract idContract, 'La coletizare' explicatii, @starePicking stare,GETDATE() data 
				from #contractedeverificat 
				outer apply (select top 1 idJurnal from JurnalContracte jc where jc.idContract=#ContracteDeVerificat.idContract and stare=@starePicking order by idJurnal desc) uj
				where uj.idJurnal is null
				FOR XML raw,root('Date'))
		EXEC wScriuJurnalContracte @sesiune = '', @parXML = @docJurnal OUTPUT
	end
end try
begin catch
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch	
GO
declare @amRezervari int
set @amRezervari=0
select @amRezervari=val_logica from par where tip_parametru='GE' and parametru='REZSTOCBK'
if @amRezervari=0 and EXISTS (
		SELECT *
		FROM sysobjects
		WHERE NAME = 'RezervaLaIntrareInStocSP'
		)
	DROP PROCEDURE RezervaLaIntrareInStocSP 
