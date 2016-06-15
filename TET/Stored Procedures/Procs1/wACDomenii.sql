/** procedura pt. auto-complete domenii de activitate **/
--***
Create procedure wACDomenii @sesiune varchar(50), @parXML xml
AS
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wACDomeniiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wACDomeniiSP @sesiune, @parXML output
	return @returnValue
end

declare @searchText varchar(80), @tip varchar(2), @utilizator char(10), @mesaj varchar(200)
begin try  
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') 	

	set @searchText=REPLACE(@searchText, ' ', '%')

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1

	select c.ID_domeniu as cod, rtrim(c.Denumire) as denumire, RTRIM(c.Descriere) as info
	from RU_domenii c
	where (c.ID_domeniu like @searchText + '%' or c.Denumire like '%' + @searchText + '%' or c.Descriere like '%' + @searchText + '%')
	order by c.ID_domeniu
	for xml raw
end try

begin catch
	set @mesaj = '(wACDomenii) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)