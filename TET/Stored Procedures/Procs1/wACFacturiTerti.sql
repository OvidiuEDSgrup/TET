--***
create procedure wACFacturiTerti @sesiune varchar(50), @parXML XML  
as  
declare @subunitate varchar(9), @searchText varchar(80), @tip varchar(2), @subtip varchar(2), @tert varchar(13), 
	@valuta varchar(3), @furnbenef varchar(1)--, @inValuta int
if exists (select 1 from sysobjects where [type]='P' and [name]='wACFacturiSP')
	exec wFacturiTertiSP @sesiune, @parXML 
else
begin
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''), 
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
	@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''), 
	@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''), 
	@valuta=ISNULL(@parXML.value('(/row/@valuta)[1]', 'varchar(3)'), '')

set @searchText=REPLACE(@searchText, ' ', '%')
set @furnbenef=(case when @tip in ('AP', 'AS') or @tip in ('RE', 'DE', 'EF') and (left(@subtip, 1)='I' and @subtip<>'IS' or @subtip='PS') then 'B' else 'F' end)
set @parXML.modify ('insert attribute furnbenef{sql:variable("@furnbenef")} into (/row)[1]')
--set @inValuta=(case when (@tip in ('RM', 'RS', 'AP', 'AS') or @tip in ('RE', 'DE', 'EF') and @subtip in ('PV', 'IV')) and @valuta<>'' then 1 else 0 end)

exec wACFacturi @sesiune=@sesiune,@parXML=@parXML
  
--select top 100 rtrim(f.Factura)+'|'+rtrim(f.Tert) as cod, 
--RTRIM(t.denumire) + ', Data ' + CONVERT(varchar(10), f.data, 103) + ', Scad. ' + CONVERT(varchar(10), f.data_scadentei, 103) as denumire, 
--'Sold ' + CONVERT(varchar(20), convert(money, (case when @inValuta=1 then f.sold_valuta else f.sold end)), 1) + ' ' + (case when @inValuta=1 then @valuta else 'lei' end) as info
--from facturi f
--inner join terti t on t.subunitate=@subunitate and f.tert=t.tert 
--where t.Denumire like @searchText+'%'
--and (@tert='' or f.Tert=@tert)
--and f.Tip=(case when @furnbenef='B' then 0x46 else 0x54 end)
--and (@inValuta=0 or f.Valuta=@valuta)
--and (@tip not in ('RE', 'DE', 'EF') or ABS(case when @inValuta=1 then f.sold_valuta else f.sold end)>=0.01)
--order by 1
--for xml raw
end
