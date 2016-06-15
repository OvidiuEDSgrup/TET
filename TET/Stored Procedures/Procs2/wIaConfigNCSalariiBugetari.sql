
create procedure wIaConfigNCSalariiBugetari @sesiune varchar(50), @parXML xml
as
	declare @utilizator varchar(100), @tip varchar(2), @f_contdebitor varchar(200), @f_contcreditor varchar(200), @f_denumire varchar(100),
		@f_lm varchar(20), @f_denlm varchar(50), @f_grlm varchar(50), @docXML xml

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
	set @f_denumire = '%'+ISNULL(@parXML.value('(/*/@f_denumire)[1]','varchar(100)'),'%')+'%'
	set @f_contdebitor = '%'+ISNULL(@parXML.value('(/*/@f_contdebitor)[1]','varchar(20)'),'%')+'%'
	set @f_contcreditor = '%'+ISNULL(@parXML.value('(/*/@f_contcreditor)[1]','varchar(20)'),'%')+'%'
	set @f_lm = @parXML.value('(/*/@f_lm)[1]','varchar(20)')
	set @f_denlm = ISNULL(@parXML.value('(/*/@f_denlm)[1]','varchar(50)'),'')
	set @f_grlm = ISNULL(@parXML.value('(/*/@f_grlm)[1]','varchar(50)'),'')
	set @tip = ISNULL(@parXML.value('(/*/@tip)[1]','varchar(20)'),'')

	if object_id('tempdb..#confignc') is not null drop table #confignc

	select s.Loc_de_munca, (case when s.Loc_de_munca is null then 'Unitate' else lm.denumire end) as denlm, 
		Numar_pozitie, Identificator, s.Denumire, 
		Cont_debitor, Cont_creditor, Comanda, Analitic, Expresie as expresie, 
		Cont_CAS, Cont_CASS, Cont_somaj, Cont_impozit, 
		convert(char(100),'') as grupare, convert(char(100),'') as grupare1,
		convert(char(100),'') as dengrupare, convert(char(100),'') as dengrupare1
	into #confignc
	from config_nc s
		left outer join lm on lm.cod=s.loc_de_munca
	where (isnull(@f_denumire,'')='' or s.Denumire like rtrim(@f_denumire))
		and (isnull(@f_contdebitor,'')='' or Cont_debitor like rtrim(@f_contdebitor)+'%')
		and (isnull(@f_contcreditor,'')='' or Cont_creditor like rtrim(@f_contcreditor)+'%')
		and (@f_lm is null or @f_lm=' ' and s.Loc_de_munca is null or @f_lm<>'' and s.Loc_de_munca like rtrim(@f_lm)+'%')
		and (isnull(@f_denlm,'')='' or lm.denumire like '%'+rtrim(@f_denlm)+'%')
	order by Numar_pozitie

	update #confignc set 
		grupare=(case when @f_grlm<>'' then loc_de_munca else convert(varchar(10),numar_pozitie) end),
		grupare1=(case when @f_grlm<>'' then convert(varchar(10),numar_pozitie) else loc_de_munca end),
		dengrupare=(case when @f_grlm<>'' then rtrim(denlm) else denumire end),
		dengrupare1=(case when @f_grlm<>'' then denumire else rtrim(denlm) end)

	set @docXML = (SELECT rtrim(dengrupare) as grupare, '#B43104' as culoare, max(numar_pozitie) as numar_pozitie, 
			(case when @f_grlm='' or @f_lm=' ' or @f_lm<>'' or @f_denlm<>'' then 'Da' else '' end) as _expandat, 
			isnull(a.Grupare,'') as ordine, 
--	date pentru detalii
			(select rtrim(dengrupare1) as grupare, rtrim(denlm) as denlm, rtrim(loc_de_munca) as lm, 
					p.Numar_pozitie as nrpozitie, rtrim(p.Identificator) as identificator, rtrim(p.Denumire) as denumire, 
					rtrim(p.Cont_debitor) as contdebitor, rtrim(p.Cont_creditor) as contcreditor, 
					rtrim(p.comanda) as comanda, convert(int,p.Analitic) as analitic, rtrim(p.Expresie) as expresie, 
					rtrim(p.Cont_CAS) as contcas, rtrim(p.Cont_CASS) as contcass, rtrim(p.Cont_somaj) as contsomaj, rtrim(p.Cont_impozit) as contimpozit
			from #confignc p
			where @f_grlm<>'' and (a.grupare is null and p.grupare is null or p.grupare=a.grupare) or @f_grlm='' and p.grupare=a.grupare
			order by p.Numar_pozitie
			FOR XML raw,type
			)
		FROM #confignc a
		group by grupare, dengrupare
		order by (case when @f_grlm<>'' then isnull(a.Grupare,'') else '' end), max(numar_pozitie)
		FOR XML raw, root('Ierarhie')
		)

	SELECT @docXML
	FOR XML path('Date')

	SELECT '1' AS areDetaliiXml
	FOR XML raw, root('Mesaje')	
