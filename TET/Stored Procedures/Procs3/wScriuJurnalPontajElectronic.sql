
Create procedure wScriuJurnalPontajElectronic @sesiune varchar(50), @parXML XML output
as
declare @idJurnalPE int, @operatie VARCHAR(1000), @explicatii VARCHAR(2000), @utilizator VARCHAR(100), @mesaj VARCHAR(400)

begin try
	set @explicatii = @parXML.value('(/*/@explicatii)[1]', 'varchar(2000)')
	set @operatie = @parXML.value('(/*/*/*/@operatie)[1]', 'varchar(1000)')
	if @operatie is null
		set @operatie = @parXML.value('(/*/*/@operatie)[1]', 'varchar(1000)')
		
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	/** Daca nu se transmite operatia, se va jurnaliza ca "modificare" */
	IF @operatie IS NULL
		set @operatie = 'Modificare'

	if OBJECT_ID('tempdb..#idJurnalPE') is not null drop table #idJurnalPE
	create table #idJurnalPE (idJurnalPE int)

	insert into JurnalPontajElectronic (operatie, data, utilizator, explicatii)
	OUTPUT inserted.idJurnalPE
	into #idJurnalPE
	select @operatie, GETDATE(), @utilizator, @explicatii
	
	select top 1 @idJurnalPE = idJurnalPE FROM #idJurnalPE
	set @parXML.modify ('insert attribute idJurnalPE {sql:variable("@idJurnalPE")} into (/*)[1]')
end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wScriuJurnalPontajElectronic)'

	raiserror (@mesaj, 11, 1)
end catch
