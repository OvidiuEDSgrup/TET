--***
Create procedure wIaResal @sesiune varchar(50), @parXML xml
as  
declare @userASiS varchar(10), @iDoc int, @tip varchar(2), @subtip varchar(2), @codbenef varchar(13), @data datetime, 
@dataj datetime, @datas datetime
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

select @data=xA.row.value('@data', 'datetime'), @tip=xA.row.value('@tip', 'varchar(2)'), @subtip=xA.row.value('@subtip', 'varchar(2)'),
@codbenef=xA.row.value('@codbenef','varchar(13)')
from @parXML.nodes('row') as xA(row) 
set @dataj=dbo.bom(@data)
set @datas=dbo.eom(@data)

select 
convert(char(10),r.data,101) as data, r.marca as marca, i.nume as densalariat, 
@tip as tip, (case when @tip='SL' then 'R1' else 'R2' end) as subtip, 'Retinere' as denumire, 
rtrim(r.numar_document) as nrdoc, rtrim(r.cod_beneficiar) as codbenef, rtrim(br.Denumire_beneficiar) as denbenef, 
convert(decimal(12,2),r.Retinere_progr_la_lichidare) as cantitate, 
convert(decimal(12,2),r.Retinut_la_lichidare) as valoare, 
convert(decimal(12,2),r.Procent_progr_la_lichidare) as procent, 
convert(decimal(12,2),r.Valoare_totala_pe_doc) as valtotala, convert(decimal(12,2),r.Valoare_retinuta_pe_doc) as valretinuta, 
'#000000' as culoare 
from 
resal r
	left outer join benret br on r.Cod_beneficiar=br.cod_beneficiar
	left outer join istpers i on i.marca=r.marca and i.Data=r.Data, @parXML.nodes('row') as xA(row)
where r.data between @dataj and @datas 
	and (@tip='SL' and r.marca=xA.row.value('@marca','varchar(6)') or @tip='RE' and r.Cod_beneficiar=@codbenef) 
order by data, marca, r.cod_beneficiar
for xml raw
