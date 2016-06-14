drop procedure [dbo].[wIaNomenclatorSP] 
go
create procedure [dbo].[wIaNomenclatorSP] @sesiune varchar(50), @parXML XML
as
begin try
	if exists(select * from sysobjects where name='yso_wIaNomenclatorSP' and type='P')
		exec yso_wIaNomenclatorSP @sesiune, @parXML 
	else      
	begin
	set transaction isolation level READ UNCOMMITTED

	Declare @filtruCod varchar(100), @filtruDenumire varchar(100), @filtruTipNomenclator varchar(1),  @filtruGrupa varchar(13), 
	@filtruFurnizor varchar(13), @filtruGestiune varchar(13) ,@filtruStocJ decimal(13,2), @filtruStocS decimal(13,2),@mesaj_eroare varchar(500),
	@gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int, @cSub char(9), @utilizator varchar(20),@preturi int

	Set @filtruCod = isnull(@parXML.value('(/row/@cod)[1]','varchar(80)'),'')
	Set @filtruDenumire = isnull(@parXML.value('(/row/@denumire)[1]','varchar(80)'),'')
	Set @filtruTipNomenclator = isnull(@parXML.value('(/row/@ftip)[1]','varchar(80)'),'')
	Set @filtruGrupa = isnull(@parXML.value('(/row/@dengrupa)[1]','varchar(80)'),'')
	--Set @filtruFurnizor = ISNULL(@parXML.value('(/row/@furnizor)[1]','varchar(80)'),'')
	--Set @filtruGestiune = ISNULL(@parXML.value('(/row/@gestiune)[1]','varchar(80)'),'')
	Set @filtruStocJ = ISNULL(@parXML.value('(/row/@stocj)[1]','decimal(14,3)'),-99999999999)
	Set @filtruStocS = ISNULL(@parXML.value('(/row/@stocs)[1]','decimal(14,3)'),99999999999)

	exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output
	exec luare_date_par 'GE','PRETURI', @Preturi output, 0, ''--setarea se lucreaza cu tabela de preturi

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT


	set @gestiune=''
	set @gestutiliz=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTIUNE' and cod=@utilizator),'')
	if @gestutiliz <> '' 
		set @gestiune=@gestutiliz
	set @categoriePret=isnull((select valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz),'1')

	set @filtrudenumire=Replace(@filtrudenumire,' ','%')

	select top 100 rtrim(nomencl.cod) as cod
	into #n100
	from nomencl 
		left outer join grupe on nomencl.grupa=grupe.grupa
	where
		nomencl.cod like @filtruCod+'%' 
		and nomencl.denumire like '%'+@filtruDenumire+'%'
		and nomencl.tip like @filtruTipNomenclator+'%'
		and rtrim(isnull(grupe.Denumire,nomencl.grupa)) like '%'+@filtruGrupa+'%'

	select s.cod,sum(s.stoc) as stoc,sum(case when gFiltru.valoare is null then 0 else s.stoc end) as stocpropriu
	into #stocpecod
	from stocuri s 
		inner join #n100 on s.cod=#n100.cod
		left outer join proprietati gFiltru on gFiltru.tip='UTILIZATOR' and gFiltru.cod_proprietate='GESTIUNE' and gFiltru.cod=@utilizator and s.Cod_gestiune=gFiltru.Valoare
	group by s.cod

	select (
		case when @filtruCod<>'' then space(20-LEN(n.cod))+n.cod
			 else ''
		end)
		as o,
		rtrim(n.cod) as cod,n.tip, dbo.denTipNomenclator(n.tip) as dentip,rtrim(n.grupa) as grupa,rtrim(n.denumire) as denumire,rtrim(n.um) as um,
		isnull(rtrim(terti.Denumire),'') as furnizor, rtrim(n.Tip_echipament) as observatii,
		convert(decimal(12,3),isnull(isnull(pretCat.Pret_cu_amanuntul, isnull(PretImplicit.Pret_cu_amanuntul, n.pret_cu_amanuntul)), 0)) as pret,
		convert(decimal(12,3),isnull(isnull(pretCat.Pret_vanzare, isnull(PretImplicit.Pret_vanzare, n.Pret_vanzare)), 0)) as pretvanzare,
		convert(decimal(12,3),n.Pret_vanzare) as pretvanznom,
		isnull(RTRIM(um.Denumire),'') as denum, rtrim(isnull(grupe.Denumire,n.grupa)) as dengrupa,
		rtrim(n.cont) as cont, convert(decimal(12,3),n.cota_tva) as cotatva, 
		rtrim(n.cont)+'-'+RTRIM(ISNULL(conturi.denumire_cont,'')) as dencont,
		convert(decimal(12,3),n.pret_stoc) as pret_stocn,
		convert(decimal(12,3),isnull(s.stoc,0)) as stoc,
		convert(decimal(12,3),isnull(s.stocpropriu,0)) as stocpropriu,
		pozeria.fisier as poza, --rog lasati fara isnull
		(select top 1 rtrim(Cod_de_bare) from codbare where Cod_produs=n.cod) as codbare, GETDATE() as data, rtrim(n.cod) as numar
	from Nomencl n 
		inner join #n100 on n.cod=#n100.cod
		left outer join #stocpecod s on s.cod=n.cod
		left outer join grupe on n.grupa=grupe.grupa
		left outer join conturi on conturi.Subunitate = @cSub and conturi.Cont = n.cont
		left outer join terti on terti.Subunitate = @cSub and terti.tert = n.furnizor
		left outer join um on n.um=um.UM
		left join preturi pretCat on pretCat.Cod_produs=n.Cod and pretCat.um=@categoriePret and pretCat.Tip_pret=1 and pretCat.Data_superioara='2999-01-01' and @preturi=1
		left join preturi PretImplicit on PretImplicit.Cod_produs=n.Cod and PretImplicit.um=1 and PretImplicit.Tip_pret=1 and PretImplicit.Data_superioara='2999-01-01' and @preturi=1
		left outer join PozeRIA on pozeria.tip='N' and pozeria.cod=n.cod
	where isnull(s.stoc,0) between @filtruStocJ and @filtruStocS
	order by o, patindex('%'+@filtruDenumire+'%', n.denumire), n.denumire
	for xml raw

	drop table #n100
	drop table #stocpecod
	end
end try
begin catch
set @mesaj_eroare=ERROR_MESSAGE()
raiserror(@mesaj_eroare,11,1)
end catch	