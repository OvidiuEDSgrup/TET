CREATE procedure [dbo].[wACFacturiOP] @sesiune varchar(50), @parXML XML    
as    
declare @subunitate varchar(9), @searchText varchar(80), @tip varchar(2), @subtip varchar(2), @tert varchar(13),@utilizator varchar(20),@lista_lm bit,@fdataAntet datetime   
   
begin  
 select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),   
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),   
		@subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''),   
		@tert=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),  
		@fdataAntet=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'),'2010-12-01')  
	
	set @searchText=REPLACE(@searchText, ' ', '%')+'%'  
	exec wIaUtilizator @sesiune=@sesiune , @utilizator=@utilizator output    
	select @lista_lm=0  
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else @lista_lm end)   
	from proprietati   
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate in ('LOCMUNCA') and valoare<>''  
 --  
select top 100   rtrim(f.Factura) as cod,   
	rtrim(f.Factura)+' din '+CONVERT(varchar(10), max(isnull(f.data,'')), 103)+' Scad. ' + CONVERT(varchar(10), max(isnull(f.data_scadentei,'')), 103)+' Ct. ' + RTRIM(max(f.Cont_de_tert)) as denumire,  
	'Sold '+CONVERT(varchar(20), convert(money, f.sold), 1)+' lei' as info,  max(isnull(f.data,'')) as data  
from facturi f, terti t   
where (@tert='' or f.Tert=@tert) and f.Factura like @searchText   
		and t.tert=f.tert and f.tip='T'
		and f.sold>=0.01 and f.cont_de_tert not in ('408','462')  
		and not exists (select 1 from generareplati g where g.tip='P' and g.element='F' and g.tert=f.tert and g.factura=f.factura and g.Data1=f.data)  
		and (@lista_lm=0 or f.loc_de_munca in (select cod from LMfiltrare where utilizator=@utilizator))   
group by f.tert,f.factura,f.sold  
order by 4  
for xml raw  
end