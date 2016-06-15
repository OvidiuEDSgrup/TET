create procedure  [dbo].[wIaIndicatoriBugetari] @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wIaIndicatoriBugetariSP' and type='P')
	exec wIaIndicatoriBugetariSP @sesiune, @parXML 
else      
begin try
	set transaction isolation level READ UNCOMMITTED

	Declare @filtruCod varchar(100), @filtruDenumire varchar(100), @filtruTipNomenclator varchar(1),
        @filtruFurnizor varchar(13), @filtruGestiune varchar(13) ,@filtruStocJ decimal(13,2), @filtruStocS decimal(13,2),    
        @gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int, @cSub char(9), @utilizator varchar(20),@filtruCod_de_Bare varchar(80) ,
        @filtruIndicator  varchar (100),@filtrugrupa  varchar (100), @anchar varchar(10), @anfiltru int,@filtrulm varchar(80),
        @mesajeroare varchar(500)
    
	select 
		@filtruindicator = isnull(@parXML.value('(/row/@filtruindicator)[1]','varchar(80)'),'') ,
		@filtrudenumire = isnull(@parXML.value('(/row/@filtrudenumire)[1]','varchar(80)'),''),    
		@filtrugrupa = isnull(@parXML.value('(/row/@filtrugrupa)[1]','varchar(80)'),''),
		@filtrulm = isnull(@parXML.value('(/row/@filtrulm)[1]','varchar(80)'),''),
		@anchar = isnull(@parXML.value('(/row/@filtruan)[1]','varchar(10)'),''),
		@filtruindicator = replace(@filtruindicator,'.','') 
    
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	if isnumeric(@anchar)=1
		set @anfiltru=convert(int,@anchar)
	else 
		set @anfiltru=year(getdate())
	    
	declare @lista_lm int
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

	set @filtrudenumire='%'+Replace(@filtrudenumire,' ','%')+'%'  
	set @filtrugrupa='%'+Replace(@filtrugrupa,' ','%')+'%'
	    
	select  top 100  i.indbug,i.denumire,i.grup,i.descr,i.grupa,i.alfa1,i.alfa2,i.val1,i.val2,i.utilizator,
		i.data_operarii,i.ora_operarii,g.Denumire_grupa as denGrupa
	into #indicatori  
	from indbug i 
		left join indbuggr g on i.grupa=g.grupa 
	where i.denumire like @filtrudenumire
		and i.indbug like @filtruindicator+'%'
		and i.indbug like @filtruindicator+'%'
		--and g.denumire_grupa like @filtrugrupa+'%'

	select 
		@anfiltru as anplan, @filtrulm as filtrulm,
		rtrim(i.indbug) as indbug,ltrim(rtrim(i.grupa)) as grupa,rtrim(i.denumire) as denumire,rtrim(i.descr)as descriere,rtrim(ltrim(i.denGrupa))as denGrupa,
		isnull(substring(i.indbug,1,4),'  ') as capitol,isnull(substring(i.indbug,5,2),'  ')as subcapitol, isnull(substring(i.indbug,7,2),'  ') as paragraf,
		isnull(substring(i.indbug,9,2),'  ') as titlu,isnull(substring(i.indbug,11,2),'  ') as articol, isnull(substring(i.indbug,13,2),'  ') as aliniat,
		isnull(substring(i.indbug,15,2),'  ') as rand ,CAST(i.grup AS bit)as grup,
		dbo.fn_indbugcupuncte(i.indbug) as indbug_cu_puncte,
		(isnull(convert(decimal(12,3),    
			(select sum(p.suma) from pozncon p left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
			where substring(p.comanda,21,20)=i.indbug and p.tip='AO' and substring(p.numar,1,8)in ('BA_TRIM1','RB_TRIM1')
				and year(p.data)=@anfiltru and (p.Loc_munca=@filtrulm or ISNULL(@filtrulm,'')='') and (@lista_lm=0 or lu.cod is not null))),0)) as bugetalocat_trim1,
		(isnull(convert(decimal(12,3),
			(select sum(p.suma) from pozncon p left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
			where substring(p.comanda,21,20)=i.indbug and p.tip='AO' and substring(p.numar,1,8)in ('BA_TRIM2','RB_TRIM2')
				and year(p.data)=@anfiltru and (p.Loc_munca=@filtrulm or ISNULL(@filtrulm,'')='') and (@lista_lm=0 or lu.cod is not null))),0)) as bugetalocat_trim2 , 
		(isnull(convert(decimal(12,3),
			(select sum(p.suma) from pozncon p left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
			where substring(p.comanda,21,20)=i.indbug and p.tip='AO' and substring(p.numar,1,8)in ('BA_TRIM3','RB_TRIM3')
				and year(p.data)=@anfiltru and (p.Loc_munca=@filtrulm or ISNULL(@filtrulm,'')='') and (@lista_lm=0 or lu.cod is not null))),0)) as bugetalocat_trim3,
		(isnull(convert(decimal(12,3),
			(select sum(p.suma) from pozncon p left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
			where substring(p.comanda,21,20)=i.indbug and p.tip='AO' and substring(p.numar,1,8)in ('BA_TRIM4','RB_TRIM4')
				and year(p.data)=@anfiltru and (p.Loc_munca=@filtrulm or ISNULL(@filtrulm,'')='') and (@lista_lm=0 or lu.cod is not null))),0)) as bugetalocat_trim4,
		(isnull(convert(decimal(12,3),
			(select sum(p.suma) from pozncon p left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
			where substring(p.comanda,21,20)=i.indbug and p.tip='AO' and substring(p.numar,1,7)in ('BA_TRIM','RB_TRIM')
				and year(p.data)=@anfiltru and (p.Loc_munca=@filtrulm or ISNULL(@filtrulm,'')='') and (@lista_lm=0 or lu.cod is not null))),0)) as bugetalocat

	from #indicatori i  
	order by patindex('%'+@filtruDenumire+'%', i.denumire)
	for xml raw  
	  
	drop table #indicatori
end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
