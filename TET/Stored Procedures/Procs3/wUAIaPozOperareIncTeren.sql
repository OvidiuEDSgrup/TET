--***
/****** Object:  StoredProcedure [dbo].[wUAIaPozOperareIncTeren]    Script Date: 01/05/2011 23:52:44 ******/
create PROCEDURE  [dbo].[wUAIaPozOperareIncTeren]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
	set transaction isolation level READ UNCOMMITTED
	Declare  @cod_casier varchar(13),@data_inc datetime,@document varchar(8),@casier varchar(13),@tip_inc varchar(2),@doc xml


	select 
		@casier = isnull(@parXML.value('(/row/@casier)[1]','varchar(13)'),''),
		@data_inc=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '1901-01-01'),
		@tip_inc = isnull(@parXML.value('(/row/@tip_inc)[1]','varchar(2)'),'')
		--@document = isnull(@parXML.value('(/row/@document)[1]','varchar(10)'),'')
	
/*	set @doc=(
	select rtrim(a.abonat) as abonat, /*convert(decimal(12,2),a.Suma) as suma,convert(decimal(12,3),a.Penalizari) as penalizari,*/            
	       convert(varchar, a.Data, 101)  as data,rtrim(a.Document) as document,/*rtrim(a.Tip_incasare)as tip_incasare,*/RTRIM(a.loc_de_munca) as loc_de_munca,
	       RTRIM(a.Casier)as casier,RTRIM(a.Utilizator) as utilizator,rtrim(a1.denumire) as denAbonat,rtrim(t.Denumire) as denTip_incasare ,
	       /*RTRIM(f.Factura)+' / '+convert(varchar, f.Data, 101) as factura,RTRIM(a.id_factura)as id_factura,RTRIM(a.Tip) as tip,(case when a.Tip='IA' then 'Inc. Avans' when a.Tip='IF' then 'Inc. Factura'else a.Tip end)as denTip,*/
	       'Nr. '+rtrim(document)+', '+ rtrim(a1.denumire)+', Suma incasata: '+(select convert(varchar,convert(decimal(12,2),Sum(Suma))) from IncasariFactAbon where Document=a.Document and Data=a.Data) as grupFals/*_grupare*/,
	       '#000000' as culoare,
	    
	       (select (case when i.Tip='IA' then 'Inc. Avans, ' when i.Tip='IF' then 'Inc. Factura, 'else 'Compensare, ' end)+'data fact. '+CONVERT(char(10),a2.data,104)+',data inc. '+CONVERT(char(10),i.data,104) as grupFals, RTRIM(i.tip) as tip,RTRIM(a2.factura) as factura,CONVERT(decimal(12,2),i.suma) as suma,
	        CONVERT(decimal(12,2),i.Penalizari) as penalizari,'#0000A0' as culoare
			 from Incasarifactabon i
			 left outer join antetfactabon a2 on a2.Id_factura=i.id_factura
				where i.Casier=@casier and i.Data=@data_inc and i.Tip_incasare=@tip_inc	and i.abonat=a.abonat		 
			 order by a.Document 
			 for xml raw,type
			) 
	
	from IncasariFactAbon a left outer join abonati a1 on a.Abonat=a1.abonat
							left outer join AntetFactAbon f on a.id_factura=f.Id_factura
	                        left outer join Tipuri_de_incasare t on a.Tip_incasare=t.ID
	where a.Casier=@casier
	  and a.Data=@data_inc
	  and a.Tip_incasare=@tip_inc
	order by  a.Data desc,a.Document desc  
	for xml raw,root('Ierarhie')
	)*/
	
		set @doc=(
	select rtrim(a.abonat) as abonat, /*convert(decimal(12,2),a.Suma) as suma,convert(decimal(12,3),a.Penalizari) as penalizari,*/            
	       convert(varchar, a.Data, 101)  as data,rtrim(a.Document) as document,/*rtrim(a.Tip_incasare)as tip_incasare,*/max(RTRIM(a.loc_de_munca)) as loc_de_munca,
	       max(RTRIM(a.Casier))as casier,max(RTRIM(a.Utilizator)) as utilizator,max(rtrim(a1.denumire)) as denAbonat,max(rtrim(t.Denumire)) as denTip_incasare ,
	       /*RTRIM(f.Factura)+' / '+convert(varchar, f.Data, 101) as factura,RTRIM(a.id_factura)as id_factura,RTRIM(a.Tip) as tip,(case when a.Tip='IA' then 'Inc. Avans' when a.Tip='IF' then 'Inc. Factura'else a.Tip end)as denTip,*/
	       'Nr. '+rtrim(document)+', '+ max(rtrim(a1.denumire))+', Suma incasata: '+convert(varchar,convert(decimal(12,2),Sum(a.Suma)))  as grupFals/*_grupare*/,
	       '#000000' as culoare,
	    
	       (select (case when i.Tip='IA' then 'Inc. Avans, ' when i.Tip='IF' then 'Inc. Factura, 'else 'Compensare, ' end)+'data fact. '+CONVERT(char(10),a2.data,104)+',data inc. '+CONVERT(char(10),i.data,104) as grupFals, RTRIM(i.tip) as tip,RTRIM(a2.factura) as factura,CONVERT(decimal(12,2),i.suma) as suma,
	        CONVERT(decimal(12,2),i.Penalizari) as penalizari,'#0000A0' as culoare
			 from Incasarifactabon i
			 left outer join antetfactabon a2 on a2.Id_factura=i.id_factura
				where i.Casier=@casier and i.Data=@data_inc and i.Tip_incasare=@tip_inc	and i.abonat=a.abonat		 
			 order by a.Document 
			 for xml raw,type
			) 
	
	from IncasariFactAbon a left outer join abonati a1 on a.Abonat=a1.abonat
							left outer join AntetFactAbon f on a.id_factura=f.Id_factura
	                        left outer join Tipuri_de_incasare t on a.Tip_incasare=t.ID
	where a.Casier=@casier
	  and a.Data=@data_inc
	  and a.Tip_incasare=@tip_inc
	group by a.abonat,a.document,a.data
	order by  a.Data desc,a.Document desc  
	for xml raw,root('Ierarhie')
	)
	select @doc for xml path('Date')
end
