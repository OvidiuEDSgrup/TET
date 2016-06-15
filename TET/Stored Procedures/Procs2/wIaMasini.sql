--***

create procedure wIaMasini @sesiune varchar(50),@parXML XML      
as      
if exists(select * from sysobjects where name='wIaMasiniSP' and type='P')      
	exec wIaMasiniSP @sesiune,@parXML      
else
set transaction isolation level READ UNCOMMITTED
declare @eroare varchar(1000)
begin try
if object_id('tempdb..#tmp') is not null drop table #tmp
if object_id('tempdb..#elemact') is not null drop table #elemact
if object_id('tempdb..#elemcoloane') is not null drop table #elemcoloane

declare	@f_codMasina varchar(20), @f_tipMasina varchar(20), @nr_inmatriculare varchar(15), @cSub varchar(13),
		@f_denumire varchar(40),  @f_grupa varchar(50), @f_tip_activitate varchar(10)

select 
	@cSub=ISNULL(@parXML.value('(/row/@cSub)[1]', 'varchar(13)'), '1'), 
	@f_codMasina=ISNULL(@parXML.value('(/row/@codMasina)[1]', 'varchar(20)'), ''), 
	@f_tipMasina=REPLACE(ISNULL(@parXML.value('(/row/@tipMasina)[1]', 'varchar(20)'), ''), ' ', '%') ,
	@f_denumire=REPLACE(ISNULL(@parXML.value('(/row/@denumire)[1]', 'varchar(40)'), ''), ' ', '%'), 
	@f_grupa=REPLACE(ISNULL(@parXML.value('(/row/@grupa)[1]', 'varchar(50)'), ''), ' ', '%'),
	@f_tip_activitate=REPLACE(ISNULL(@parXML.value('(/row/@tip_activitate)[1]', 'varchar(20)'), ''), ' ', '%') 

	select top 100
		rtrim(m.cod_masina) as codMasina,
		RTRIM(m.denumire) as denumire, 	
		RTRIM(g.tip_masina) as tipMasina, 
		RTRIM(t.Denumire) as denTipMasina, 
		RTRIM(m.loc_de_munca) as lm, 
		RTRIM(lm.Denumire) as denLm, 
		RTRIM(m.Comanda) as comanda, 
		RTRIM(c.Descriere) as denComanda,
		rtrim(m.grupa) as grupa,
		rtrim(g.denumire) as denGrupa, 
		rtrim(m.nr_inventar) as nr_inventar,
		t.Tip_activitate
	into #tmp
	from masini m
		left outer join grupemasini g on g.grupa=m.grupa
		left join tipmasini t on g.tip_masina=t.Cod
		left outer join lm on m.loc_de_munca = lm.Cod
		left outer join comenzi c on c.Subunitate=@cSub and c.Comanda=m.Comanda
	where(@f_codMasina='' or m.cod_masina like @f_codMasina+'%')
		and (@f_tipMasina='' or t.Denumire like '%'+@f_tipMasina+'%')
		and (@f_denumire='' or m.denumire like '%'+@f_denumire+'%')
		and (@f_grupa='' or g.Denumire like '%'+@f_grupa+'%')
		and (@f_tip_activitate='' or t.tip_activitate like '%'+@f_tip_activitate+'%')
	order by patindex('%'+@f_denumire+'%',m.denumire),1 
/*
	select row_number() over (partition by ea.element, a.masina order by ea.Data desc, ea.Fisa desc, ea.Numar_pozitie desc) as ordine,
		ea.element, a.masina, valoare, m.Tip_activitate
	into #elemact
	from elemactivitati ea
		inner join activitati a on a.Tip=ea.Tip and a.Fisa=ea.Fisa and a.Data=ea.Data 
		inner join #tmp m on a.Masina=m.codMasina
	where
	ea.Element in ('RestEst','KmBord','OREBORD')
	
	select masina,
			RestEst, KmBord, OREBORD, (case when Tip_activitate='P' then KmBord else OREBORD end) as KmOre
	into #elemcoloane
	from (select masina, element, ltrim(str(valoare,12,2)) valoare, Tip_activitate from #elemact where ordine=1) as p
	pivot
	(max(valoare)
	for element in ([RestEst],[KmBord],[OREBORD])
	) as pvt
	order by masina
	--select * from #elemcoloane --where ordine=1
	*/
	select m.codMasina, m.denumire, m.tipMasina, m.denTipMasina, m.lm, m.denLm, m.comanda, m.denComanda, m.grupa, m.denGrupa, m.nr_inventar,
		--ltrim(str(C100.Valoare,12,2)) as C100,
		ltrim(str(cRezervor.Valoare,12,2)) as cRezervor, 
		ltrim(str(cVara.Valoare,12,2)) as cVara, 
		ltrim(str(cIarna.Valoare,12,2)) as cIarna, 
		ltrim(str(cKmEf1.Valoare,12,2)) as cKmEf1, 
		ltrim(str(cKmEf2.Valoare,12,2)) as cKmEf2, 
		ltrim(str(cKmEf3.Valoare,12,2)) as cKmEf3, 
		--isnull(ltrim(str(co.Valoare,12,2)),0) as co,
		(case	
			when m.Tip_activitate='L'  then isnull(ltrim(str(co.Valoare,12,2)),0) 
			when m.Tip_activitate='P'  then ltrim(str(C100.Valoare,12,2)) 
			else '?' end) as C100,
		-- elemente urmarite:
		--ea.kmore, ea.kmbord, ea.orebord, ea.restest,
		convert(decimal(15),ea.valoare) as kmore,
		-- elemente implementare - Ghita, 19.03.2012: cred ca nu se foloseste tabela "valelemimpl"
		isnull((select top 1 ltrim(str(valoare,12,2)) from valelemimpl v where v.Masina=m.codMasina and v.Element='KmBord'),0) as KmBordImpl,
		isnull((select top 1 ltrim(str(valoare,12,2)) from valelemimpl v where v.Masina=m.codMasina and v.Element='RestDecl'),0) as RestDeclImpl,
		isnull((select top 1 ltrim(str(valoare,12,2)) from valelemimpl v where v.Masina=m.codMasina and v.Element='OREBORD'),0) as OREBORDImpl,
		(case when isnull(m.grupa,'')='' then '#CC0000' else '#000000' end) as culoare
	from #tmp m
		--left join #elemcoloane ea on ea.Masina=m.codMasina
		left join dbo.bordMM(null,null) ea on m.codMasina=ea.masina
		left outer join coefmasini C100 on C100.Masina=m.codMasina and C100.Coeficient='C100'
		left outer join coefmasini cRezervor on cRezervor.Masina=m.codMasina and cRezervor.Coeficient='cRezervor'
		left outer join coefmasini cVara on cVara.Masina=m.codMasina and cVara.Coeficient='cVara'
		left outer join coefmasini cIarna on cIarna.Masina=m.codMasina and cIarna.Coeficient='cIarna'
		left outer join coefmasini cKmEf1 on cKmEf1.Masina=m.codMasina and cKmEf1.Coeficient='cKmEf1'
		left outer join coefmasini cKmEf2 on cKmEf2.Masina=m.codMasina and cKmEf2.Coeficient='cKmEf2'
		left outer join coefmasini cKmEf3 on cKmEf3.Masina=m.codMasina and cKmEf3.Coeficient='cKmEf3'
		left outer join coefmasini co on co.Masina=m.codMasina and co.Coeficient='CO'	
	for xml raw      
end try
begin catch
	select @eroare='(wIaMasini)'+char(10)+error_message()
end catch

if object_id('tempdb..#tmp') is not null drop table #tmp
if object_id('tempdb..#elemact') is not null drop table #elemact
if object_id('tempdb..#elemcoloane') is not null drop table #elemcoloane

if len(@eroare)>0 raiserror(@eroare,16,1)
