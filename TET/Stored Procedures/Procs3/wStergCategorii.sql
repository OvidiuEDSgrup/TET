--***
create procedure wStergCategorii @sesiune varchar(50), @parXML xml
as
begin
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	declare @cod varchar(20)
	Set @cod = @parXML.value('(/row/@codCat)[1]','varchar(20)')

	if @cod is null
	raiserror('Nu a fost trimis codul',16,1)

	delete from compcategorii where Cod_Categ=@cod
	delete from categorii where Cod_categ=@cod

	SELECT 'Categoria '+@cod+
		' a fost stearsa din baza de date.' AS textMesaj, 
		'Notificare' AS titluMesaj
	FOR XML raw, root('Mesaje')
	
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wStergCategorii '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
/*
end try
begin catch
	set @eroare = ERROR_MESSAGE()
	raiserror(@eroare, 11, 1)	
end catch
*/
