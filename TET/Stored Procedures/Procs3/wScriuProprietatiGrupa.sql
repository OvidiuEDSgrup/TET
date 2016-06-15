﻿
create proc wScriuProprietatiGrupa @sesiune varchar(250), @parXML xml
as

BEGIN TRY
	declare 
		@grupa varchar(20), @cod_prop varchar(20), @update bit, @valoare varchar(20)

	select 
		@grupa=rtrim(@parXML.value('(/*/@grupa)[1]','varchar(20)')),
		@cod_prop=rtrim(@parXML.value('(/*/*/@codproprietate)[1]','varchar(20)')),
		@valoare=rtrim(@parXML.value('(/*/*/@valoare)[1]','varchar(20)')),
		@update=ISNULL(@parXML.value('(/*/*/@update)[1]','bit'),0)

	if @update=1
		update proprietati
			set valoare=@valoare
		where tip='grupa' and cod=@grupa and cod_proprietate=@cod_prop
	else

		insert into proprietati (tip, cod, cod_proprietate, valoare, valoare_tupla)
		select
			'GRUPA', @grupa, @cod_prop, @valoare, ''
		where not exists (select 1 from proprietati where tip='GRUPA' and cod=@grupa and cod_proprietate=@cod_prop and valoare=@valoare) 
		
END TRY
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
