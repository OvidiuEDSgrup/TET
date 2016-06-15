create procedure  [dbo].[wIaAngajamenteLegaleP] @sesiune varchar(50), @parXML XML    
as
begin try    
	set transaction isolation level READ UNCOMMITTED

	Declare  
		@gestiune varchar(20),@gestutiliz varchar(20), @cSub char(9), @utilizator varchar(20),@mesajeroare varchar(500),
		@indbug varchar(20),@filtruindbug varchar(20),@datasus datetime,@datajos datetime,@numar_ordonantare varchar(20),
		@filtruord varchar(20),@filtruangbug varchar(20),@numar_ang_bug varchar(20),@data_ordonantare datetime,@filtrulm varchar(80)
 --citire date din xml
	select 
	   @datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
	   @datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
	   @numar_ordonantare = isnull(@parXML.value('(/row/@numar_ordonantare)[1]','varchar(20)'),''),
	   @data_ordonantare = isnull(@parXML.value('(/row/@data_ordonantare)[1]','datetime'),'1901-01-01'),
	   @numar_ang_bug = isnull(@parXML.value('(/row/@numar_ang_bug)[1]','varchar(20)'),''),
	   @indbug = isnull(@parXML.value('(/row/@indbug)[1]','varchar(20)'),''),
	   @filtruindbug = isnull(@parXML.value('(/row/@filtruindbug)[1]','varchar(20)'),''),
	   @filtruord = isnull(@parXML.value('(/row/@filtruord)[1]','varchar(20)'),''),
	   @filtrulm = isnull(@parXML.value('(/row/@filtrulm)[1]','varchar(80)'),''),
	   @filtruangbug = isnull(@parXML.value('(/row/@filtruangbug)[1]','varchar(20)'),''),
	   @filtruindbug = replace(@filtruindbug,'.','')
  
   
	exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output    
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	    
	set @gestiune=''    
	set @gestutiliz=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTIUNE' and cod=@utilizator),'')    
	
	if @gestutiliz <> ''     
		set @gestiune=@gestutiliz  
 
	declare @lista_lm int
	set @lista_lm=(case when exists (select 1 from proprietati 
	where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end) 

	select distinct top 100 o.*
	into #angajamenteLegale 
	from ordonantari o 
	left outer join LMFiltrare lu on lu.utilizator=@utilizator and o.Compartiment=lu.cod
	where o.data_ordonantare between @datajos and @datasus
		and (@numar_ordonantare='' or o.numar_ordonantare=@numar_ordonantare)
		and (@data_ordonantare='01-01-1901' or o.data_ordonantare=@data_ordonantare)
		and (o.numar_ang_bug=@numar_ang_bug or @numar_ang_bug='')
		--and (o.indicator=@indbug or @indbug='')
		and (indicator like @filtruindbug+'%'or @filtruindbug='')
		and (numar_ordonantare like @filtruord+'%'or @filtruord='')
		and (numar_ang_bug like @filtruangbug+'%'or @filtruangbug='')
		and (@lista_lm=0 or lu.cod is not null)
		and (o.Compartiment=@filtrulm or ISNULL(@filtrulm,'')='')
	order by o.data_ordonantare desc,o.numar_ordonantare desc	

	select ltrim(rtrim(p.numar_ordonantare))as numar, rtrim(p.indicator)as indbug,ltrim(rtrim(p.numar_ordonantare))as numar_ordonantare,convert(char(10), p.data_ordonantare, 101) as data_ordonantare,
		  rtrim(ltrim(p.numar_ang_bug)) as numar_ang_bug,convert(char(10), p.data_ang_bug, 101) as data_ang_bug,rtrim(ltrim(p.numar_ang_legal))as numar_ang_legal,
		  convert(char(10), p.data_ang_legal, 101) as data_ang_legal,rtrim(t.denumire)as denContract,'c|'+rtrim(c.contract)as contract_AC,
		  ltrim(rtrim(p.beneficiar))as beneficiar,ltrim(rtrim(p.contract))as contract,ltrim(rtrim(p.compartiment)) as compartiment,
		  convert(decimal(12,3),p.suma) as suma, ltrim(rtrim(p.valuta))as valuta,convert(decimal(12,3),p.curs) as curs,
		  convert(decimal(12,3),p.suma_valuta) as suma_valuta,ltrim(rtrim(p.mod_de_plata))as mod_de_plata,
		  ltrim(rtrim(documente_justificative))as documente_justificative,ltrim(rtrim(p.observatii))as observatii,
		  ltrim(rtrim(p.utilizator))as utilizator, p.data_operarii,p.ora_operarii, convert(varchar, p.data_ordonantare, 101)  as data_ordonantareR ,
		  convert(varchar, p.data_ang_bug, 101)  as data_ang_bugR ,ltrim(rtrim(p.compartiment))+'-'+rtrim(ltrim(lm.denumire)) as denCompartiment ,
		  rtrim(ltrim(p.numar_ang_bug))+'|'+convert(char(10),p.data_ang_bug,101) as numar_ang_bug_AC,
	      
		  'Ang.bug: '+rtrim(ltrim(p.numar_ang_bug))+', pe indicator: '+
       		isnull(substring(p.indicator,1,2),'  ')+'.'+isnull(substring(p.indicator,3,2),'  ')+'.'+isnull(substring(p.indicator,5,2),'  ')+'.'+isnull(substring(p.indicator,7,2),'  ')+'.'
			+isnull(substring(p.indicator,9,2),'  ')+'.'+isnull(substring(p.indicator,11,2),'  ')+'.'+isnull(substring(p.indicator,13,2),'  ')+' - '+rtrim(ltrim(i.denumire)) as denumireAC,
	      
		  ltrim(rtrim(p.beneficiar))+'-'+rtrim(ltrim(l.denumire)) as denBeneficiar ,
		  isnull(substring(p.indicator,1,2),'  ')+'.'+isnull(substring(p.indicator,3,2),'  ')+'.'+isnull(substring(p.indicator,5,2),'  ')+'.'+isnull(substring(p.indicator,7,2),'  ')+'.'
		  +isnull(substring(p.indicator,9,2),'  ')+'.'+isnull(substring(p.indicator,11,2),'  ')+'.'+isnull(substring(p.indicator,13,2),'  ') as indbug_cu_puncte,
		  case when exists(select numar from registrucfp where numar=p.numar_ordonantare and tip='O' and indicator=p.indicator) then 'Ordonantare' else 'Angajament' end as stare,
		  case when exists(select numar from registrucfp where numar=p.numar_ordonantare and tip='O' and indicator=p.indicator) then '#736F6E' else '#000000' end as culoare
		  ,'OB'as tip,convert(char(10), p.data_ordonantare, 101) as data           
	from #angajamenteLegale  p 
		 left outer join lm on p.compartiment=lm.cod
		 left outer join lm l on p.beneficiar=l.cod
		 left outer join con c on c.Contract=p.Contract and c.Tip='FA'
		 left outer join terti t on c.Tert=t.tert
	,indbug i,angbug a     
	where a.indicator=i.indbug
	  and p.numar_ang_bug=a.numar
	  and p.data_ang_bug=a.data
	  and p.indicator=a.indicator    
	order by p.data_ordonantare desc,p.numar_ordonantare desc
	for xml raw  
	  
	drop table #angajamenteLegale 

end try
begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
