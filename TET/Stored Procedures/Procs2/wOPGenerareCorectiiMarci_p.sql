--***
Create procedure wOPGenerareCorectiiMarci_p @sesiune varchar(50), @parXML xml
as

declare @data datetime, @userASiS varchar(20)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @data = ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '1901-01-01')

begin try  
	
	SELECT convert(char(10),@data,101) AS datacor
	FOR XML RAW

end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPGenerareCorectiiMarci_p) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
