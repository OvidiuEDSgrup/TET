create procedure  [dbo].[wIaPozAngajamenteLegale] @sesiune varchar(50), @parXML xml  
as 
begin
	declare @indbug varchar(30), @numar_ordonantare varchar(20), @numar_ang_legal varchar(8),@data_ordonantare datetime,
        @numar_ang_bug varchar(20),@data_ang_bug datetime,@doc xml
	select 
		@indbug=ISNULL(@parXML.value('(/row/@indbug)[1]', 'varchar(30)'), ''),  
		@data_ordonantare=ISNULL(@parXML.value('(/row/@data_ordonantare)[1]', 'datetime'), '01/01/1901'),  
		@data_ang_bug=ISNULL(@parXML.value('(/row/@data_ang_bug)[1]', 'datetime'), '01/01/1901'),  
		@numar_ordonantare=ISNULL(@parXML.value('(/row/@numar_ordonantare)[1]', 'varchar(20)'), ''),  
		@numar_ang_bug=ISNULL(@parXML.value('(/row/@numar_ang_bug)[1]', 'varchar(20)'), '')  	

	select 'v' as tip_doc,rtrim(r.numar_cfp) as numar, ''as numar_ang_legal,convert(char(10), r.data_CFP, 101) as data,
		rtrim(ltrim(r.observatii))as observatii,convert(varchar, r.data_CFP, 101)  as dataR,'#DF7401'as culoare, '' as stare,
		'VO' as subtip,'' as stareC,''as explicatii,@indbug as indbug,'' as indbug_cu_puncte ,''as denBeneficiar,''as denCompartiment,''as beneficiar,
		''as compartiment,null as suma,null as curs,''as valuta ,null as suma_valuta ,'' as nr_pozitie,''as data_OP,''as numar_ang_bug ,
		convert(char(10), r.data_CFP, 101) as data_CFP,@numar_ordonantare as numar_ordonantare  ,
		''as contract  ,'' as denumireAC,''as denContract,''as mod_de_plata,''as documente_justificative   
	into #temp from registrucfp r 
	where ( @indbug='' or r.indicator=@indbug )
		and r.numar=@numar_ordonantare 
		and r.tip='O'
					
	union all
	select 'o' as  tip_doc,
		rtrim(p.numar_OP) as numar,''as numar_ang_legal,convert(char(10),p.data_OP,101) as data,p.explicatii as observatii,
		convert(varchar, p.data_OP, 101)  as dataR,'#006400'as culoare, '' as stare,  'OP' as subtip,'' as stareC,
		''as explicatii,@indbug as indbug,'' as indbug_cu_puncte ,''as denBeneficiar,''as denCompartiment,''as beneficiar,
		''as compartiment,convert(decimal(12,3),p.suma) as suma ,convert(decimal(12,3),p.curs) as curs ,p.valuta as valuta,
		convert(decimal(12,3),p.suma_valuta) as suma_valuta,p.numar_pozitie as nr_pozitie,convert(char(10),p.data_OP,101) as data_OP,''as numar_ang_bug,
		''as data_CFP, @numar_ordonantare as numar_ordonantare ,''as contract,'' as denumireAC,
		''as denContract,''as mod_de_plata,''as documente_justificative   
	from pozordonantari p
	where p.numar_ordonantare=@numar_ordonantare 
	and p.data_ordonantare=@data_ordonantare
	and indicator=@indbug

	set @doc=(select  case when a.tip_doc='o' then 'Ordine de plata' else 'Vize-CFP' end as tip_doc,
				(select  case when a.tip_doc='o' then 'Ordin de plata' else 'Viza-CFP' end  as  tip_doc,
						rtrim(b.numar) as numar,''as numar_ang_legal,convert(char(10),b.data,101) as data,rtrim(b.observatii) as observatii,
						convert(varchar, b.data, 101)  as dataR,(case when a.tip_doc='o' then '#DF7401' else '#006400' end)as culoare, '' as stare,  b.subtip as subtip,'' as stareC,
						''as explicatii,@indbug as indbug,'' as indbug_cu_puncte ,''as denBeneficiar,''as denCompartiment,''as beneficiar,
						''as compartiment,convert(decimal(12,3),b.suma) as suma ,convert(decimal(12,3),b.curs) as curs ,b.valuta as valuta,
						convert(decimal(12,3),b.suma_valuta) as suma_valuta,b.nr_pozitie as nr_pozitie,convert(char(10),b.data_OP,101) as data_OP,''as numar_ang_bug,
						b.data_CFP as data_CFP, @numar_ordonantare as numar_ordonantare ,''as contract,'' as denumireAC,
						''as denContract,''as mod_de_plata,''as documente_justificative 
				from #temp b
				where a.tip_doc=b.tip_doc
				for xml raw,type)
			from #temp	a
			group by tip_doc		
			for xml raw,root('Ierarhie')
		)	
	drop table #temp
	if @doc is not null
		set @doc.modify('insert attribute _expandat {("da")} into (/Ierarhie)[1]')	
	select @doc for xml path('Date')
end
