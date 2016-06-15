--***
create procedure wIaMfixe @sesiune varchar(50), @parXML xml
as
IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wIaMfixeSP' AND type = 'P')
	EXEC wIaMfixeSP @sesiune, @parXML
ELSE
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	declare @sub varchar(9), @alteinfomf int, @userASiS varchar(10), @lunacalc int, @anulcalc int, 
		@datacalc datetime, @filtrunrinv varchar(13), @filtrudenmf varchar(80), @filtrugest varchar(30), 
		@filtruLm varchar(30), @filtruCom varchar(30), @areDetalii bit

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	exec luare_date_par 'MF', 'ALTEINFO', @alteinfomf output, 0, ''
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	exec luare_date_par 'MF','LUNACAL', 0, @lunacalc output, ''
	exec luare_date_par 'MF','ANULCAL', 0, @anulcalc output, ''
	if @lunacalc=0 exec luare_date_par 'MF','LUNAI', 0, @lunacalc output, ''
	if @anulcalc=0 exec luare_date_par 'MF','ANULI', 0, @anulcalc output, ''
	if @lunacalc=0 set @lunacalc=month(GETDATE())
	if @anulcalc=0 set @anulcalc=year(GETDATE())
	set @datacalc=dbo.eom(convert(datetime,str(@lunacalc,2)+'/01/'+str(@anulcalc,4)))
	set @filtrunrinv=isnull(@parXML.value('(/row/@f_nrinv)[1]','varchar(13)'),'')
	set @filtrudenmf=isnull(@parXML.value('(/row/@f_denmf)[1]','varchar(80)'),'')
	set @filtrudenmf=Replace(@filtrudenmf,' ','%')
	set @filtrugest=isnull(@parXML.value('(/row/@f_gest)[1]','varchar(30)'),'')
	set @filtruLm=isnull(@parXML.value('(/row/@f_lm)[1]','varchar(30)'),'')
	set @filtruCom=isnull(@parXML.value('(/row/@f_comanda)[1]','varchar(30)'),'')

	IF OBJECT_ID('tempdb..#wfisaMF') IS NOT NULL
		DROP TABLE #wfisaMF

	select *, row_number() over(partition by numar_de_inventar order by data_lunii_operatiei desc) as ranc 
	into #wfisaMF
	from fisaMF 
	where Felul_operatiei='1' 
	delete from #wfisaMF where ranc<>1
	CREATE INDEX wfisaMF on #wfisaMF (subunitate, numar_de_inventar, data_lunii_operatiei, felul_operatiei)
	
	IF OBJECT_ID('tempdb..#wMfix') IS NOT NULL
		DROP TABLE #wMfix

	CREATE TABLE #Mfix100 (nrinv VARCHAR(20) PRIMARY KEY)

	INSERT #Mfix100
	SELECT TOP 100 rtrim(x.Numar_de_inventar) AS nrinv
	FROM Mfix x
	left outer join #wfisaMF f1 on f1.Subunitate=x.Subunitate and f1.Felul_operatiei='1' and f1.Numar_de_inventar=x.Numar_de_inventar
	left outer join gestiuni g on g.cod_gestiune = isnull(f1.gestiune,'')
	left join lm on lm.cod=isnull(f1.Loc_de_munca, '')
	left join comenzi c on c.subunitate=@sub and c.comanda=isnull(f1.comanda, '')
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=isnull(f1.Loc_de_munca, '')
	WHERE x.subunitate=@sub and (x.Numar_de_inventar like @filtrunrinv+'%') 
	and (x.denumire like '%'+@filtrudenmf+'%') and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	and (isnull(f1.Loc_de_munca,'') like @filtruLm+'%' or isnull(lm.Denumire,'') like '%'+@filtruLm+'%') 
	and (isnull(f1.comanda,'') like @filtruCom+'%' or isnull(c.Descriere,'') like '%'+@filtruCom+'%') 
	and (isnull(f1.Gestiune,'') like @filtrugest+'%' or isnull(LEFT(g.Denumire_gestiune,30),'') like 
	'%'+@filtrugest+'%')

	SELECT rtrim(x.Numar_de_inventar) as nrinv, rtrim(x.Denumire) as denmf,
		rtrim(f1.cont_mijloc_fix) as contmf, rtrim(cm.Denumire_cont) as dencontmf, 
		rtrim(f1.Cont_amortizare) as contam, rtrim(ca.Denumire_cont) as dencontam, 
		rtrim(f1.Cont_cheltuieli) as contcham, rtrim(cca.Denumire_cont) as dencontcham, 
		(case x.tip_amortizare when '1' then 'Necalc.' when '2' then 'Liniara' when '3' then 
		'Degr. 1' when '4' then 'Degr. 2' when '5' then 'Accelerata' when '6' then 'Prima 20 %' 
		when '7' then 'Lin.sugerata' else '' end) as tipam, rtrim(x.cod_de_clasificare) as codcl, 
		rtrim(cc.denumire) as dencodcl, convert(char(10),x.Data_punerii_in_functiune,101) as datapf, 
		rtrim(x.serie) as seriemf, rtrim(f1.loc_de_munca) as lm, rtrim(lm.denumire) as denlm,
		rtrim(f1.Gestiune) as gest, rtrim(left(g.Denumire_gestiune,30)) as dengest,
		rtrim(xd.Tip_amortizare) as patrim, rtrim(xd.denumire) as denalternmf, 
		rtrim(xd2.denumire) as prodmf, rtrim(xd2.serie) as modelmf, rtrim(xd2.cod_de_clasificare) 
		as nrinmatrmf, rtrim(xd3.serie) as durfunct, rtrim(xd3.cod_de_clasificare) as staremf, 
		convert(char(10),xd3.Data_punerii_in_functiune,101) as datafabr, 
		rtrim(xd4.Serie) as codmfpublic, rtrim(mfp.denumire) as denmfpublic, 
		rtrim(f1.comanda) comanda,
		convert(decimal(17,2), f1.Valoare_de_inventar) valinv, 
		convert(decimal(17,2), f1.Valoare_amortizata) valam, 
		(case 
			when m.Subunitate is not null then '#808080' -- mijloace fixe iesite
			when f1.Valoare_amortizata>=f1.Valoare_de_inventar then '#FF0000' -- amortizat integral  
			when f1.Valoare_de_inventar<2500 then '#0000FF' -- de natura ob. inventar 
			else '#000000' end)  as culoare, -- in curs
		(case when 0=0 then 1 else 0 end) as _nemodificabil
	INTO #wMfix
	FROM Mfix x
	INNER JOIN #Mfix100 x1 ON x.Numar_de_inventar = x1.nrinv
	left outer join MFix xd on xd.Subunitate='DENS' and xd.Numar_de_inventar=x.Numar_de_inventar
	left outer join MFix xd2 on @alteinfomf=1 and xd2.Subunitate='DENS2' and xd2.Numar_de_inventar=x.Numar_de_inventar
	left outer join MFix xd3 on @alteinfomf=1 and xd3.Subunitate='DENS3' and xd3.Numar_de_inventar=x.Numar_de_inventar
	left outer join MFix xd4 on xd4.Subunitate='DENS4' and xd4.Numar_de_inventar=x.Numar_de_inventar
	left outer join mismf m on m.subunitate=x.Subunitate and m.Numar_de_inventar=x.Numar_de_inventar and LEFT(m.tip_miscare,1)='E' and m.Data_lunii_de_miscare<=@datacalc
	left outer join #wfisaMF f1 on f1.Subunitate=x.Subunitate and f1.Felul_operatiei='1' and f1.Numar_de_inventar=x.Numar_de_inventar
	left outer join Codclasif cc on cc.Cod_de_clasificare = x.Cod_de_clasificare
	left outer join conturi cm on cm.Subunitate=x.Subunitate and cm.Cont=isnull(f1.Cont_mijloc_fix,'')
	left outer join conturi ca on ca.Subunitate=x.Subunitate and ca.Cont=isnull(f1.Cont_amortizare,'') 
	left outer join conturi cca on cca.Subunitate=x.Subunitate and cca.Cont=isnull(f1.Cont_cheltuieli,'')
	left outer join gestiuni g on g.cod_gestiune = isnull(f1.gestiune,'')
	left join MFpublice mfp on mfp.cod=xd4.Serie
	left join lm on lm.cod=isnull(f1.Loc_de_munca, '')
	--left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=isnull(f1.Loc_de_munca, '')
	WHERE x.subunitate=@sub
	ORDER BY patindex(@filtrunrinv+'%', x.Numar_de_inventar)

	IF EXISTS (SELECT 1 FROM syscolumns sc, sysobjects so WHERE so.id = sc.id AND so.NAME = 'Mfix'
				AND sc.NAME = 'detalii')
	BEGIN
		SET @areDetalii = 1

		ALTER TABLE #wMfix ADD detalii XML

		UPDATE #wMfix SET detalii = x.detalii
		FROM Mfix x
		INNER JOIN #Mfix100 xx ON xx.nrinv = x.Numar_de_inventar
		WHERE x.Numar_de_inventar = #wMfix.nrinv and x.Subunitate=@sub
	END
	ELSE
		SET @areDetalii = 0

	SELECT * FROM #wMfix
	FOR XML raw, root('Date')

	SELECT @areDetalii AS areDetaliiXml
	FOR XML raw, root('Mesaje')
	
	DROP TABLE #Mfix100
END
