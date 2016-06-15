create procedure  [dbo].[wIaAngajamenteBugetare] @sesiune varchar(50), @parXML XML    
as 
begin try   
	set transaction isolation level READ UNCOMMITTED

	Declare  
		@gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int, @cSub char(9), @utilizator varchar(20),@filtruCod_de_Bare varchar(80) ,
		@anfiltru int,@indbug varchar(20),@mesajeroare varchar(500)
		
	select 
		@indbug = isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),'')   

	exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output    
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	declare @anchar varchar(10)
	set @anchar=isnull(@parXML.value('(/row/@anplan)[1]','varchar(10)'),'')

	if isnumeric(@anchar)=1
		set @anfiltru=convert(int,@anchar)
	else 
		set @anfiltru=year(getdate())
	
	declare @lista_lm int
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)
    
	select distinct top 100 p.*
	into #angajamenteBugetare 
	from angbug p 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_de_munca=lu.cod
	where p.indicator=@indbug
		and year(p.data)=@anfiltru
		and (@lista_lm=0 or lu.cod is not null)


	select rtrim(p.indicator)as indicator,rtrim(ltrim(p.numar))as numar,p.data,
		p.stare,(case when p.stare='0' then '0-Propunere'
                    when p.stare='1' then '1-Viza prop.'
                    when p.stare='4' then '4-Respins'
                    when p.stare='5' then '5-Angajare bugetara'
                    when p.stare='6' then '6-Viza angajare' end) as stareC,
		ltrim(rtrim(p.loc_de_munca)) as loc_de_munca,ltrim(rtrim(p.beneficiar))as beneficiar,convert(decimal(12,3),p.suma) as suma,
		p.valuta,convert(decimal(12,3),p.curs) as curs,convert(decimal(12,3),p.suma_valuta) as suma_valuta,ltrim(rtrim(p.explicatii))as explicatii,
		p.observatii,p.utilizator,p.data_operarii,p.ora_operarii,p.data_angajament, convert(varchar, p.data, 101)  as dataR ,
		lm.denumire as denLm              
	from #angajamenteBugetare p  
		left outer join lm on p.loc_de_munca=lm.cod
	order by 1
	for xml raw    

	drop table #angajamenteBugetare
end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
