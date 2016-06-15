--***
Create procedure wIaVerificareDLSalarii_p @sesiune varchar(50), @parXML xml
as

declare @dataJos datetime, @dataSus datetime, @tipvalidare varchar(100), @userASiS varchar(20), @parXMLVerif xml, @rezultat xml

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @datajos = ISNULL(@parXML.value('(/row/@datajos)[1]', 'datetime'), '')
set @datasus = ISNULL(@parXML.value('(/row/@datasus)[1]', 'datetime'), '1901-01-01')
set @tipvalidare = ISNULL(@parXML.value('(/row/@tipvalidare)[1]', 'varchar(100)'), '')

begin try  

	set @parXMLVerif=(select convert(char(10),@datajos,101) datajos, convert(char(10),@datasus,101) datasus, (case when @tipvalidare='TV' then '' else @tipvalidare end) as tipvalidare for xml raw)

	exec wIaVerificareDLSalarii @sesiune, @parXMLVerif, @rezultat output

	SELECT convert(char(10),@dataJos,101) AS datajos, convert(char(10),@datasus,101) AS datasus, @tipvalidare AS tipvalidare, 
		(case when @tipvalidare='TV' then 'Toate' 
			when @tipvalidare='CE' then 'Coduri eronate' when @tipvalidare='SI' then 'Date eronate pt. salariati inactivi' 
			when @tipvalidare='RV' then 'Date revisal' when @tipvalidare='DP' then 'Date personal de modificat' 
			when @tipvalidare='NP' then 'Necorelatie pontaj-concedii' when @tipvalidare='SN' then 'Salariati nepontati' 
			when @tipvalidare='PE' then 'Pontati eronat'end) as dentipvalidare
	FOR XML RAW, ROOT('Date')

	if @rezultat is null 
		select 1 as inchideFereastra for xml raw,root('Mesaje')	
	else 
		SELECT (SELECT @rezultat)  
		FOR XML PATH('DateGrid'), ROOT('Mesaje')

end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wIaVerificareDLSalarii_p) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
