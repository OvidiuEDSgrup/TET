
CREATE procedure wScriuPozRectificariSalarii @sesiune varchar(50), @parXML XML
as
begin try
	declare @tip varchar(2), @subtip varchar(2), @idRectificare int, @idPozRectificare int, @marca varchar(6), @datalunii datetime, 
		@detalii xml, @update int, @docPozitii XML, @mesaj varchar(400)

	set @tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)')
	set @subtip = @parXML.value('(/*/*/@subtip)[1]', 'varchar(2)')
	set @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
	set @datalunii = dbo.eom(@parXML.value('(/*/@data)[1]', 'datetime'))
	set @idRectificare = @parXML.value('(/*/@idRectificare)[1]', 'int')
	set @idPozRectificare = @parXML.value('(/*/*/@idPozRectificare)[1]', 'int')
	set @update = isnull(@parXML.value('(/*/*/@update)[1]', 'int'),0)
	/** Validare detalii pt null **/
	if @parXML.exist('(/*/detalii)[1]') = 1
		set @detalii = @parXML.query('/*/detalii/row')

	if OBJECT_ID('tempdb..#PozRectificariSalarii') is not null drop table #PozRectificariSalarii
	if OBJECT_ID('tempdb..#AntetRectificariSalarii') is not null drop table #AntetRectificariSalarii

	create table #PozRectificariSalarii
	(
		idRectificare int,
		idPozRectificare int,
		data datetime,
		marca varchar(6),
		explicatii varchar(100),
		detalii xml,
		data_rectificata datetime,
		loc_de_munca varchar(9),
		tip_suma varchar(50),
		suma float,
		procent float,
		_update int
	)

	declare @iDoc int, @rootDoc varchar(20), @multiDoc int
	set @multiDoc=0
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	if @parXML.exist('(/Date)')=1 --Daca exista parametrul Date inseamna ca avem date multiple de introdus in tabela
	begin
		set @rootDoc='/Date/row/row'
		set @multiDoc=1
	end	
	else
		set @rootDoc='/row/row'

	insert into #PozRectificariSalarii (idPozRectificare, idRectificare, data, marca, explicatii, detalii, data_rectificata, loc_de_munca, tip_suma, suma, procent, _update)
	select idPozRectificare, idRectificare, dbo.eom(data), marca, explicatii, detalii, dbo.eom(data_rectificata), loc_de_munca, tip_suma, suma, procent, _update
	from OPENXML(@iDoc, @rootDoc)
	WITH 
	(
		idRectificare int '@idRectificare',
		marca varchar(6) '../@marca',
		data datetime '../@data',
		explicatii varchar(100) '../@explicatii',
		detalii xml '../@detalii',
		idPozRectificare int '@idPozRectificare',
		data_rectificata datetime '@datarectificata',
		loc_de_munca varchar(9) '@lm',
		tip_suma varchar(50) '@tipsuma',
		suma float '@suma',
		procent float '@procent',
		_update bit '@update'
	)

	if @update = 0 and @idRectificare is null
	begin
		if OBJECT_ID('tempdb..#inserted') is not null drop table #inserted
		if OBJECT_ID('tempdb..#tmpAntet') is not null drop table #tmpAntet
		
		create table #inserted (idRectificare int)

		select distinct data, marca, explicatii
		into #tmpAntet
		from #PozRectificariSalarii	

		insert into AntetRectificariSalarii (data, marca, explicatii, detalii)
			OUTPUT inserted.idRectificare
			INTO #inserted(idRectificare)
		select data, marca, explicatii, @detalii
		from #tmpAntet

		/** Iau ID-ul nou introdus pentru a-l scrie in PozRectificariSalarii **/
		select top 1 @idRectificare = idRectificare
		FROM #inserted

	end

--	pentru update=1
	update PozRectificariSalarii set data_rectificata=r1.data_rectificata, loc_de_munca=r1.loc_de_munca, 
		tip_suma=r1.tip_suma, suma=r1.suma, procent=r1.procent
	from PozRectificariSalarii r
		inner join #PozRectificariSalarii r1 on r.idPozRectificare=r1.idPozRectificare

--	pun in tabela temporara ultimul idRectificare pe fiecare marca, data
	select Data, Marca, idRectificare into #AntetRectificariSalarii from 
	(select Data, Marca, idRectificare, RANK() over (partition by Data, Marca order by idRectificare Desc) as ordine
	from AntetRectificariSalarii) a
	where Ordine=1
	
	insert into PozRectificariSalarii (idRectificare, data_rectificata, loc_de_munca, tip_suma, suma, procent)
	select a.idRectificare, data_rectificata, loc_de_munca, tip_suma, suma, procent
	from #PozRectificariSalarii r
		left outer join #AntetRectificariSalarii a on a.data=r.data and a.marca=r.marca
	where not exists (select 1 from PozRectificariSalarii r1 where r1.idPozRectificare=r.idPozRectificare)

--> pentru apel direct din macheta:
	if @multiDoc=0
	begin
		set @docPozitii = (select @tip as tip, @idRectificare idRectificare, @marca as marca, @datalunii data for xml raw)
		exec wIaPozRectificariSalarii @sesiune = @sesiune, @parXML = @docPozitii
	end	

end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wScriuPozRectificariSalarii)'+'(linia '+convert(varchar(20),ERROR_LINE())+') :'

	raiserror (@mesaj, 11, 1)
end catch
