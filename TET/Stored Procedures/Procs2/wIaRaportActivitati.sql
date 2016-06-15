--***
create procedure wIaRaportActivitati @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wIaRaportActivitateSP' and type='P')      
	exec wIaRaportActivitateSP @sesiune,@parXML      
else      
begin
declare	@tipMasina varchar(20), @searchtext varchar(30)

select 
	@tipMasina=ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''),
    @searchtext = rtrim(isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(30)'), ''))

set @searchtext=REPLACE(@searchtext,' ','%')+'%'

select top 100
rtrim(em.Tip_masina) as tipMasina, 
rtrim(em.Element) as element, 
rtrim(e.Denumire) as denumire, 
convert(decimal(12,2),valoare) as valoare, 
em.Ord_raport as ordineRaport,
em.Grupa as grupa, g.Denumire as denumireGrupa
from elemtipm em
		inner join tipmasini tm on tm.Cod=em.Tip_masina
		inner join elemente e on e.Cod=em.Element
	left join grrapmt g on em.Grupa=g.Grupa
where tm.Cod=@tipMasina 
	  and (@tipMasina='' or tm.Cod like '%'+@tipMasina+'%')
	  and (em.Element like @searchtext or e.Denumire like '%'+@searchtext)
order by em.Tip_masina,
		(case when em.ord_raport>0 then 1 else 0 end) desc,
		em.ord_raport, em.Grupa
for xml raw

end
