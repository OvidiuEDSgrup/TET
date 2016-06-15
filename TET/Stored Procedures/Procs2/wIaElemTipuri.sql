--***
create procedure wIaElemTipuri @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wIaElemTipuriSP' and type='P')      
	exec wIaElemTipuriSP @sesiune,@parXML      
else      
begin
declare	@tipMasina varchar(20), @searchtext varchar(30)

select 
	@tipMasina=ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''),
    @searchtext = rtrim(isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(30)'), ''))

set @searchtext='%'+REPLACE(@searchtext,' ','%')+'%'

select top 100
rtrim(em.Tip_masina) as tipMasina, 
rtrim(em.Element) as element, 
rtrim(e.Denumire) as denumire, 
convert(decimal(12,2),valoare) as valoare, 
(case	when e.UM2 = 'D' then 'Data'
		else 'Activitate' end) as tipInterval,
(case	
		when isnull(e.UM2,'')='D' then 'Luni'
		when tm.Tip_activitate='L' and isnull(e.UM2,'')<>'D' then 'Ore'
		when tm.Tip_activitate='P' and isnull(e.UM2,'')<>'D' then 'Km'
		else '?' end) um,
rtrim(em.formula) as parinte, rtrim(p.Denumire) as denparinte
from elemtipm em
		inner join tipmasini tm on tm.Cod=em.Tip_masina
		inner join elemente e on e.Cod=em.Element
		left join elemente p on p.cod=em.Formula
where tm.Cod=@tipMasina 
	  and (@tipMasina='' or tm.Cod like '%'+@tipMasina+'%')
	  and  e.Tip='I'	 
      
order by em.Tip_masina
for xml raw

end
