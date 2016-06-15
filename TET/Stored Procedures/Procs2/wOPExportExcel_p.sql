/* procedura apelata pentru pregatirea datelor trimise la apelarea raportului 'TB/Date TB' */
create procedure wOPExportExcel_p @sesiune varchar(50), @parXML xml 
as  
declare @dataJos datetime, @dataSus datetime, @ind varchar(50)

select	
	@ind = @parXML.value('(/*/@indicator)[1]', 'varchar(50)'),
	@dataJos= convert(datetime,@parXML.value('(/*/@dataJos)[1]','varchar(10)'),103),
	@dataSus = convert(datetime,@parXML.value('(/*/@dataSus)[1]', 'varchar(10)'),103)
	
select  @ind indicator, convert(char(10),@dataJos,101) datajos, convert(char(10),@dataSus,101) datasus
for xml raw
