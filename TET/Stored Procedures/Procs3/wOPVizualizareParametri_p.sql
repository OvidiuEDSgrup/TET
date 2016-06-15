
Create procedure wOPVizualizareParametri_p @sesiune varchar(50), @parXML xml
as

declare @data datetime, @ora varchar(10), @utilizator varchar(100), @paramXML varchar(max)

set @data = @parXML.value('(/*/@data)[1]','datetime')
set @ora = @parXML.value('(/*/@ora)[1]','varchar(10)')
set @utilizator = @parXML.value('(/*/@utilizator)[1]','varchar(100)')

set @paramXML = convert(varchar(max),
				(
					select top 1 parametruXML
					from webJurnalOperatii 
					where convert(varchar(20),data,101) = convert(varchar(10),@data,101)
						and convert(varchar(20),data,108) = @ora
						and utilizator = @utilizator
				))

select @paramXML as paramXML
for xml raw, root('Date')
