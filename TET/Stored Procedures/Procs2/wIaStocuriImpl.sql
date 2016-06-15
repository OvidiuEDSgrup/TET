--***
create procedure [dbo].wIaStocuriImpl @sesiune varchar(30), @parXML XML
AS    
declare @tip varchar(2),@fcod_gestiune varchar(13),@ftip_gestiune varchar(13),@data_jos datetime,@data_sus datetime,
	@an_impl int,@luna_impl int,@mod_impl int,@data_implementare datetime,@data_lunii datetime,@cod_gestiune varchar(13),@tip_gestiune varchar(1)

select  @tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@fcod_gestiune=isnull(@parXML.value('(/row/@fcod_gestiune)[1]', 'varchar(13)'), '') , 
		@ftip_gestiune=isnull(@parXML.value('(/row/@ftip_gestiune)[1]', 'varchar(1)'), ''),
		@tip_gestiune=isnull(@parXML.value('(/row/@tip_gestiune)[1]', 'varchar(13)'), ''),
		@data_jos=isnull(@parXML.value('(/row/@datajos)[1]', 'datetime'), '1901-01-01') ,
		@data_sus=isnull(@parXML.value('(/row/@datasus)[1]', 'datetime'), '2901-01-01') ,
		@data_lunii=isnull(@parXML.value('(/row/@data_lunii)[1]', 'datetime'), '1901-01-01') ,
		@cod_gestiune=isnull(@parXML.value('(/row/@cod_gestiune)[1]', 'varchar(13)'), '')
		
set @data_implementare='1901-01-01'	
		
	exec luare_date_par 'GE', 'ANULIMPL', 0, @an_impl output, ''
	exec luare_date_par 'GE', 'LUNAIMPL', 0, @luna_impl output, ''
	exec luare_date_par 'GE', 'IMPLEMENT', @mod_impl output, 0, ''

if @an_impl<>0
	set @data_implementare=dbo.EOM(convert(datetime,str(@luna_impl,2)+'/01/'+str(@an_impl,4),101))

select top 100 @tip as tip, max(a.Tip_gestiune) as tip_gestiune, rtrim(a.Cod_gestiune) as cod_gestiune, convert(varchar(10),a.Data_lunii,101) as data_lunii,
		count(*) as nr_pozitii,	convert(decimal(12,4), sum(a.stoc)) as stoc ,(case when max(a.Tip_gestiune)='F' then RTRIM(MAX(p.nume)) else RTRIM(max(g.Denumire_gestiune)) end) as dengestiune,
		(case when a.Data_lunii>@data_implementare then 1 else 0 end) as _nemodificabil,
		@data_jos as datajos, @data_sus as datasus
from istoricstocuri a
		left outer join gestiuni g on g.Cod_gestiune=a.Cod_gestiune
		left outer join personal p on p.Marca=a.Cod_gestiune and a.Tip_gestiune='F'
where ((g.Denumire_gestiune like '%'+@fcod_gestiune+'%' or (p.Nume like '%'+@fcod_gestiune+'%' and @tip='OF')) or a.Cod_gestiune like @fcod_gestiune+'%' or isnull(@fcod_gestiune,'')='')
	and (a.Tip_gestiune like '%'+@ftip_gestiune+'%' or isnull(@ftip_gestiune,'')='')	
	and ((a.Data_lunii between @data_jos and @data_sus) or (@tip<>'SU' and @tip<>'OI'))	
	and (a.Cod_gestiune=@cod_gestiune or ISNULL(@cod_gestiune,'')='')
	and (a.Data_lunii=(case when @tip in ('SI','OF') then @data_implementare else @data_lunii end) or ISNULL(@data_lunii,'1901-01-01')='1901-01-01')
	and ((a.Data_lunii<=@data_implementare and a.Tip_gestiune<>'F') or @tip<>'SI')  
	and ((a.Data_lunii>@data_implementare and a.Tip_gestiune<>'F') or @tip<>'SU') 
	and ((a.Data_lunii<=@data_implementare and a.Tip_gestiune='F') or @tip<>'OF')  
	and ((a.Data_lunii>@data_implementare and a.Tip_gestiune='F') or @tip<>'OI')   
  
group by a.Cod_gestiune, a.Data_lunii
order by a.Cod_gestiune, a.Data_lunii desc
for xml raw
/*
select * from istoricstocuri where cod_intrare='1234'
select * from par where parametru='ANULIMPL' and tip_parametru='GE'
select * from par where parametru='LUNAIMPL'and tip_parametru='GE'
select * from par where parametru='IMPLEMENT'and tip_parametru='GE'
*/
