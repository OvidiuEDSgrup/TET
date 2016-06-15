--***
/**	procedura pt. raport nota contabila salarii */
Create procedure rapNotaContabilaSalarii
	(@dataJos datetime, @dataSus datetime, @locm char(9)=null, @strict int=0, @comanda char(20)=null, @indbug char(20)=null, 
		@desfasurare int=1, @tipnc int=null, @nrdocRecif varchar(13)=null) 
as
/*
	@desfasurare=1	-> Conturi
	@desfasurare=2	-> Conturi, indicatori bugetari
	@desfasurare=3	-> Conturi, tipuri de sume
	@desfasurare=4	-> detalii
	@tipnc is null	-> Toate note contabile
	@tipnc=1		-> Notele contabile aferente lunii curente
	@tipnc=2		-> Notele contabile rectificative (diferente din luni anterioare)
*/
declare @eroare varchar(2000)
begin try
	set transaction isolation level read uncommitted
	declare @userASiS char(10), @Sub char(9), @Bugetari int, @NrDocSal varchar(8), @cDataDoc char(4), @NrDocSalRectif varchar(8), @NrDocTich varchar(8), 
	@NCTichete int, @nTipDoc decimal(10,2), @cTipDoc char(1), @DateTichete char(20), @GestiuneTichete char(9), @CodTichete char(20), @NCIndBug int, @Somesana int

--	pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @userASiS=dbo.fIaUtilizator(null)
	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @Bugetari=dbo.iauParL('GE','BUGETARI')
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @NCTichete=dbo.iauParL('PS','NC-TICHM')
	set @nTipDoc=dbo.iauParN('PS','NC-TICHM')
	set @cTipDoc=left(convert(char(2),convert(int, @nTipDoc)),1)
	set @cTipDoc=(case when @cTipDoc='' then '2' else @cTipDoc end)
	set @DateTichete=dbo.iauParA('PS','NC-TICHM')
	set @GestiuneTichete=left(@DateTichete,charindex(',',@DateTichete)-(case when charindex(',',@DateTichete)=0 then 0 else 1 end))
	set @CodTichete=substring(@DateTichete,charindex(',',@DateTichete)+1,20)
	set @Somesana=dbo.iauParL('SP','SOMESANA')

	set @cDataDoc=left(convert(char(10),@dataSus,101),2)+right(convert(char(10),@dataSus,101),2)
	set @NrDocSal='SAL'+@cDataDoc
	set @NrDocSalRectif='SAL'+rtrim(@cDataDoc)+'R'
	set @NrDocTich='TICH'+@cDataDoc

	if object_id('tempdb..#rapncsal') is not null drop table #rapncsal

	/*	punem datele in tabela temporara pentru a putea stabili indicatorul bugetar pentru fiecare pozitie de document */
	select p.subunitate, p.tip, p.numar, p.Data as data, p.Cont_debitor as cont_debitor, p.Cont_creditor as cont_creditor, p.Suma as suma, 
		p.Loc_munca as lm, left(p.Comanda,20) as comanda, convert(varchar(20),'') as indbug, p.explicatii, convert(varchar(1000),'') as ordonare, 
		p.Nr_pozitie as nr_pozitie, p.idPozncon as idPozitieDoc, 'pozncon' as tabela, substring(p.Comanda,21,20) as indbug_old
	into #rapncsal
	from pozncon p
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_munca
	where p.Subunitate=@Sub and p.Tip='PS' 
		and (isnull(@tipnc,0)=0 and (p.Numar like rtrim(@NrDocSal)+'%' or p.Numar like 'SALR%') or @tipnc=1 and p.Numar=@NrDocSal 
			or @tipnc=2 and p.Numar like 'SALR%' and (@nrdocRecif is null or p.Numar=@nrdocRecif))
		and p.Data between @dataJos and @dataSus 
		and (@locm is null or p.Loc_munca like rtrim(@locm)+ (case when @Strict=0 then '%' else '' end)) 
		and (@comanda is null or left(p.Comanda,20)=@comanda) 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null) 
	union all 
-- selectare cheltuieli pt. salariatii ocazionali cu cont creditor atribuit de tip furnizor
	select p.subunitate, p.tip, p.numar_document, p.Data, p.Cont_deb, p.Cont_cred, p.Suma, 
		p.Loc_munca, left(p.Comanda,20) as comanda, convert(varchar(20),'') as indbug, 
		p.explicatii, convert(varchar(1000),'') as ordonare,
		p.Numar_pozitie as nr_pozitie, p.idPozadoc as idPozitieDoc, 'pozadoc' as tabela, substring(p.Comanda,21,20) as indbug_old
	from pozadoc p
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_munca
	where p.Subunitate=@Sub and p.Tip='FF' 
		and isnull(@tipnc,0)<>2 and p.Numar_document between @NrDocSal and rtrim(@NrDocSal)+'ZZZ' and p.Data between @dataJos and @dataSus 
		and (@locm is null or p.Loc_munca like rtrim(@locm)+ (case when @Strict=0 then '%' else '' end)) 
		and (@comanda is null or left(p.Comanda,20)=@Comanda)   
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	union all 
-- selectare achitare contributii pt. salariatii ocazionali cu cont debitor atribuit de tip furnizor
	select p.subunitate, p.plata_incasare, p.numar, p.Data, p.Cont_corespondent, p.Cont, p.Suma, 
		p.Loc_de_munca, left(p.Comanda,20) as comanda, convert(varchar(20),'') as indbug, 
		p.explicatii, convert(varchar(1000),'') as ordonare,
		p.Numar_pozitie as nr_pozitie, p.idPozplin as idPozitieDoc, 'pozplin' as tabela, substring(p.Comanda,21,20) as indbug_old
	from pozplin p
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where p.Subunitate=@Sub and p.Data between @dataJos and @dataSus and p.Plata_incasare='PF' and isnull(@tipnc,0)<>2
		and p.Numar between @NrDocSal and rtrim(@NrDocSal)+'ZZZ' and p.Tert like 'M'+'%' 
		and (@locm is null or p.Loc_de_munca like rtrim(@locm)+(case when @Strict=0 then '%' else '' end)) 
		and (@comanda is null or left(p.Comanda,20)=@Comanda) 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	union all
-- selectare retineri generate ca si deconturi in pozplin
	select p.subunitate, p.plata_incasare, p.numar, p.Data, p.Cont_corespondent, p.Cont, p.Suma, 
		p.Loc_de_munca, left(p.Comanda,20) as comanda, convert(varchar(20),'') as indbug, 
		p.explicatii, convert(varchar(1000),'') as ordonare,
		p.Numar_pozitie as nr_pozitie, p.idPozplin as idPozitieDoc, 'pozplin' as tabela, substring(p.Comanda,21,20) as indbug_old
	from pozplin p
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where p.Subunitate=@Sub and p.Data between @dataJos and @dataSus and p.Plata_incasare='PD' 
		and isnull(@tipnc,0)<>2
		and p.Explicatii like 'Retinere marca'+'%'
		and (@locm is null or p.Loc_de_munca like rtrim(@locm)+(case when @Strict=0 then '%' else '' end)) 
		and (@comanda is null or left(p.Comanda,20)=@Comanda) 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	union all
-- selectare tichete de masa generate ca si consumuri
	select p.subunitate, p.tip, p.numar, p.Data, p.Cont_corespondent, p.Cont_de_stoc, round(p.Cantitate*p.Pret_de_stoc,2) as suma, 
		p.Loc_de_munca, left(p.Comanda,20) as comanda, convert(varchar(20),'') as indbug, 
		'Tichete de masa' as explicatii, p.Cont_corespondent+p.Cont_de_stoc+p.Loc_de_munca+left(p.Comanda,20) as ordonare,
		p.Numar_pozitie as nr_pozitie, p.idPozdoc as idPozitieDoc, 'pozdoc' as tabela, substring(p.Comanda,21,20) as indbug_old
	from pozdoc p
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where @NCTichete=1 and @cTipDoc='2' 
		and p.Subunitate=@Sub and p.Tip='CM' and p.Numar=@NrDocTich and p.Data between @dataJos and @dataSus 
		and isnull(@tipnc,0)<>2
		and p.Gestiune=@GestiuneTichete and p.Cod=@CodTichete 
		and (@locm is null or p.Loc_de_munca like rtrim(@locm)+(case when @Strict=0 then '%' else '' end)) 
		and (@comanda is null or left(p.Comanda,20)=@Comanda) 
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)

	/* apelam procedura unica de stabilire a indicatorului bugetar pentru fiecare pozitie de document */
	if @Bugetari=1 and exists (select * from sysobjects where name ='indbugPozitieDocument' and xtype='P')
	begin
		select '' as furn_benef, tabela, idPozitieDoc, indbug into #indbugPozitieDoc 
		from #rapncsal

		exec indbugPozitieDocument @sesiune=null, @parXML=null
		update p set p.indbug=ib.indbug
		from #rapncsal p
			left outer join #indbugPozitieDoc ib on ib.tabela=p.tabela and ib.idPozitieDoc=p.idPozitieDoc
	end

	/*	selectul final */
	select r.data, r.cont_debitor, r.cont_creditor, r.suma, 
		r.lm, isnull(lm.Denumire,'') as den_lm, r.comanda, isnull(co.Descriere,'') as den_comanda, r.indbug, isnull(i.Denumire,'') as den_indbug, 
		(case when r.tabela='pozdoc' then r.Explicatii 
			when @desfasurare=1 and @NCIndBug=1 and r.tabela='pozncon' then c.Denumire_cont 
			when @desfasurare in (1,2,3) then left(r.Explicatii, (case when charindex ('-', r.Explicatii)>1 then charindex('-',r.Explicatii)-1 else len(r.Explicatii) end)) 
			else r.Explicatii end) as explicatii, 
		(case when (@Somesana=1 and @desfasurare=1) then r.lm else '' end) as grupare_lm, 
		(case when @desfasurare=2 then r.indbug else '' end) as grupare_indbug, 
		(case when r.tabela='pozdoc' then r.Explicatii
			when @desfasurare=3 then left(r.Explicatii, (case when charindex ('-', r.Explicatii )>1 then charindex('-',r.Explicatii)-1 else len(r.Explicatii) end)) else '' end) as grupare_tipsume,
		(case when r.tabela='pozplin' and r.explicatii like 'Retinere marca%' then r.cont_creditor+cont_debitor+(case when @desfasurare=2 then r.indbug else '' end)
			when r.tabela='pozdoc' then r.ordonare+r.indbug
			when @desfasurare in (1,2,3) 
			then r.Subunitate+convert(char(10),r.data,102)+r.Cont_debitor+r.Cont_creditor
				+(case when (@Somesana=1 and @desfasurare=1) then r.lm else '' end)+(case when @desfasurare=2 then r.indbug else '' end) 
			else r.Subunitate+r.Tip+r.Numar+convert(char(10),r.Data,102)+replicate(' ',6-len(convert(varchar(6),r.Nr_pozitie)))+convert(char(6),r.Nr_pozitie) end) as ordonare
	from #rapncsal r
		left outer join conturi c on c.Subunitate=r.Subunitate and c.Cont=r.Cont_creditor
		left outer join lm lm on lm.Cod=r.lm
		left outer join comenzi co on co.Subunitate=r.Subunitate and co.Comanda=r.Comanda
		left outer join indbug i on i.Indbug=r.indbug
	where (@indbug is null or r.indbug like rtrim(@IndBug)+'%')
	order by ordonare, Grupare_tipsume

	if object_id('tempdb..#rapncsal') is not null drop table #rapncsal

end try

begin catch
	set @eroare='Procedura rapNotaContabilaSalarii (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

/*
	exec rapNotaContabilaSalarii '03/01/2012', '03/31/2012', null, 0, null, null, 2
*/
