--***
Create procedure wScriuCuantumDiurne @sesiune varchar(50), @parXML xml
as 

Declare @iDoc int, @userASiS varchar(20), @referinta int, @tabReferinta int, @eroare xml, @mesaj varchar(254), @mesajEroare varchar(254), 
	@multiFirma int, @LMFiltru varchar(9)

EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT 

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlcdiurne') IS NOT NULL drop table #xmlcdiurne
if exists (select * from sysobjects where name ='par' and xtype='V')
	select @LMFiltru=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS

begin try  
	select isnull(ptupdate, 0) as ptupdate, idPozitie, marca, data_inceput, tara, valuta, diurna, diurnaneimp, detalii
	into #xmlcdiurne
	from OPENXML(@iDoc, '/row')
	WITH
	(
		detalii xml 'detalii/row',
		ptupdate int '@update', 
		idPozitie int '@idPozitie',
		marca varchar(6) '@marca',
		data_inceput datetime '@datainceput',
		tara varchar(20) '@tara',
		valuta varchar(3) '@valuta',
		diurna float '@diurna',
		diurnaneimp float '@diurnaneimp'
	)
	exec sp_xml_removedocument @iDoc 

	if exists (select 1 from #xmlcdiurne where isnull(marca, '')<>'') 
		and not exists (select 1 from #xmlcdiurne x inner join personal p on p.marca=x.marca)
		raiserror('Marca inexistenta!', 16, 1)
	if exists (select 1 from #xmlcdiurne where isnull(tara, '')='')
		raiserror('Tara necompletata!', 16, 1)
	if exists (select 1 from #xmlcdiurne where isnull(valuta, '')='')
		raiserror('Valuta necompletata!', 16, 1)

	insert into CuantumDiurne (loc_de_munca, marca, data_inceput, tara, valuta, diurna, diurna_neimpozabila, detalii)
	select @LMFiltru, x.marca, x.data_inceput, x.tara, x.valuta, diurna, diurnaneimp, detalii
	from #xmlcdiurne x
	where x.ptupdate=0

	update cd
		set cd.Marca=isnull(x.marca, cd.marca), cd.data_inceput=isnull(x.data_inceput,cd.data_inceput), 
			cd.tara=isnull(x.tara,cd.tara), cd.valuta=isnull(x.valuta,cd.valuta), 
			cd.diurna=isnull(x.diurna,cd.diurna), cd.diurna_neimpozabila=isnull(x.diurnaneimp,cd.diurna_neimpozabila), 
			cd.detalii=isnull(x.detalii,cd.detalii)
	from CuantumDiurne cd, #xmlcdiurne x
	where x.ptupdate=1 and cd.idPozitie=x.idPozitie
end try  

begin catch
	set @mesaj=ERROR_MESSAGE()+' (wScriuCuantumDiurne)'
	raiserror(@mesaj, 11, 1)
end catch
IF OBJECT_ID('tempdb..#xmlcdiurne') IS NOT NULL
	drop table #xmlcdiurne

