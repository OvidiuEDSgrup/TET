--***
create procedure wIaPozRealcom @sesiune varchar(50), @parXML xml
as  
declare @sub varchar(9), @userASiS varchar(10), @iDoc int, @tip varchar(2), @subtip varchar(2), 
@marca varchar(9), @lmantet varchar(9), @data datetime, @dataj datetime, @datas datetime
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @sub=dbo.iauParA('GE','SUBPRO')
select @tip=xA.row.value('@tip', 'varchar(2)'), @subtip=xA.row.value('@subtip', 'varchar(2)'), 
@data=xA.row.value('@data', 'datetime'), 
@marca=xA.row.value('@marca', 'varchar(6)'), @lmantet=rtrim(xA.row.value('@lmantet', 'varchar(9)'))
from @parXML.nodes('row') as xA(row) 
set @dataj=dbo.bom(@data)
set @datas=dbo.eom(@data)

if @tip='PO'
	select @tip='MN', @subtip='MN'

select 
convert(char(10),dbo.eom(r.data),101) as data, @tip as tip, @subtip as subtip, 'Realizari acord global' as denumire, 
rtrim(r.marca) as marca, isnull(rtrim(p.nume),'') as densalariat, 
rtrim(r.Numar_document) as nrdoc, convert(char(10),r.data,101) as datadoc, 
(case when r.marca<>'' and r.Categoria_salarizare<>'' then 1 else 0 end) as bonuriregie, 
rtrim(r.Loc_de_munca) as lm, isnull(rtrim(lm.Denumire),'') as denlm, rtrim(r.Comanda) as comanda, 
isnull(rtrim(c.Descriere),'') as dencomanda, 
rtrim(r.Cod_reper) as codtehn, isnull(rtrim(t.denumire),'') as dentehn, 
rtrim(r.Cod) as codoperatie, isnull(rtrim(o.denumire),'') as denoperatie, 
convert(decimal(13,6),r.Norma_de_timp) as normatimp, 
convert(decimal(10,3),r.Cantitate) as cantitate, convert(decimal(14,5),r.Tarif_unitar) as tarifunitar, 
convert(decimal(12,3),r.Cantitate*r.Tarif_unitar) as valoare, 
'#000000' as culoare 
from Realcom r 
left outer join personal p on p.marca=r.marca
left outer join lm lm on lm.Cod=r.Loc_de_munca
left outer join comenzi c on c.Subunitate=@sub and c.Comanda=r.Comanda
left outer join tehn t on t.Cod_tehn=r.Cod_reper
left outer join catop o on o.Cod=r.Cod
, @parXML.nodes('row') as xA(row)
where (@tip='SL' and r.marca=xA.row.value('@marca','varchar(6)') 
or @tip='AG' and r.loc_de_munca=@lmantet and r.Marca=''
or @tip='AI' and r.Marca=@marca and r.Marca<>'')
or @tip='MN' and r.loc_de_munca like @lmantet + '%' -- Pentru macheta de realizari manopera
and r.data between @dataj and @datas
order by datadoc, marca, comanda
for xml raw
