create procedure wRUOPCompletareDateDiploma_p @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUOPCompletareDateDiploma_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wRUOPCompletareDateDiploma_pSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @id_instruire int, @id_poz_instruire int, @id_pers int, @seriediploma varchar(10), @nrdiploma varchar(20), @elibdiploma varchar(100)

	select @id_instruire=@parXML.value('(/row/@id_instruire)[1]','int'),
		@id_poz_instruire=isnull(@parXML.value('(/row/row/@id_poz_instruire)[1]','int'),0),
		@id_pers=isnull(@parXML.value('(/row/row/@id_pers)[1]','int'),0),
		@seriediploma=isnull(@parXML.value('(/row/row/@seriediploma)[1]','varchar(10)'),0),
		@nrdiploma=isnull(@parXML.value('(/row/row/@nrdiploma)[1]','varchar(20)'),0),
		@elibdiploma=isnull(@parXML.value('(/row/row/@elibdiploma)[1]','varchar(100)'),0)

	if @id_poz_instruire=0 or @id_pers=0
	begin
		select 'wRUOPCompletareDateDiploma_p: Operatia de completare date diploma valabila pentru pozitiile instruirii!, selectati o persoana pentru completarea acestor date!' as textMesaj for xml raw, root('Mesaje')
		return -1
	end  

	select @seriediploma seriediploma, @nrdiploma nrdiploma, @elibdiploma elibdiploma
	for xml raw
end try 

begin catch
	declare @error varchar(500)
	set @error=ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch