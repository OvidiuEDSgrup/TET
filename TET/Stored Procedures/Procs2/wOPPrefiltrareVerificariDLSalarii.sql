--***
Create procedure wOPPrefiltrareVerificariDLSalarii @sesiune varchar(50), @parXML xml
as

declare @dataJos datetime, @dataSus datetime, @tipvalidare varchar(100), @userASiS varchar(20)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @datajos = ISNULL(@parXML.value('(/*/@datajos)[1]', 'datetime'), '')
set @datasus = ISNULL(@parXML.value('(/*/@datasus)[1]', 'datetime'), '1901-01-01')
set @tipvalidare = ISNULL(@parXML.value('(/*/@tipvalidare)[1]', 'varchar(100)'), '')

begin try  

	DECLARE @dateInitializare XML
	SET @dateInitializare='<row datajos="'+convert(char(10),@datajos,101)+'" datasus="'+convert(char(10),@datasus,101)+'" tipvalidare="'+rtrim(@tipvalidare)+'"/>'
	
	SELECT 'Validari date salarii' nume, 'VA' codmeniu, 'D' tipmacheta, 'DS' tip, 'VS' subtip,'O' fel,
		(SELECT @dateInitializare ) dateInitializare
	FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPPrefiltrareVerificariDLSalarii) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
