/*
	--exemplu de apel
	declare @parXML xml, @detalii xml
	set @parXML=(select '_test' as atribut, 'merge ok' as valoare for xml raw)
	exec ActualizareInXml @parXML=@parXML, @detalii=@detalii output
	select @detalii
*/
Create procedure ActualizareInXml @parXML XML, @detalii XML output
AS
DECLARE @atribut varchar(1000), @valoare varchar(3000), @comanda NVARCHAR(max), @eroare VARCHAR(500)
select	@atribut = @parXML.value('(/*/@atribut)[1]', 'varchar(1000)'),
		@valoare = @parXML.value('(/*/@valoare)[1]', 'varchar(3000)')

BEGIN TRY

--	initializez detalii cu <row />
	if @detalii is null or convert(varchar(max),@detalii)=''
		set @detalii='<row />'

--	inlocuiesc valoarea, daca exista atributul
	set @comanda='if @detalii.value('''+'(/row/@'+@atribut+')[1]'',''varchar(1000)'') is not null
		set @detalii.modify('''+'replace value of (/row/@'+@atribut+')[1] with sql:variable("@valoare")'''+')'
	
	exec sp_executesql @statement=@comanda, @params=N'@detalii xml output, @valoare varchar(1000)', @detalii=@detalii output, @valoare=@valoare

--	inserez atribut si valoare
	set @comanda='if @detalii.value('''+'(/row/@'+@atribut+')[1]'',''varchar(1000)'') is null
		set @detalii.modify ('''+'insert attribute '+@atribut+' {sql:variable("@valoare")} into (/row)[1]'''+')'

	exec sp_executesql @statement=@comanda, @params=N'@detalii xml output, @valoare varchar(1000)', @detalii=@detalii output, @valoare=@valoare 

	RETURN

END TRY

BEGIN CATCH
	SET @eroare = ERROR_MESSAGE() + '(FormareDetalii)'
	RAISERROR (@eroare, 11, 1)
END CATCH
