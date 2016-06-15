--***
create procedure wACGrupeElementeMM @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wACGrupeElementeSP' and type='P')      
	exec wACGrupeElementeSP @sesiune,@parXML      
else      
begin
declare	@tipMasina varchar(20), @searchtext varchar(30)

select 
	--@tipMasina=ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''),
    @searchtext = rtrim(isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(30)'), ''))

set @searchtext=REPLACE(@searchtext,' ','%')+'%'

select top 100 rtrim(g.Grupa) cod, rtrim (g.Denumire) as denumire, rtrim(g1.Denumire) as info
from grrapmt g left join grrapmt g1 on left(g.Grupa,1)=g1.Grupa
where (g.Grupa like @searchtext or g.Denumire like '%'+@searchtext)
	and len(rtrim(g.Grupa))>1
order by g.Grupa, g.Denumire
for xml raw

end
