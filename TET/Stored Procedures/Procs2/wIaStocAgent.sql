CREATE procedure wIaStocAgent @sesiune varchar(50), @parxml xml        
as 
     
    declare @utilizator varchar(100), @lm varchar(50)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output     
 
	  
	select top 10000 RTRIM(gestiuni.Denumire_gestiune) as codGest,rtrim(nomencl.cod) as cod,        
		RTRIM(gestiuni.Denumire_gestiune) as denumire,        
		ltrim(convert(varchar(20),CONVERT(money,sum(stocuri.stoc)),1))+' '+rtrim(nomencl.um) as info        
	from stocuri        
	inner join gestiuni on stocuri.Subunitate=gestiuni.Subunitate and stocuri.Cod_gestiune=gestiuni.Cod_gestiune        
	inner join nomencl on stocuri.cod=nomencl.cod  
	join proprietati p on p.Tip='utilizator' and p.Cod=@utilizator and p.Cod_proprietate = 'OGRUPNOM' and p.Valoare=nomencl.grupa        
	where stocuri.Subunitate='1' and stocuri.stoc<>0        
	group by stocuri.Cod_gestiune,gestiuni.Denumire_gestiune,nomencl.um,nomencl.cod        
	for xml raw
	
	
