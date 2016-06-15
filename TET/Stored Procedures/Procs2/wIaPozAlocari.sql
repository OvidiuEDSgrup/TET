create procedure [dbo].[wIaPozAlocari] @sesiune varchar(50), @parXML XML  
as
	declare 
		@idParinte int, @comanda varchar(20),@doc xml
		
	set @comanda= ISNULL(@parXML.value('(/row/@comanda)[1]','varchar(20)'),'')	
	set @idParinte= (select id from pozTehnologii where cod=@comanda and tip='L')
		
	set @doc=
	(
		select
			p.id as id, RTRIM(p.cod) +' '+ (select rtrim(denumire) from catop where cod= p.cod)as denumire, 
			RTRIM(p.cod) as cod,
			CONVERT(decimal(10,2),p.cantitate) as cantitate, CONVERT(decimal(10,2),p.pret) as pret, 
			RTRIM(p.resursa) as resursa, CONVERT(decimal(10,2),p.ordine_o) as ordine,
			(select rtrim(pp.cod) from pozTehnologii pp where pp.id = p.idp) as parinte,
			(
				select 
					RTRIM(comanda) as denumire, convert(decimal(10,2),cantitate) as cantitate,'MO' as subtip,
					(select RTRIM(descriere) from Resurse where cod=planificare.resursa) as resursa,
					RTRIM(resursa) as codRes, idOp as idOp,id as id,RTRIM(p.cod) as cod,
					convert(char(10),dataStart,101) as dataStart,convert(char(10),dataStop,101) as dataStop,
					SubString(oraStart,1,2)+':'+(case when SubString(oraStart,3,2)='' then '00' else SubString(oraStart,3,2) end)  as oraStart, SubString(oraStop,1,2)+':'+(case when SubString(oraStop,3,2)='' then '00' else SubString(oraStop,3,2) end)  as oraStop
				from planificare 
				where idOp = p.id 
				for xml raw,type
			)		
		from pozTehnologii p where p.parinteTop=@idParinte and tip='O' 
		order by ordine
		for xml raw, root('Ierarhie')
	)	
	select @doc for xml path('Date')
