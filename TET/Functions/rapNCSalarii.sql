--***
/**	functie pt. raport nota contabila salarii */
Create function [dbo].[rapNCSalarii]
	(@DataJ datetime, @DataS datetime, @unLm int, @Lm char(9), @Strict int, @oComanda int, @Comanda char(20), 
	@unIndBug int, @IndBug char(20), @Centr int, @CentrIndBug int, @CentrTipSume int) 
returns @NCSalarii table
	(Data datetime, Cont_debitor char(13), Cont_creditor char(13), Suma decimal(12,2), Loc_de_munca char(9), DenLM char(30), 
	Comanda char(20), DenComanda char(80), IndBug char(20), DenIndBug char(80), Explicatii char(80), GrupLM char(9),
	GrupIndBug char(20), GrupTipSume char(50), Ordonare varchar(100))
as
begin
	declare @userASiS char(10), @Sub char(9), @NrDocSal varchar(8), @cDataDoc char(4), @NrDocSal1 varchar(8), @NrDocTich varchar(8), 
	@NCTichete int, @nTipDoc decimal(10,2), @cTipDoc char(1), 
	@DateTichete char(20), @GestiuneTichete char(9), @CodTichete char(20), @NCIndBug int, @Somesana int

	set @userASiS=dbo.fIaUtilizator(null)
	set @Sub=dbo.iauParA('GE','SUBPRO')
	set @NCIndBug=dbo.iauParL('PS','NC-INDBUG')
	set @NCTichete=dbo.iauParL('PS','NC-TICHM')
	set @nTipDoc=dbo.iauParN('PS','NC-TICHM')
	set @cTipDoc=left(convert(char(2),convert(int, @nTipDoc)),1)
	set @cTipDoc=(case when @cTipDoc='' then '2' else @cTipDoc end)
	set @DateTichete=dbo.iauParA('PS','NC-TICHM')
	set @GestiuneTichete=left(@DateTichete,charindex(',',@DateTichete)-(case when charindex(',',@DateTichete)=0 then 0 else 1 end))
	set @CodTichete=substring(@DateTichete,charindex(',',@DateTichete)+1,20)
	set @Somesana=dbo.iauParL('SP','SOMESANA')

	set @cDataDoc=left(convert(char(10),@DataS,101),2)+right(convert(char(10),@DataS,101),2)
	set @NrDocSal='SAL'+@cDataDoc
	set @NrDocSal1='SAL'+@cDataDoc
	set @NrDocTich='TICH'+@cDataDoc

	insert into @NCSalarii
	select p.Data, p.Cont_debitor, p.Cont_creditor, p.Suma, p.Loc_munca, isnull(lm.Denumire,''), 
	left(p.Comanda,20), isnull(o.Descriere,''), substring(p.Comanda,21,20), isnull(i.Denumire,''), 
	(case when @Centr=1 and @NCIndBug=1 and @CentrIndBug=0 and @CentrTipSume=0 then c.Denumire_cont when @Centr=1 then 
	left(p.Explicatii, (case when charindex ('-', p.Explicatii )>1 then charindex('-',p.Explicatii)-1 else len(p.Explicatii) end)) else p.Explicatii end), 
	(case when (@Somesana=1 and @Centr=1) then p.Loc_munca else '' end) as Grupare_lm, 
	(case when @CentrIndBug=1 and @Centr=1 then substring(p.Comanda,21,20) else '' end) as Grupare_indbug, 
	(case when @CentrTipSume=1 then left(p.Explicatii, (case when charindex ('-', p.Explicatii )>1 then charindex('-',p.Explicatii)-1 else len(p.Explicatii) end)) else '' end) as Grupare_tipsume, 
	(case when @Centr=1 then p.Subunitate+convert(char(10),data,102)+p.Cont_debitor+p.Cont_creditor+
	(case when (@Somesana=1 and @Centr=1) then p.Loc_munca else '' end)+
	(case when @CentrIndBug=1 then substring(p.Comanda,21,20) else '' end) 
	else p.Subunitate+p.Tip+p.Numar+convert(char(10),p.Data,102)+replicate(' ',6-len(convert(varchar(6),p.Nr_pozitie)))+convert(char(6),p.Nr_pozitie) end) as ordonare1
	from pozncon p
		left outer join conturi c on c.Subunitate=p.Subunitate and c.Cont=p.Cont_creditor
		left outer join lm lm on lm.Cod=p.Loc_munca
		left outer join comenzi o on o.Subunitate=p.Subunitate and o.Comanda=left(p.Comanda,20)
		left outer join indbug i on i.Indbug=substring(p.Comanda,21,20)
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_munca
	where p.Subunitate=@Sub and p.Tip='PS' and p.Numar between @NrDocSal and @NrDocSal and p.Data between @DataJ and @DataS 
		and (@unLm=0 or p.Loc_munca like rtrim(@Lm)+ (case when @Strict=0 then '%' else '' end)) 
		and (@oComanda=0 or left(p.Comanda,20)=@Comanda) 
		and (@unIndBug=0 or substring(p.Comanda,21,20) like rtrim(@IndBug)+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	union all 
-- selectare cheltuieli pt. salariatii ocazionali cu cont creditor atribuit de tip furnizor
	select p.Data, p.Cont_deb, p.Cont_cred, p.Suma, p.Loc_munca, isnull(lm.Denumire,''), 
	left(p.Comanda,20), isnull(c.Descriere,''), substring(p.Comanda,21,20), isnull(i.Denumire,''), 
	(case when @Centr=1 then left(p.Explicatii, (case when charindex ('-', p.Explicatii )>1 then charindex('-',p.Explicatii)-1 else len(p.Explicatii) end)) else p.Explicatii end) as Grupare_tipsume, 
	(case when (@Somesana=1 and @Centr=1) then p.Loc_munca else '' end) as Grupare_lm, 
	(case when @CentrIndBug=1 and @Centr=1 then substring(p.Comanda,21,20) else '' end) as Grupare_indbug, 
	(case when @CentrTipSume=1 then left(p.Explicatii, (case when charindex ('-', p.Explicatii )>1 then charindex('-',p.Explicatii)-1 else len(p.Explicatii) end)) else '' end), 
	(case when @Centr=1 then p.Subunitate+convert(char(10),data,102)+p.Cont_deb+p.Cont_cred+
	(case when (@Somesana=1 and @Centr=1) then p.Loc_munca else '' end)+(case when @CentrIndBug=1 then substring(p.Comanda,21,20) else '' end) else p.Subunitate+p.Tip+p.Numar_document+convert(char(10),p.Data,102)+
	replicate(' ',6-len(convert(varchar(6),p.Numar_pozitie)))+convert(char(6),p.Numar_pozitie) end) as ordonare1
	from pozadoc p
		left outer join lm lm on lm.Cod=p.Loc_munca
		left outer join comenzi c on c.Subunitate=p.Subunitate and c.Comanda=left(p.Comanda,20)
		left outer join indbug i on i.Indbug=substring(p.Comanda,21,20)
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_munca
	where p.Subunitate=@Sub and p.Tip='FF' and p.Numar_document between @NrDocSal and rtrim(@NrDocSal)+'ZZZ' and p.Data between @DataJ and @DataS 
		and (@unLm=0 or p.Loc_munca like rtrim(@Lm)+ (case when @Strict=0 then '%' else '' end)) and (@oComanda=0 or left(p.Comanda,20)=@Comanda)   
		and (@unIndBug=0 or substring(p.Comanda,21,20) like rtrim(@IndBug)+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	union all 
-- selectare achitare contributii pt. salariatii ocazionali cu cont debitor atribuit de tip furnizor
	select p.Data, p.Cont_corespondent, p.Cont, p.Suma, p.Loc_de_munca, isnull(lm.Denumire,''), 
	left(p.Comanda,20), isnull(c.Descriere,''), substring(p.Comanda,21,20), isnull(i.Denumire,''), 
	(case when @Centr=1 then left(p.Explicatii, (case when charindex ('-', p.Explicatii )>1 then charindex('-',p.Explicatii)-1 else len(p.Explicatii) end)) else p.Explicatii end), 
	(case when (@Somesana=1 and @Centr=1) then p.Loc_de_munca else '' end) as Grupare_lm, 
	(case when @CentrIndBug=1 and @Centr=1 then substring(p.Comanda,21,20) else '' end) as Grupare_indbug, 
	(case when @CentrTipSume=1 then left(p.Explicatii, (case when charindex ('-', p.Explicatii)>1 then charindex('-',p.Explicatii)-1 else len(p.Explicatii) end)) else '' end) as Grupare_tipsume, 
	(case when @Centr=1 then p.Subunitate+convert(char(10),p.Data,102)+p.Cont_corespondent+p.Cont+
	(case when (@Somesana=1 and @Centr=1) then p.Loc_de_munca else '' end)+
	(case when @CentrIndBug=1 then substring(p.Comanda,21,20) else '' end) 
	else p.Subunitate+p.Numar+convert(char(10),p.Data,102)+replicate(' ',6-len(convert(varchar(6),p.Numar_pozitie)))+convert(char(6),p.Numar_pozitie) end) as ordonare1 
	from pozplin p
		left outer join lm lm on lm.Cod=p.Loc_de_munca
		left outer join comenzi c on c.Subunitate=p.Subunitate and c.Comanda=left(p.Comanda,20)
		left outer join indbug i on i.Indbug=substring(p.Comanda,21,20)
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where p.Subunitate=@Sub and p.Data between @DataJ and @DataS and p.Plata_incasare='PF' 
		and p.Numar between @NrDocSal and rtrim(@NrDocSal)+'ZZZ' and p.Tert like 'M'+'%' 
		and (@unLm=0 or p.Loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and (@oComanda=0 or left(p.Comanda,20)=@Comanda) 
		and (@unIndBug=0 or substring(p.Comanda,21,20) like rtrim(@IndBug)+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	union all
-- selectare retineri generate ca si deconturi in pozplin
	select p.Data, p.Cont_corespondent, p.Cont, p.Suma, p.Loc_de_munca, isnull(lm.Denumire,''), 
	left(p.Comanda,20), isnull(c.Descriere,''), substring(p.Comanda,21,20), isnull(i.Denumire,''), 
	(case when @Centr=1 then left(p.Explicatii,(case when charindex ('-',p.Explicatii )>1 then charindex('-',p.Explicatii)-1 else len(Explicatii) end)) else Explicatii end), 
	(case when (@Somesana=1 and @Centr=1) then p.Loc_de_munca else '' end) as Grupare_lm, 
	(case when @CentrIndBug=1 then substring(p.Comanda,21,20) else '' end) as Grupare_indbug, 
	(case when @CentrTipSume=1 then left(p.Explicatii, (case when charindex ('-', p.Explicatii )>1 then charindex('-',p.Explicatii)-1 else len(p.Explicatii) end)) else '' end) as Grupare_tipsume,
	p.Cont+p.Cont_corespondent+(case when @CentrIndBug=1 then substring(p.Comanda,21,20) else '' end) as Ordonare1
	from pozplin p
		left outer join lm lm on lm.Cod=p.Loc_de_munca
		left outer join comenzi c on c.Subunitate=p.Subunitate and c.Comanda=left(p.Comanda,20)
		left outer join indbug i on i.Indbug=substring(p.Comanda,21,20)
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where p.Subunitate=@Sub and p.Data between @DataJ and @DataS and p.Plata_incasare='PD' 
		and p.Explicatii like 'Retinere marca'+'%'
		and (@unLm=0 or p.Loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and (@oComanda=0 or left(p.Comanda,20)=@Comanda) 
		and (@unIndBug=0 or substring(p.Comanda,21,20) like rtrim(@IndBug)+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	union all
-- selectare tichete de masa generate ca si consumuri
	select p.Data, p.Cont_corespondent, p.Cont_de_stoc, round(p.Cantitate*p.Pret_de_stoc,2), p.Loc_de_munca, isnull(lm.Denumire,''), 
	left(p.Comanda,20), isnull(c.Descriere,''), substring(p.Comanda,21,20), isnull(i.Denumire,''), 
	'Tichete de masa', 
	(case when (@Somesana=1 and @Centr=1) then p.Loc_de_munca else '' end) as Grupare_lm, 
	(case when @CentrIndBug=1 then substring(p.Comanda,21,20) else '' end) as Grupare_indbug, 
	'Tichete de masa' as Grupare_tipsume,
	p.Cont_corespondent+p.Cont_de_stoc+p.Loc_de_munca+left(p.Comanda,20)+substring(p.Comanda,21,20) as Ordonare1
	from pozdoc p
		left outer join lm lm on lm.Cod=p.Loc_de_munca
		left outer join comenzi c on c.Subunitate=p.Subunitate and c.Comanda=left(p.Comanda,20)
		left outer join indbug i on i.Indbug=substring(p.Comanda,21,20)
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=p.Loc_de_munca
	where @NCTichete=1 and @cTipDoc='2' 
		and p.Subunitate=@Sub and p.Tip='CM' and p.Numar=@NrDocTich and p.Data between @DataJ and @DataS 
		and p.Gestiune=@GestiuneTichete and p.Cod=@CodTichete 
		and (@unLm=0 or p.Loc_de_munca like rtrim(@Lm)+(case when @Strict=0 then '%' else '' end)) 
		and (@oComanda=0 or left(p.Comanda,20)=@Comanda) and (@unIndBug=0 or substring(p.Comanda,21,20) like rtrim(@IndBug)+'%')
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	order by ordonare1, Grupare_tipsume
	return
end

/*
	select * from rapNCSalarii ('01/01/2011', '01/31/2011', 0, '', 0, 0, '', 0, '', 0, 0, 0) 
*/
