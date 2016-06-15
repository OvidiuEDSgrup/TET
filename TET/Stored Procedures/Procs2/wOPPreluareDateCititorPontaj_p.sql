
CREATE procedure wOPPreluareDateCititorPontaj_p @sesiune varchar(50), @parXML xml
as
declare @data datetime
set @data = @parXML.value('(/*/@data)[1]', 'datetime')

select convert(char(10),dbo.BOM(@data),101) as datainceput, convert(char(10),@data,101) as datasfarsit, '' as marca
for xml raw
