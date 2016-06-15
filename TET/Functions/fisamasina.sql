--***
create function dbo.fisamasina (@pDataJos datetime, @pDataSus datetime, @pMasina char(20), @pTipInt char(1), @pElement char(20))
returns @fisamasina table
(masina char(20), nr_inmatriculare char(20), element char(20), denumire_elem char(60), 
 tip char(1), fisa char(20), data datetime, km float, km_bord float)
as begin 

declare @dDataImpl datetime,@nAnImpl int,@nLunaImpl int, @dDataCurenta datetime 
set @nAnImpl=(select max(val_numerica) from par where tip_parametru='MT' and parametru='ANIMPL')
set @nLunaImpl=(select max(val_numerica) from par where tip_parametru='MT' and parametru='LUNAIMPL')
set @dDataImpl=DateAdd(year,@nAnImpl-1901,'01/01/1901')
set @dDataImpl=DateAdd(month,@nLunaImpl,@dDataImpl)
set @dDataImpl=DateAdd(day,-1,@dDataImpl)
set @dDataCurenta = @pDataSus --convert(datetime, convert(char(10), getdate(), 104), 104)

insert into @fisamasina

-- interventii la implementare - contin fie data interventiei, fie numarul de kilometri
select m.cod_masina, m.nr_inmatriculare as nr_inmatric, 
e.cod as cod_element, e.denumire as den_element, 
'F' as tip_pozitie, '<IMPL>' as fisa_expl, 
(case when left(e.UM2, 1)='D' then DateAdd(day, convert(int, vei.valoare), '01/01/1901') else '01/01/1901' end) as data_int, 
(case when left(e.UM2, 1)<>'D' then vei.valoare else 0 end) as km, 0 as km_bord 
from masini m, elemente e, valelemimpl vei 
where (isnull(@pMasina, '')='' or m.cod_masina=@pMasina) and m.cod_masina=vei.masina 
and (isnull(@pElement, '')='' or e.cod=@pElement) and e.cod=vei.element and e.tip='I' 

union all 

-- interventii si planificari din activitati
select m.cod_masina, m.nr_inmatriculare, e.cod, e.denumire, 
left(a.tip,1), ea.fisa, ea.data, dbo.kmbord(m.cod_masina, ea.data, ea.fisa, ea.numar_pozitie), 0 
from masini m, elemtipm et, elemente e, elemactivitati ea, activitati a 
where (isnull(@pMasina, '')='' or m.cod_masina=@pMasina) and m.tip_masina=et.tip_masina 
 and (isnull(@pElement, '')='' or e.cod=@pElement) and et.element=e.cod and e.tip='I' 
 and m.cod_masina=a.masina and a.tip=ea.tip and a.fisa=ea.fisa and a.data=ea.data 
 and e.cod=ea.element and substring(a.tip,2,1)='I' 

union all 

-- urmatoarea interventie pt. fiecare masina si element de tip I 
select m.cod_masina, m.nr_inmatriculare, e.cod, e.denumire, 
'R', '<RECOMANDARE>', 
'01/01/1901', 0, dbo.kmbord(m.cod_masina, @dDataCurenta, '', -1) 
from masini m, elemtipm et, elemente e 
where (isnull(@pMasina, '')='' or m.cod_masina=@pMasina) and m.tip_masina=et.tip_masina 
and (isnull(@pElement, '')='' or e.cod=@pElement) and et.element=e.cod and e.tip='I' 
order by nr_inmatric, den_element, cod_element, data_int 

declare @cCodMasina char(20), @cElement char(20)
declare tmpint cursor for select distinct masina, element from @fisamasina where tip='R' 
open tmpint
fetch next from tmpint into @cCodMasina, @cElement
while @@fetch_status = 0 
begin
 update @fisamasina
 set data=(case when left(e.UM2, 1)='D' then DateAdd(month, convert(int, c.interval), isnull(i.data, @dDataImpl)) else f.data end), 
 km=(case when left(e.UM2, 1)<>'D' then isnull(i.km, dbo.kmbord(@cCodMasina, @dDataImpl, '', -1)) + c.interval else f.km end) 
 from @fisamasina f 
 inner join elemente e on e.cod=f.element 
 inner join masini m on m.cod_masina=f.masina
 inner join coefmasini c on c.masina=f.masina and c.coeficient=f.element 
 left outer join  
 (select top 1 masina, element, data, km from @fisamasina where masina=@cCodMasina and element=@cElement and tip='I' order by data desc, fisa desc, km desc) i 
 on m.cod_masina=i.masina and e.cod=i.element
 where f.masina=@cCodMasina and f.element=@cElement and f.tip='R' 
  
 
 fetch next from tmpint into @cCodMasina, @cElement
end
close tmpint
deallocate tmpint

update @fisamasina
set data=@dDataCurenta
where tip='R' and (data<>'01/01/1901' and data<@dDataCurenta or data='01/01/1901' and km<km_bord)

update @fisamasina
set data=DateAdd(day, convert(int, round((km-km_bord)/((km_bord-dbo.kmbord(masina,@dDataImpl,'',-1))/DateDiff(day,@dDataImpl,@dDataCurenta)), 0)), @dDataCurenta)
where tip='R' and data='01/01/1901' and km>km_bord and abs(km_bord-dbo.kmbord(masina,@dDataImpl,'',-1))>=0.01

update @fisamasina
set km=km_bord + DateDiff(day, @dDataCurenta, data) * ((km_bord-dbo.kmbord(masina,@dDataImpl,'',-1))/DateDiff(day,@dDataImpl,@dDataCurenta))
where tip='R' and km=0 and data<>'01/01/1901' 

delete @fisamasina 
where not (data between @pDataJos and @pDataSus and (isnull(@pTipInt, '')='' or tip=@pTipInt)) 

return 
end 
