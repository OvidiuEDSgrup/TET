
create proc wStergProprietatiNomencl @sesiune varchar(250), @parXML xml
as
BEGIN TRY
	declare 
		@cod varchar(20), @cod_prop varchar(20), @valoare varchar(20)

	select 
		@cod=rtrim(@parXML.value('(/*/@cod)[1]','varchar(20)')),
		@cod_prop=rtrim(@parXML.value('(/*/*/@codproprietate)[1]','varchar(20)')),
		@valoare=rtrim(@parXML.value('(/*/*/@valoare)[1]','varchar(20)'))

	delete proprietati where tip='NOMENCL' and cod=@cod and cod_proprietate=@cod_prop and valoare=@valoare
		
END TRY
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
