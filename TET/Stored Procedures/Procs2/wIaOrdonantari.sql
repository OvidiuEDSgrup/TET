create procedure  [dbo].[wIaOrdonantari] @sesiune varchar(50), @parXML XML    
as 
begin try   
	set transaction isolation level READ UNCOMMITTED

	Declare @gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int, @cSub char(9), @utilizator varchar(20),@filtruCod_de_Bare varchar(80) ,
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
    
	--declare @lista_lm int
	--set @lista_lm=dbo.areLMFiltru(@utilizator)

	select distinct top 100 p.*
	into #ordonantari
	from ordonantari p 
		left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Compartiment=lu.cod
	where p.indicator=@indbug
		and year(p.data_ordonantare)=@anfiltru
		and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)

	select rtrim(p.indicator)as indicator,rtrim(ltrim(p.numar_ordonantare))as nr_ord,
		p.data_ordonantare,rtrim(ltrim(p.numar_ang_bug)) as nr_ang_bug,p.data_ang_bug,
		rtrim(ltrim(p.numar_ang_legal))as numar_ang_legal,p.data_ang_legal,ltrim(rtrim(p.beneficiar))as beneficiar,p.contract,
		rtrim(ltrim(p.compartiment))as compartiment,convert(decimal(12,3),p.suma) as suma,p.valuta, convert(decimal(12,3),p.curs) as curs,
		convert(decimal(12,3),p.suma_valuta)as suma_valuta,p.mod_de_plata,p.documente_justificative,
		ltrim(rtrim(p.observatii))as observatii,p.utilizator,ltrim(rtrim(lm.denumire)) as denLm,
		(case when a.stare='0' then '0-Propunere'
					when a.stare='1' then '1-Viza prop.'
					when a.stare='4' then '4-Respins'
					when a.stare='5' then '5-Angajare bugetara'
					when a.stare='6' then '6-Viza angajare' end) as stareC,a.stare,
		convert(varchar, p.data_ordonantare, 101)  as dataR,ltrim(rtrim(t.denumire)) as denTert 
  
	from #ordonantari p  
		left outer join angbug  a on p.indicator=a.indicator and p.numar_ang_bug=a.numar and p.data_ang_bug=a.data
		left outer join lm on lm.cod=p.beneficiar
		left outer join con c on c.contract=p.contract
		left outer join terti t on c.tert=t.tert and c.subunitate=t.subunitate
	order by 1
	for xml raw  
  
	drop table #ordonantari
end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
