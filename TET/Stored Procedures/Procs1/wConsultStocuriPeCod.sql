--***
create procedure wConsultStocuriPeCod @sesiune varchar(50), @parXML xml
as    
declare @returnValue int
if exists(select * from sysobjects where name='wConsultStocuriPeCodSP' and type='P')      
begin
	exec @returnValue = wConsultStocuriPeCodSP @sesiune,@parXML
	return @returnValue 
end

declare @cod varchar(50),@gestiune varchar(200)    
set nocount on

select	@cod = @parXML.value('(/row/@cod)[1]', 'Varchar(50)'),
		@gestiune = @parXML.value('(/row/@gestiune)[1]', 'varchar(200)')

select rtrim(stocuri.cod_gestiune) as gestiune,rtrim(gestiuni.denumire_gestiune) as denumire_gestiune,    
convert(char(10),data,103) as data,rtrim(cod_intrare) as cod_intrare,    
convert(decimal(12,2),pret) as pret,rtrim(cont) as cont,convert(decimal(12,2),stoc) as stoc,   
RTRIM(stocuri.Furnizor) as furnizor, RTRIM(isnull(terti.denumire,'')) as denumire_furnizor  
from stocuri    
inner join gestiuni on stocuri.cod_gestiune=gestiuni.cod_gestiune    
left outer join terti on terti.Tert=stocuri.Furnizor  
where cod=@cod and abs(stoc)>0.01    
order by data    
for xml raw  

return 0
