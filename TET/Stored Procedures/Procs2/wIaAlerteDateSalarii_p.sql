--***
Create procedure wIaAlerteDateSalarii_p @sesiune varchar(50), @parXML xml
as

declare @dataJos datetime, @dataSus datetime, @tipalerta varchar(100), @zileref int, @inchidereLuna int, 
	@userASiS varchar(20), @parXMLVerif xml, @rezultat xml

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @datajos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'), '')
set @datasus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'), '1901-01-01')
set @tipalerta = ISNULL(@parXML.value('(/row/@tipalerta)[1]', 'varchar(100)'), '')
set @zileref = ISNULL(@parXML.value('(/row/@zileref)[1]', 'int'), 30)
set @inchidereLuna = isnull(@parXML.value('(/*/@inchidereluna)[1]', 'int'),0)

begin try  

	set @parXMLVerif=(select convert(char(10),@datajos,101) datajos, convert(char(10),@datasus,101) datasus, 
		(case when @tipalerta='T' then '' else @tipalerta end) as tipalerta, @zileref as zileref, @inchidereLuna as inchidereluna for xml raw)
	
	exec wIaAlerteDateSalarii @sesiune, @parXMLVerif, @rezultat output

	SELECT convert(char(10),@dataJos,101) AS datajos, convert(char(10),@datasus,101) AS datasus, @tipalerta AS tipalerta, 
		(case when @tipalerta='T' then 'Toate' 
			when @tipalerta='S' then 'Incetare suspendare contract' 
			when @tipalerta='C' then 'Incetare contract pe per. determinata' end) as dentipalerta
	FOR XML RAW, ROOT('Date')

	if @rezultat is null and @inchidereLuna=1
		select 1 as inchideFereastra for xml raw,root('Mesaje')	
	else 
		SELECT (SELECT @rezultat)  
			FOR XML PATH('DateGrid'), ROOT('Mesaje')
	
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wIaAlerteDateSalarii_p) '+ERROR_MESSAGE()
	select 1 as inchideFereastra for xml raw,root('Mesaje')	
	raiserror(@eroare, 16, 1) 
end catch
