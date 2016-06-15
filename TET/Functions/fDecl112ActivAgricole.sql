--***
/**	functie ce returneaza date pt. declaratia 112 - contributie asigurari de sanatate si impozit retinute la achizitii de cereale */
Create function fDecl112ActivAgricole
	(@dataJos datetime, @dataSus datetime, @lm char(9), @ContCASSAgricol char(30), @ContImpozitAgricol char(30))
returns @date112 table
	(Data datetime, Tip_contributie char(2), CNP char(13), Nume char(200), Casa_sanatate char(2), Baza decimal(10), Contributie decimal(10))
as  
Begin
	declare @Sub char(9), @ValidareJudetTerti int, @procCASS float, @procImpozit float
	
	select @Sub=dbo.iauParA('GE','SUBPRO')
	select @ValidareJudetTerti=dbo.iauParL('GE','JUDTERTI')
	set @procCASS=dbo.iauParLN(@dataSus,'PS','CASSIND')
	set @procImpozit=16

	if exists (select 1 from sysobjects where [type]='TF' and [name]='fDecl112ActivAgricoleSP')
		insert into @date112
		select * from fDecl112ActivAgricoleSP (@dataJos, @dataSus, @lm, @ContCASSAgricol, @ContImpozitAgricol)
	else 
	Begin
		insert into @date112
		select @dataSus, 'IM' as Tip_contributie, (case when isnull(c.Valoare,'')<>'' then isnull(c.Valoare,'') else left(rtrim(t.Cod_fiscal),13) end) as cnp,
			max(t.Denumire) as Nume, '' as Casa_sanatate, sum(f.Valoare) as Baza, sum(p.Suma) as Contributie
		from pozplin p
			left outer join terti t on p.Subunitate=t.Subunitate and p.Tert=t.Tert
			left outer join facturi f on f.Subunitate=p.Subunitate and f.Factura=p.Factura and f.Tert=p.Tert and f.Tip=0x54
			left outer join proprietati c on c.tip='TERT' and c.cod_proprietate='CNPTERTPFA' and c.Cod=p.Tert and c.Valoare<>''			
		where p.Subunitate=@Sub and p.Data between @dataJos and @dataSus and p.Plata_incasare='PF' and p.Cont=@ContImpozitAgricol
		Group by (case when isnull(c.Valoare,'')<>'' then isnull(c.Valoare,'') else left(rtrim(t.Cod_fiscal),13) end)
		union all
		select @dataSus, 'AS' as Tip_contributie, (case when isnull(c.Valoare,'')<>'' then isnull(c.Valoare,'') else left(rtrim(t.Cod_fiscal),13) end) as CNP, max(t.Denumire) as Nume, 
			max((case when isnull(cs.Valoare,'')='' and @ValidareJudetTerti=1 then t.Judet else isnull(cs.Valoare,'') end)) as Casa_sanatate, 
			(case when abs(sum(f.Valoare)-sum(p.Suma)*100/@procCASS)>10 then round(sum(p.Suma)*100/@procCASS,0) else sum(f.Valoare) end) as Baza, sum(p.Suma) as Contributie
		from pozplin p
			left outer join terti t on p.Subunitate=t.Subunitate and p.Tert=t.Tert
			left outer join facturi f on f.Subunitate=p.Subunitate and f.Factura=p.Factura and f.Tert=p.Tert and f.Tip=0x54
			left outer join proprietati cs on cs.tip='TERT' and cs.cod_proprietate='CASASANATATE' and cs.Cod=p.Tert and cs.Valoare<>''
			left outer join proprietati c on c.tip='TERT' and c.cod_proprietate='CNPTERTPFA' and c.Cod=p.Tert and c.Valoare<>''
		where p.Subunitate=@Sub and p.Data between @dataJos and @dataSus and p.Plata_incasare='PF' and p.Cont=@ContCASSAgricol
		Group by (case when isnull(c.Valoare,'')<>'' then isnull(c.Valoare,'') else left(rtrim(t.Cod_fiscal),13) end)
	End

	return
End

/*
	select * from fDecl112ActivAgricole ('07/01/2012', '07/31/2012', '', '4478', '4471') order by cnp, tip_contributie
	WHERE tip_contributie='AS'
*/
