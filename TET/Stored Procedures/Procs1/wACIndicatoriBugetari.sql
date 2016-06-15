create procedure  [dbo].[wACIndicatoriBugetari] @sesiune varchar(50), @parXML XML
as
begin try
	declare @searchText varchar(30),@data datetime, @meniu varchar(10), @tip varchar(2),@compartiment varchar(20),@mesajeroare varchar(500),
		@suma float
	select 
		@searchText = isnull(@parXML.value('(/row/@searchText)[1]','varchar(20)'),''),
		@compartiment = isnull(@parXML.value('(/row/@compartiment)[1]','varchar(20)'),''),
		@searchText = '%'+replace(@searchText,' ','%')+'%',
		@searchText = replace(@searchText,'.',''),
		@data = isnull(@parXML.value('(/row/@data)[1]','datetime'),'1901-01-01'), 
		@meniu = isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(10)'),''), 
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
		@suma = isnull(@parXML.value('(/row/@suma)[1]','float'),'')

	declare @utilizator varchar(50),@lista_lm int
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	select @lista_lm=(case when cod_proprietate='LOCMUNCA' and Valoare<>'' then 1 else 0 end)
	from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA'
	set @lista_lm=ISNULL(@lista_lm,0)
	
	select /*top 100*/ a.cod,a.denumire +' -> '+a.info as denumire
	,a.info from
	(
	select /*top 100*/ i.indbug as cod,       
       		isnull(substring(i.indbug,1,2),'  ')+'.'+isnull(substring(i.indbug,3,2),'  ')+'.'+isnull(substring(i.indbug,5,2),'  ')+'.'+isnull(substring(i.indbug,7,2),'  ')+'.'
			+isnull(substring(i.indbug,9,2),'  ')+'.'+isnull(substring(i.indbug,11,2),'  ')+'.'+isnull(substring(i.indbug,13,2),'  ')+' - '+rtrim(ltrim(i.denumire)) as denumire,
		   'Suma disponibila: '+
			 convert(varchar,((isnull(convert(decimal(12,3),(select sum(p.suma) from pozncon p left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
															where substring(p.comanda,21,20)=i.indbug 
																and p.tip='AO' 
																and (p.Loc_munca=@compartiment or ISNULL(@compartiment,'')='')
																and substring(p.numar,1,7)in ('BA_TRIM')
																and datepart(quarter,p.data)<=datepart(quarter,@data)
																and year(p.data)=year(@data) and (@lista_lm=0 or lu.cod is not null))),0)+
			
			 isnull(convert(decimal(12,3),(select sum(p.suma) from pozncon p left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
															 where substring(p.comanda,21,20)=i.indbug 
																and p.tip='AO' 
																and (p.Loc_munca=@compartiment or ISNULL(@compartiment,'')='')
																and substring(p.numar,1,7)in ('RB_TRIM')
																and datepart(quarter,p.data)<=datepart(quarter,@data)
																--and p.data<=@data
																and year(p.data)=year(@data) and (@lista_lm=0 or lu.cod is not null))),0)-                                                                                    
	                                                                                                 
			 isnull(convert(decimal(12,3),(select sum(suma) from angbug left outer join LMFiltrare lu on lu.utilizator=@utilizator and angbug.Loc_de_munca=lu.cod
											where indicator=i.indbug 
												and stare>'0'
												and stare<>'4'
												and (Loc_de_munca=@compartiment or ISNULL(@compartiment,'')='')
												and datepart(quarter,data)<=datepart(quarter,@data) 
												and year(data)=year(@data) and (@lista_lm=0 or lu.cod is not null))),0))))  as info
	from indbug i
	where (denumire like '%'+replace(@searchText,' ','%')+'%' or indbug like @searchText+'%')
	 and  grup=0
	) a where ((not (@meniu='AG' and @tip='AL') and convert(float,substring(a.info,18,len(a.info)-18))>0.0001)or @suma<0)
	for xml raw
end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
