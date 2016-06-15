/****** Object:  StoredProcedure [dbo].[wACSerii]    Script Date: 01/06/2011 01:04:36 ******/
--***
create PROCEDURE wACSerii
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wACSeriiSP' and type='P')      
	exec wACSeriiSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80),@tip varchar(2),@subtip varchar(2),@cod varchar(20),@cod_intrare varchar(13),
	    @gestiune varchar(13)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
	   @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') ,
	   @subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), '') ,
	   @cod=ISNULL(@parXML.value('(/row/@cod)[1]', 'varchar(13)'), ''),
	   @gestiune=isnull(ISNULL(@parXML.value('(/row/@gestiune)[1]', 'varchar(13)'), @parXML.value('(/row/linie/@gestiune)[1]', 'varchar(13)')),''),
	   @cod_intrare=ISNULL(@parXML.value('(/row/@codintrare)[1]', 'varchar(13)'), '')	    	

set @searchText=REPLACE(@searchText, ' ', '%')

if @cod=''
	begin
	set @cod=ISNULL(@parXML.value('(/row/linie/@cod)[1]', 'varchar(20)'),'')
	set @cod_intrare=ISNULL(@parXML.value('(/row/linie/@codintrareS)[1]', 'varchar(13)'),'')
	end
	
select @cod,@cod_intrare,@gestiune
select rtrim(a.Serie) as cod, rtrim(a.Serie) as denumire,'Stoc: '+convert(varchar,convert(decimal(12,3),SUM(a.Stoc))) as info
from serii a
where (a.Serie  like '%' + @searchText + '%')
  and a.Serie<>''
  and (a.Cod=@cod or @cod='')
  and (a.Cod_intrare=@cod_intrare or @cod_intrare='' or @tip='SI')
  and (Gestiune=@gestiune or @gestiune='' or @tip='SI')
group by a.Cod,a.Serie  
having (SUM(a.Stoc)>0.001 or @tip='SI')
order by rtrim(a.Serie)  
for xml raw
end
