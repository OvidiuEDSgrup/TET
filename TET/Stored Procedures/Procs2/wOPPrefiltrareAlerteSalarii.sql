--***
Create procedure wOPPrefiltrareAlerteSalarii @sesiune varchar(50), @parXML xml
as

declare @luna int, @an int, @dataJos datetime, @dataSus datetime, @tipalerta varchar(100), @inchidereLuna int, @zileref int, @userASiS varchar(20)

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @luna = ISNULL(@parXML.value('(/*/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/*/@an)[1]', 'int'), '1901')
set @tipalerta = ISNULL(@parXML.value('(/*/@tipalerta)[1]', 'varchar(100)'), '')
set @zileref = isnull(@parXML.value('(/*/@zileref)[1]', 'int'),30)
set @inchidereLuna = isnull(@parXML.value('(/*/@inchidereluna)[1]', 'int'),0)

if @luna=0
	select @luna=month(getdate()), @An=year(getdate())

set @datajos = dbo.BOM(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
set @datasus = dbo.EOM(@datajos)

begin try  

	DECLARE @dateInitializare XML
	SET @dateInitializare='<row datajos="'+convert(char(10),@datajos,101)+'" datasus="'+convert(char(10),@datasus,101)
		+'" tipalerta="'+rtrim(@tipalerta)+'" zileref="'+rtrim(convert(char(4),@zileref))+'" inchidereluna="'+convert(char(1),@inchidereLuna)+'"/>'

	SELECT 'Alerte date salarii' nume, (case when exists (select 1 from webConfigMeniu where meniu='ADS') then 'ADS' else 'AS' end) codmeniu, 'D' tipmacheta, 'AS' tip, 'AS' subtip,'O' fel,
		(SELECT @dateInitializare ) dateInitializare
	FOR XML RAW('deschideMacheta'), ROOT('Mesaje')

end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='(wOPPrefiltrareAlerteSalarii) '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
