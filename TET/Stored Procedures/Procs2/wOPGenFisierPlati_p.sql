create procedure wOPGenFisierPlati_p @sesiune varchar(50), @parXML xml  
as   
declare @nrdoc varchar(20), @datascad datetime, @numar_p varchar(50), @path varchar(max)

 select @nrdoc=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@datascad=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '')

--select @numar_p=rtrim(numar_document) from generareplati gp where Numar_document=@nrdoc and Data=convert(varchar(20),@datascad,101)
select @path=RTRIM(val_alfanumerica) from par where Tip_parametru='AR' and Parametru='FISPLATI'
select @nrdoc+' - '+convert(varchar(20),@datascad,103) as numar_p, @path as path, 1 as sterginvalid
for xml raw