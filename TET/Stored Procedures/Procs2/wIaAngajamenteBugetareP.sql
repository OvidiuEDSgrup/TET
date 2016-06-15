create procedure  [dbo].[wIaAngajamenteBugetareP] @sesiune varchar(50), @parXML XML    
as    
begin try
	set transaction isolation level READ UNCOMMITTED

	Declare  
		@gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int, @cSub char(9), @utilizator varchar(20),@filtruCod_de_Bare varchar(80) ,
		@filtruAn varchar (100),@indbug varchar(20),@datasus datetime,@datajos datetime, @numar varchar(100),@filtrustare varchar(20),@filtruangbug varchar(20),
		@filtruindbug varchar(20),@data datetime,@mesajeroare varchar(500),@filtrulm varchar(80)
	--citire date din xml
	select 
		@indbug = isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
		@numar = isnull(@parXML.value('(/row/@numar)[1]','varchar(100)'),''),
		@data = isnull(@parXML.value('(/row/@data)[1]','datetime'),'1901-01-01'),
		@datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
		@filtruAn = isnull(@parXML.value('(/row/@filtruan)[1]','int'),''),   
		@filtruindbug = isnull(@parXML.value('(/row/@filtruindbug)[1]','varchar(20)'),''),
		@filtrulm = isnull(@parXML.value('(/row/@filtrulm)[1]','varchar(80)'),''),
		@filtrustare = isnull(@parXML.value('(/row/@filtrustare)[1]','varchar(20)'),''),
		@filtruangbug = isnull(@parXML.value('(/row/@filtruangbug)[1]','varchar(20)'),''),
		@filtruindbug = replace(@filtruindbug,'.','')
   
	exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output    
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
    
declare @lista_lm int
	set @lista_lm=(case when exists (select 1 from proprietati where tip='UTILIZATOR' 
															and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end) 
	
	select distinct top 100 p.*
	into #angajamenteBugetare 
	from angbug p 
	left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_de_munca=lu.cod
	where (@numar='' or p.numar=@numar)
	  and (@data='1901-01-01' or p.data=@data)
	  and (@indbug='' or p.indicator=@indbug)
	  and  p.data between @datajos and @datasus
	  and (indicator like @filtruindbug+'%'or @filtruindbug='')
	  and (stare like @filtrustare+'%'or @filtrustare='')
	  and (numar like @filtruangbug+'%'or @filtruangbug='')
	  and (@lista_lm=0 or lu.cod is not null)
	  and (p.Loc_de_munca=@filtrulm or ISNULL(@filtrulm,'')='')

	select rtrim(p.indicator)as indbug,ltrim(rtrim(p.numar))as numar, convert(char(10),p.data,101)as data,
		ltrim(rtrim(p.stare))as stare,(case when p.stare='0' then '0-Propunere'
											when p.stare='1' then '1-Viza prop.'
											when p.stare='4' then '4-Respins'
											when p.stare='5' then '5-Angajare bugetara'
											when p.stare='6' then '6-Viza angajare' end) as stareC,
		ltrim(rtrim(p.loc_de_munca)) as compartiment,ltrim(rtrim(p.beneficiar))as beneficiar,convert(decimal(12,3),p.suma) as suma,
		ltrim(rtrim(p.valuta))as valuta,convert(decimal(12,3),p.curs) as curs,convert(decimal(12,3),p.suma_valuta) as suma_valuta,rtrim(ltrim(p.explicatii))as explicatii,
		ltrim(rtrim(p.observatii))as observatii,ltrim(rtrim(p.utilizator))as utilizator,p.data_operarii,p.ora_operarii,p.data_angajament, 
		convert(varchar, p.data, 101)  as dataR ,RTRIM(t.Denumire)as denExplicatii,--campul explicatii este refolosit pentru salvarea tertului in cazul angbug individuale
		ltrim(rtrim(p.loc_de_munca))+'-'+rtrim(ltrim(lm.denumire)) as denCompartiment ,
		ltrim(rtrim(p.beneficiar))+'-'+rtrim(ltrim(l.denumire)) as denBeneficiar ,
		dbo.fn_indbugcupuncte(p.Indicator) as indbug_cu_puncte ,            
		(case when p.stare=4 then '#FF0000' when p.stare=5 then '#0000FF'  
			when p.stare=6 then '#888888' when p.stare=1 then '#088A08' else '#000000' end)  as culoare,      
		isnull(substring(i.indbug,1,2),'  ')+'.'+isnull(substring(i.indbug,3,2),'  ')+'.'+isnull(substring(i.indbug,5,2),'  ')+'.'+isnull(substring(i.indbug,7,2),'  ')+'.'
			  +isnull(substring(i.indbug,9,2),'  ')+'.'+isnull(substring(i.indbug,11,2),'  ')+'.'+isnull(substring(i.indbug,13,2),'  ')+' - '+rtrim(ltrim(i.denumire)) as denumireAC,
			  'AB'as tip
	from #angajamenteBugetare p  
		inner join indbug i on i.indbug=p.indicator 
		left outer join lm on p.loc_de_munca=lm.cod
		left outer join lm l on p.beneficiar=l.cod
		left outer join terti t on t.Tert=p.Explicatii
	order by 3 desc,2 desc
	for xml raw  
  
	drop table #angajamenteBugetare
end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
