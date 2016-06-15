--***
Create procedure wDeclaratia300 @sesiune varchar(50), @parXML xml
as

declare @datajos datetime, @datasus datetime, @lunaalfa varchar(15), @luna int, @an int, --@dataj datetime, @datas datetime, 
	@userASiS varchar(10)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @datajos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'), '')
set @datasus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'), 0)

begin try  
	select distinct convert(char(10),Data_lunii,101) as data, rtrim(LunaAlfa) as numeluna, Luna as luna, convert(char(4),an) as an, data as data_ord
	from fCalendar(@datajos,@datasus)
	where data=Data_lunii
	order by data_ord desc
	for XML raw
end try  

begin catch
	declare @eroare varchar(254)
	set @eroare='Procedura wDeclaratia300 (linia '+convert(varchar(20),ERROR_LINE())+'): '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1)
end catch
