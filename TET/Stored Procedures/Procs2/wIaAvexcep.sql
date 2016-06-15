--***
create procedure wIaAvexcep @sesiune varchar(50), @parXML xml
as  
declare @userASiS varchar(10), @iDoc int, @tip varchar(2), @subtip varchar(2), @grupdoc varchar(20), @data datetime, 
@lm varchar(9), @dataj datetime, @datas datetime, @lPremiu_la_avans int 
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

set @lPremiu_la_avans=dbo.iauParL('PS','PREMAVANS')
select @data=xA.row.value('@data', 'datetime'), @tip=xA.row.value('@tip', 'varchar(2)'), @subtip=xA.row.value('@subtip', 'varchar(2)'), 
@lm=xA.row.value('@lm', 'varchar(9)')
from @parXML.nodes('row') as xA(row) 

set @dataj=dbo.bom(@data)
set @datas=dbo.eom(@data)

select 
convert(char(10),a.data,101) as data, @tip as tip, (case when @tip='SL' then 'A1' else 'A2' end) as subtip, 
'Avans'+space(25) as denumire, a.marca as marca, i.nume as densalariat, 
i.Loc_de_munca as locm, rtrim(lm.Denumire) as denlm, 
'Avans' as explicatii,
convert(decimal(12,2),a.Ore_lucrate_la_avans) as oreavans, 
convert(decimal(12,2),a.Suma_avans) as sumaavans, convert(decimal(12,2),a.Premiu_la_avans) as premiuavans, 
'#000000' as culoare 
from avexcep a 
	left outer join istpers i on i.marca=a.marca and i.Data=a.Data
	left outer join lm lm on lm.Cod=i.Loc_de_munca, 
	@parXML.nodes('row') as xA(row)
where (@tip='SL' and a.marca=xA.row.value('@marca','varchar(6)') or @tip='AV' and i.loc_de_munca=@lm) 
	and a.data between @dataj and @datas
order by data, marca
for xml raw
