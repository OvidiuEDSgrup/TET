--***
create procedure wmScriuActivitatiCRM @sesiune varchar(50), @parXML xml
as
begin try
	declare
		@tipActivitate varchar(100), @data datetime, @descriere varchar(1000),
		@utilizator varchar(20), @tert varchar(20), @idActivitate int, @update bit,
		@xml xml, @idSarcina int, @marca varchar(20), @idPotential int

	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output

	select
		@tipActivitate = rtrim(@parXML.value('(/row/@tip_activitate)[1]', 'varchar(100)')),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@descriere = isnull(rtrim(@parXML.value('(/row/@note)[1]', 'varchar(1000)')), ''),
		@idActivitate = @parXML.value('(/row/@id)[1]', 'int'),
		@idSarcina = @parXML.value('(/row/@sarcina)[1]', 'int'),
		@marca = @parXML.value('(/row/@marca)[1]', 'varchar(20)'),
		@idPotential = @parXML.value('(/row/@tert)[1]', 'int')
	
	IF @idActivitate IS NULL
		SET @update = 0
	ELSE
		SET @update = 1
	
	SET @xml =
	(
		SELECT
			@idActivitate AS idActivitate, @idSarcina AS idSarcina, @update AS [update], @data AS data,
			@tipActivitate AS tip_activitate, @descriere AS note, @marca AS marca, 
			@idPotential AS idPotential, 1 AS fara_luare_date
		FOR XML RAW, TYPE
	)
	EXEC wScriuActivitatiCRM @sesiune = @sesiune, @parXML = @xml

	select 'back(1)' as actiune
	for xml raw,Root('Mesaje')

end try
begin catch
	declare @mesajEroare varchar(500)
	set @mesajEroare = ERROR_MESSAGE() + ' (' + OBJECT_NAME(@@PROCID) + ')'
	raiserror(@mesajEroare, 11, 1)
end catch
