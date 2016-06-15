--***
create procedure wACDeconturi @sesiune varchar(50), @parXML XML  
as  
 if exists (select 1 from sysobjects where [type]='P' and [name]='wACDeconturiSP')
	exec wACDeconturiSP @sesiune, @parXML

declare @subunitate varchar(9), @searchText varchar(80), @tip varchar(2), @subtip varchar(2), @marca varchar(6), 
	@valuta varchar(3), @inValuta int
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
	@marca=ISNULL(@parXML.value('(/row/@marca)[1]', 'varchar(13)'), ''), 
	@valuta=ISNULL(@parXML.value('(/row/@valuta)[1]', 'varchar(3)'), '')
set @inValuta=(case when (@tip in ('PW') or @tip='RE' and @subtip in ('PW', 'IW')) and @valuta<>'' then 1 else 0 end)
set @searchText=REPLACE(@searchText, ' ', '%')

select top 100 rtrim(d.Decont) as cod,
'Ct. ' + RTRIM(d.Cont) + ', Data ' + CONVERT(varchar(10), d.data, 103) /*+ ', Scad. ' + CONVERT(varchar(10), d.data_scadentei, 103)+rtrim(d.Explicatii)*/ as denumire, 
'Sold ' + CONVERT(varchar(20), convert(money, (case when @inValuta=1 then d.sold_valuta else d.sold end)), 1) + ' ' + (case when @inValuta=1 then @valuta else 'lei' end)
	+(case when @inValuta=0 and d.Valuta<>'' then ' ('+CONVERT(varchar(20), convert(money,d.sold_valuta), 1)+' '+RTRIM(d.Valuta)+')' else '' end)
	+(case when substring(d.comanda,21,20)<>'' then ' Indbug. '+rtrim(substring(d.comanda,21,20)) else '' end) as info
from deconturi d   
where (d.Decont like @searchText+'%' or d.Explicatii like '%'+@searchText+'%')  
and (@marca='' or d.Marca =@marca)
and abs(case when @inValuta=1 then d.sold_valuta else d.sold end)>=0.01
order by rtrim(d.Decont)
for xml raw
