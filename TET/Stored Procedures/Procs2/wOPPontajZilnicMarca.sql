--***
Create procedure wOPPontajZilnicMarca @sesiune varchar(50), @parXML xml
as

declare @dataJos datetime, @dataSus datetime, @userASiS varchar(20), @marca varchar(6),@card varchar(100)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @datajos = ISNULL(@parXML.value('(/*/@datajos)[1]', 'datetime'), '')
set @datasus = ISNULL(@parXML.value('(/*/@datasus)[1]', 'datetime'), '1901-01-01')
set @marca = ISNULL(@parXML.value('(/*/@marca)[1]', 'varchar(6)'), '')
set @card= @parXML.value('(/*/@card)[1]', 'varchar(100)')

if @card is not null
	select top 1 @marca=marca from infopers where observatii=@card
begin try  

	DECLARE @dateInitializare XML
	SET @dateInitializare='<row datajos="'+convert(char(10),@datajos,101)+'" datasus="'+convert(char(10),@datasus,101)+'" marca="'+rtrim(@marca)+'"/>'

	SELECT 'Pontaj zilnic - poza' nume, 'PZCAM' codmeniu, 'D' tipmacheta, 'PZ' tip, 'PD' subtip,'O' fel,
		(SELECT @dateInitializare ) dateInitializare
	FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
	
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPPontajZilnicMarca) '+ERROR_MESSAGE()
	select 1 as inchideFereastra for xml raw,root('Mesaje')	
	raiserror(@eroare, 16, 1) 
end catch
