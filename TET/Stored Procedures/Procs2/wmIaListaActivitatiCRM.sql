
create procedure wmIaListaActivitatiCRM @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@sarcina int, @utilizator varchar(20), @adaugare xml, @lista_activitati xml,
		@modificareSarcina xml, @searchText varchar(200)

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		@sarcina = @parXML.value('(/row/@sarcina)[1]', 'int'),
		@searchText = @parXML.value('(/row/@searchText)[1]', 'varchar(200)')

	if @sarcina is null
		raiserror('Nu s-a putut identifica sarcina!', 16, 1)

	set @modificareSarcina =
	(
		SELECT
			'modificare' AS cod, 'Detalii sarcina curenta' AS denumire, '0x006600' AS culoare,
			dbo.f_wmIaForm('SRCRM') AS form, 'server://assets/Imagini/Meniu/tbconfigcat.png' as poza,
			'wmScriuSarciniCRM' AS procdetalii, 'D' AS tipdetalii
		FOR XML RAW, TYPE
	)

	set @adaugare =
	(
		select
			'adaugare' cod, 'Adauga activitate' denumire, '0x0000ff' as culoare,
			'assets/Imagini/Meniu/AdaugProdus32.png' as poza
		for xml raw, type
	)

	set @lista_activitati =
	(
		select top 100
			rtrim(tip_activitate) as cod,
			rtrim(tip_activitate) + ' - ' + convert(varchar(10), a.data, 103) as denumire, rtrim(note) as info,
			idActivitate as id, -- trimitem si id, ca sa stim daca facem update la activitate sau nu.
			rtrim(tip_activitate) as tip_activitate, rtrim(tip_activitate) as dentip_activitate,
			convert(varchar(10), a.data, 101) as data,
			rtrim(note) as note
		from ActivitatiCRM a
		inner join SarciniCRM sc on sc.idSarcina = a.idSarcina
		where a.idSarcina = @sarcina
			and (@searchText is null or a.note like '%' + @searchText + '%')
		for xml raw, type
	)

	select 'wmScriuActivitatiCRM' as detalii, 0 as areSearch, 'D' as tipdetalii, 'Activitate' as titlu,
		dbo.f_wmIaForm('ACT') as form, 1 AS _toateAtr
	for xml raw, root('Mesaje')

	select @adaugare, @lista_activitati, @modificareSarcina
	for xml path('Date'), type

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 11, 1)
end catch
