/** procedura de scriere a configurarilor pentru nota contabila de salarii (specific bugetari) **/
Create procedure wScriuConfigNCSalariiBugetari @sesiune varchar(30), @parXML XML
as
declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlcfg') IS NOT NULL
	drop table #xmlcfg

begin try
	select isnull(ptupdate, 0) as ptupdate, nullif(ltrim(rtrim(lm)),'') lm, nullif(isnull(lm_vechi, lm),'') as lm_vechi, 
		isnull(nrpozitie,0) as nrpozitie, isnull(o_nrpozitie,0) as o_nrpozitie, isnull(ltrim(rtrim(denumire)),'') denumire, 
		isnull(ltrim(rtrim(contdebitor)),'') contdebitor, isnull(ltrim(rtrim(contcreditor)),'') contcreditor, 
		isnull(analitic,0) as analitic, isnull(comanda,'') as comanda, isnull(expresie,'') as expresie, identificator, 
		nullif(contcas,'') as contcas, nullif(contcass,'') as contcass, nullif(contsomaj,'') as contsomaj, nullif(contimpozit,'') as contimpozit
	into #xmlcfg
	from OPENXML(@iDoc, '/row')
	WITH
	(
		ptupdate int '@update', 
		lm varchar(9) '@lm', 
		lm_vechi varchar(9) '@o_lm', 
		nrpozitie int '@nrpozitie', 
		o_nrpozitie int '@o_nrpozitie', 
		denumire varchar(50) '@denumire', 
		contdebitor varchar(20) '@contdebitor', 
		contcreditor varchar(20) '@contcreditor', 
		comanda varchar(20) '@comanda', 
		analitic int '@analitic', 
		expresie varchar(500) '@expresie', 
		identificator varchar(50) '@identificator',
		contcas varchar(20) '@contcas', 
		contcass varchar(20) '@contcass', 
		contsomaj varchar(20) '@contsomaj', 
		contimpozit varchar(20) '@contimpozit'
	)
	exec sp_xml_removedocument @iDoc 

	update #xmlcfg set nrpozitie=(case when o_nrpozitie<>0 then o_nrpozitie else nrpozitie end)

	if exists (select 1 from #xmlcfg where nrpozitie=0)
		raiserror('Nu se pot adauga pozitii. Se pot doar modifica!',16,1)

	if exists (select 1 from #xmlcfg where nrpozitie>70 and (nullif(contcas,'') is not null or nullif(contcass,'') is not null or nullif(contsomaj,'') is not null or nullif(contimpozit,'') is not null))
		raiserror('Conturile creditoare pentru contributiile individuale se completeaza doar pentru sumele reprezentand componente ale venitului brut (numar pozitie <=70)!',16,1)

	update c 
		set Denumire=isnull(x.denumire,c.denumire), Cont_debitor=isnull(x.contdebitor,c.Cont_debitor), Cont_creditor=isnull(x.contcreditor,c.Cont_creditor), 
			Comanda=isnull(x.comanda,c.Comanda), Analitic=isnull(x.analitic,c.Analitic), Expresie=isnull(x.expresie,c.Expresie), 
			Identificator=isnull(x.identificator,c.Identificator),  
			Cont_cas=isnull(x.contcas,c.Cont_CAS), Cont_CASS=isnull(x.contcass,c.Cont_CASS), Cont_somaj=isnull(x.contsomaj,c.Cont_somaj), Cont_impozit=isnull(x.contimpozit,c.Cont_impozit)
	from config_nc c, #xmlcfg x
	where x.ptupdate=1 and c.Numar_pozitie=x.nrpozitie and (c.Loc_de_munca is null and x.lm is null or c.loc_de_munca=x.lm)

	insert into config_nc (Loc_de_munca, Numar_pozitie, Denumire, Cont_debitor, Cont_creditor, Comanda, Analitic, Expresie, 
		Identificator, Cont_CAS, Cont_CASS, Cont_somaj, Cont_impozit)  
	select lm, nrpozitie, denumire, contdebitor, contcreditor, comanda, analitic, expresie, 
		identificator, contcas, contcass, contsomaj, contimpozit
	from #xmlcfg x
	where x.ptupdate=0
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()+ ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 11, 1)	
end catch
