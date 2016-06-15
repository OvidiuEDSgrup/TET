
CREATE procedure wOPScriuPontajZilnic @sesiune varchar(50), @parXML XML
as
begin try
	declare @subtip varchar(2), @idJurnalPE int, @idPontajElectronic int, @marca varchar(6), @datalunii datetime, @update int, @tipmiscare varchar(100), @datapontaj datetime, 
		@identifpoza varchar(1000), @operatie varchar(100), @mesaj varchar(400), @detalii xml

	set @subtip = @parXML.value('(/*/*/@subtip)[1]', 'varchar(2)')
	set @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
	set @datalunii = @parXML.value('(/*/@data)[1]', 'datetime')
	set @tipmiscare = @parXML.value('(/*/@tipmiscare)[1]', 'varchar(100)')
	set @identifpoza = @parXML.value('(/*/@identifpoza)[1]', 'varchar(1000)')
	set @update = isnull(@parXML.value('(/*/*/@update)[1]', 'int'),0)
	set @datapontaj=getdate()

	if @tipmiscare='E'
		select top 1 @idPontajElectronic=idPontajElectronic, @detalii=detalii 
		from PontajElectronic where Marca=@marca and nullif(Data_ora_iesire,'01/01/1901') is null order by data_ora_intrare desc

	if @idPontajElectronic is null and @tipmiscare='E'
		raiserror('Nu exista intrare in unitate pentru acest salariat!',11,1)	

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML


	if @update=0
		set @operatie='Adaugare'
	else
		set @operatie='Modificare'

	set @parXML.modify ('insert attribute operatie {sql:variable("@operatie")} into (/row/row)[1]')

	if @update=0 or @update=1
	Begin
		exec wScriuJurnalPontajElectronic @sesiune=@sesiune, @parXML=@parXML output
		set @idJurnalPE = @parXML.value('(/*/@idJurnalPE)[1]', 'int')
	End

	update PontajElectronic set data_ora_iesire=getdate(), idJurnalPE=(case when @idJurnalPE is null then p.idJurnalPE else @idJurnalPE end), 
		detalii.modify ('insert (attribute pozaiesire {sql:variable("@identifpoza")}) into (/row)[1]')
	from PontajElectronic p
	where idPontajElectronic=@idPontajElectronic and @idPontajElectronic is not null and @tipmiscare='E'

	if @idPontajElectronic is null and @tipmiscare='I'
		insert into PontajElectronic (Marca, data_ora_intrare, data_ora_iesire, idJurnalPE, detalii)
		select @marca, getdate(), null, @idJurnalPE, (select @identifpoza as pozaintrare for xml raw)

	DECLARE @dateInitializare XML

	SELECT 'Introducere date - salariat' nume, 'PZCAM' codmeniu, 'D' tipmacheta, 'PZ' tip, 'PM' subtip,'O' fel,
		(SELECT @dateInitializare ) dateInitializare
	FOR XML RAW('deschideMacheta'), ROOT('Mesaje')


end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wOPScriuPontajZilnic)'+'(linia '+convert(varchar(20),ERROR_LINE())+') :'

	raiserror (@mesaj, 11, 1)
end catch
