
CREATE procedure wStergPontajElectronic @sesiune VARCHAR(50), @parXML XML
as
declare @idPontajElectronic int, @data datetime, @marca varchar(6), @subtip varchar(2),
	@mesaj varchar(500), @docPontajElectronic XML

begin try
	set @idPontajElectronic = @parXML.value('(/*/*/@idPontajElectronic)[1]', 'int')
	set @data = @parXML.value('(/*/@data)[1]', 'datetime')
	set @marca = @parXML.value('(/*/@marca)[1]', 'varchar(6)')
	set @subtip = @parXML.value('(/*/*/@subtip)[1]', 'varchar(2)')

	delete
	from PontajElectronic
	where idPontajElectronic = @idPontajElectronic and @subtip='DC'

	set @docPontajElectronic = 
			(select @data data, @marca marca for xml raw)

	exec wIaPontajElectronic @sesiune = @sesiune, @parXML = @docPontajElectronic
end try

begin catch
	set @mesaj = ERROR_MESSAGE() + ' (wStergPontajElectronic)'

	raiserror (@mesaj, 11, 1)
end catch
