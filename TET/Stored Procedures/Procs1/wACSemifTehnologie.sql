
CREATE procedure wACSemifTehnologie @sesiune varchar(50), @parXML XML      
as    
 if exists(select * from sysobjects where name='wACSemifTehnologieSP' and type='P')    
 BEGIN    
  exec wACSemifTehnologieSP @sesiune=@sesiune, @parXML=@parXML    
  RETURN    
 END    
     
 declare @cod varchar(20) , @searchText varchar(80), @id int, @comanda varchar(20)
     
 set @cod= ltrim(rtrim(@parXML.value('(/row/@cod)[1]','varchar(20)')    ))
 set @comanda=@parXML.value('(/row/@comanda)[1]','varchar(20)')  
 set @searchText='%'+replace(ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),' ' ,'%')+'%'    
     
	if isnull(@comanda,'') = ''
	begin 
		select @id=id from poztehnologii where tip='T' and cod=@cod;
 		with arbore(id,cod,idParinte)    
		as    
		( select     
		  p.id as id, p.cod, p.idp    
		  from poztehnologii as p     
		  where  p.id=@id    
		      
		  union all      
		  select     
		 isnull((select id from poztehnologii where tip='T' and cod=p.cod) ,p.id), p.cod, p.idp    
		  from poztehnologii as p    
		  join arbore as a on a.id=p.idp  and p.tip not in ('A','L','E')    
		  )    
		     
		 select     
		  RTRIM(a.cod) as cod,RTRIM(n.denumire) as denumire , n.Tip as info    
		 from     
		  arbore a    
		  join nomencl n on n.Cod=a.cod and n.Denumire like @searchText and a.Cod like @searchText    
		  join tehnologii t on t.cod=n.cod and t.cod is not null  
		 for xml raw, root('Date')    
	end	
	else
		select 
			p.cod as cod, RTRIM(n.denumire) as denumire,'Comanda: ' + @comanda as info
		from pozTehnologii p 
		join pozLansari lansari on lansari.cod= @comanda and lansari.idp=p.id and lansari.tip='L'
		join nomencl n on n.Cod=p.cod
		for xml raw
