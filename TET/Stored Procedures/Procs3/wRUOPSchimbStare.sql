--***
create procedure wRUOPSchimbStare @sesiune varchar(50), @parXML xml 
as     
begin try 
	declare @tip varchar(2), @subtip varchar(2), @id_instruire int, @o_stare varchar(1), @schimbstare varchar(1)

	declare @iDoc int 
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	select @id_instruire=id_instruire, @schimbstare=stare
	from OPENXML(@iDoc, '/parametri')
	WITH 
	(
		id_instruire int './@id_instruire',
		stare varchar(1)'./@stare',
		o_stare varchar(1) './@o_stare'
	)

	if @schimbstare is null or @schimbstare=''
		raiserror ('Stare necompletata',11,1)

	update RU_instruiri set Stare=@schimbstare where ID_instruire=@id_instruire

	exec sp_xml_removedocument @iDoc 
--	select * from RU_instruiri
end try

begin catch
	declare @eroare varchar(200) 
	set @eroare='(wRUOPSchimbStare)'+ERROR_MESSAGE()
	raiserror(@eroare, 11, 1) 
end catch
