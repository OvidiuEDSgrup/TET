--***
Create procedure wOPPrefiltrareVerificariDLSalarii_p @sesiune varchar(50), @parXML xml
as

declare @data datetime, @dataJos datetime, @dataSus datetime, @tipvalidare varchar(100), @userASiS varchar(20), @parXMLVerif xml, @rezultat xml

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @datajos = @parXML.value('(/row/@datajos)[1]', 'datetime')
set @datasus = @parXML.value('(/row/@datasus)[1]', 'datetime')
set @data = ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '1901-01-01')
if @dataJos is null
	select @datajos=dbo.bom(@data), @datasus=dbo.eom(@data)

begin try  
	
	SELECT convert(char(10),@dataJos,101) AS datajos, convert(char(10),@datasus,101) AS datasus, null AS tipvalidare
	FOR XML RAW

end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPPrefiltrareVerificariDLSalarii_p) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
