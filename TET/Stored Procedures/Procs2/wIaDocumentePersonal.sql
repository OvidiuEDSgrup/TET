
create procedure wIaDocumentePersonal @sesiune varchar(30), @parXML XML
as

declare @caleupload varchar(255), @marca varchar(20)

select 
	@caleUpload = rtrim(ltrim(val_alfanumerica)) + '/formulare/uploads/',
	@marca = isnull(@parXML.value('(/row/@marca)[1]','varchar(20)'),'')
from par
where Tip_parametru = 'AR' and Parametru = 'URL'

select top 100
	d.idDocument,
	d.idTipDocument,
	rtrim(t.tip) as tipdocument,
	rtrim(t.descriere) as descdoc,
	rtrim(t.descriere) as dentipdoc,
	rtrim(d.numar) as numar,
	rtrim(d.serie) as serie,
	convert(varchar(10),d.data_emiterii,101) as data_emiterii,
	convert(varchar(10),d.valabilitate,101) as valabilitate,
	rtrim(d.observatii) as observatii,
	(case when isnull(d.fisier,'')='' then '' else '<a href="' + @caleUpload + rtrim(d.fisier) + '" target="_blank" /><u> Click </u></a>' end) as fisier,
	(case	when datediff(d,convert(varchar(10),getdate(),101),convert(varchar(10),d.valabilitate,101)) > 30 then '#008000'
			when datediff(d,convert(varchar(10),getdate(),101),convert(varchar(10),d.valabilitate,101)) between 0 and 30 then '#FF0000'
	else '#808080'
	end) as culoare
from DocumentePersonal d
left join TipuriDocumentePersonal t on d.idTipDocument=t.idTipDocument
where d.marca=@marca
order by d.data_emiterii desc
for xml raw
