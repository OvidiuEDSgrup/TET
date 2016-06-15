--***
create procedure wIaNomenclator @sesiune varchar(50), @parXML XML
as
begin try
	if exists(select * from sysobjects where name='wIaNomenclatorSP' and type='P')
		exec wIaNomenclatorSP @sesiune, @parXML 
	else      
	begin
	set transaction isolation level READ UNCOMMITTED

	Declare @filtruCod varchar(100), @filtruCodbare varchar(100), @filtruDenumire varchar(100), @filtruTipNomenclator varchar(1),  @filtruGrupa varchar(13), 
	@filtruFurnizor varchar(13), @filtruGestiune varchar(13) ,@filtruStocJ decimal(13,2), @filtruStocS decimal(13,2),@mesaj_eroare varchar(500),
	@gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int, @cSub char(9), @utilizator varchar(20),@preturi int, @faraU bit,
	@areDetalii bit, @filtruCont varchar(20), @filtruCodGrupa varchar(40), @filtruUM varchar(10), @filtruInvalid varchar(2), @invalid bit

	Set @filtruCod = isnull(@parXML.value('(/row/@cod)[1]','varchar(80)'),'')
	Set @filtruCodbare = isnull(@parXML.value('(/row/@codbare)[1]','varchar(100)'),'')
	Set @filtruDenumire = isnull(@parXML.value('(/row/@denumire)[1]','varchar(80)'),'')
	Set @filtruTipNomenclator = isnull(@parXML.value('(/row/@ftip)[1]','varchar(80)'),'')
	Set @filtruCodGrupa = isnull(@parXML.value('(/row/@codgrupa)[1]', 'varchar(40)'), '')
	Set @filtruGrupa = isnull(@parXML.value('(/row/@dengrupa)[1]','varchar(80)'),'')
	Set @filtruCont = isnull(@parXML.value('(/row/@cont)[1]','varchar(20)'),'')
	Set @filtruStocJ = ISNULL(@parXML.value('(/row/@stocj)[1]','decimal(14,3)'),-99999999999)
	Set @filtruStocS = ISNULL(@parXML.value('(/row/@stocs)[1]','decimal(14,3)'),99999999999)
	Set @filtruUM = ISNULL(@parXML.value('(/row/@um)[1]', 'varchar(10)'), '')
	Set @filtruInvalid = ISNULL(@parXML.value('(/row/@invalid)[1]', 'varchar(2)'), '')

	exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output
	exec luare_date_par 'GE','PRETURI', @Preturi output, 0, ''--setarea se lucreaza cu tabela de preturi
	exec luare_date_par 'GE', 'FARATIPU',  @faraU output,0,''
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	if OBJECT_ID('tempdb..#wNomencl') is not null
		drop table #wNomencl
		
	set @gestiune=''
	set @gestutiliz=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and cod_proprietate='GESTIUNE' and cod=@utilizator),'')
	if @gestutiliz <> '' 
		set @gestiune=@gestutiliz
	set @categoriePret=isnull((select valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz),'1')

	set @filtrudenumire=Replace(@filtrudenumire,' ','%')
	set @invalid = (case when @filtruInvalid in ('da', 'd') then 1 else 0 end)

	select top 100 rtrim(nomencl.cod) as cod
	into #n100
	from nomencl 
	left outer join grupe on nomencl.grupa=grupe.grupa
	left outer join um on nomencl.um = um.um
	where
		nomencl.cod like @filtruCod+'%' 
		and nomencl.denumire like '%'+@filtruDenumire+'%'
		and nomencl.tip like @filtruTipNomenclator+'%'
		and rtrim(isnull(grupe.Denumire,nomencl.grupa)) like '%'+@filtruGrupa+'%'
		and (@faraU=0 or nomencl.Tip<>'U') 
		and (@filtruCodbare='' or exists (select * from codbare c where nomencl.cod=c.Cod_produs and	 c.Cod_de_bare like '%'+@filtruCodbare+'%'))
		and (@filtruCont='' OR nomencl.Cont LIKE '%'+@filtruCont+'%')
		and (@filtruCodGrupa = '' OR rtrim(isnull(grupe.grupa, nomencl.Grupa)) like '%' + @filtruCodGrupa + '%')
		and (@filtruUM = '' OR rtrim(nomencl.um) like '%' + @filtruUM + '%' or rtrim(um.denumire) like '%' + @filtruUM + '%')
		and (@invalid = 0 OR (@invalid = 1 and getdate() between nomencl.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime')
			and nomencl.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime')))

	select s.cod,sum(s.stoc) as stoc,sum(case when gFiltru.valoare is null then 0 else s.stoc end) as stocpropriu
	into #stocpecod
	from stocuri s 
		inner join #n100 on s.cod=#n100.cod
		left outer join proprietati gFiltru on gFiltru.tip='UTILIZATOR' and gFiltru.cod_proprietate='GESTIUNE' and gFiltru.cod=@utilizator and s.Cod_gestiune=gFiltru.Valoare
	group by s.cod

	--luare preturi din tabela de preturi cu wIaPreturi
	create table #preturi(cod varchar(20),nestlevel int)
	insert into #preturi
	select cod,@@NESTLEVEL
	from #n100 

	exec CreazaDiezPreturi
	exec wIaPreturi @sesiune,@parXMl

	select (
		case when @filtruCod<>'' then space(20-LEN(n.cod))+n.cod
			 else null
		end)
		as o,
		rtrim(n.cod) as cod,n.tip, dbo.denTipNomenclator(n.tip) as dentip,rtrim(n.grupa) as grupa,rtrim(n.denumire) as denumire,rtrim(n.um) as um,
		isnull(rtrim(terti.Denumire),'') as furnizor, rtrim(n.Tip_echipament) as observatii,
		convert(decimal(12,3),isnull(isnull(p.Pret_amanunt_discountat, n.pret_cu_amanuntul), 0)) as pret,
		convert(decimal(12,3),isnull(isnull(p.Pret_vanzare_discountat, n.Pret_vanzare), 0)) as pretvanzare,
		convert(decimal(12,3),n.Pret_vanzare) as pretvanznom,
		isnull(RTRIM(um.Denumire),'') as denum, rtrim(isnull(grupe.Denumire,n.grupa)) as dengrupa,
		rtrim(n.cont) as cont, convert(varchar(6),n.cota_tva) as cotatva, 
		rtrim(n.cont)+'-'+RTRIM(ISNULL(conturi.denumire_cont,'')) as dencont,
		convert(decimal(12,3),n.pret_stoc) as pret_stocn,
		convert(decimal(12,3),isnull(s.stoc,0)) as stoc,
		convert(decimal(12,3),isnull(s.stocpropriu,0)) as stocpropriu,
		(select top 1 rtrim(Cod_de_bare) from codbare where Cod_produs=n.cod) as codbare,
		rtrim(n.Loc_de_munca) as note,
		convert(decimal(12,3),sl.Stoc_min) as stocmin, 
		convert(decimal(12,3),sl.Stoc_max) as stocmax,
		rtrim(n.valuta) as valuta,
		CONVERT(decimal(15,2),n.greutate_specifica) greutate,
		rtrim(n.categorie) as categorie,
		case when RTRIM(n.UM_2)='Y' then 1 else 0 end as areserii, 
		(case 
			when getdate() between n.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime') and n.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime') then '#0000FF'
			when n.tip not in ('R','S','F') and s.stoc is null then '#808080' -- fara stoc
			when n.tip not in ('R','S','F') and s.stoc<0 then'#FF0000' -- stoc negativ
			else '#000000' end)  as culoare,
		convert(decimal(17,5),coeficient_conversie_1) as coeficient_conversie_1,
		rtrim(um_1) as um_1,
		convert(decimal(17,5),coeficient_conversie_2) as coeficient_conversie_2,
		rtrim(um_2) as um_2
		into #wNomencl
	from Nomencl n 
		inner join #n100 on n.cod=#n100.cod
		left outer join #stocpecod s on s.cod=n.cod
		left outer join grupe on n.grupa=grupe.grupa
		left outer join conturi on conturi.Subunitate = @cSub and conturi.Cont = n.cont
		left outer join terti on terti.Subunitate = @cSub and terti.tert = n.furnizor
		left outer join um on n.um=um.UM
		left outer join #preturi p on n.cod=p.cod
		left outer join stoclim sl on n.cod=sl.cod and sl.subunitate='1' and sl.Cod_gestiune=''
	where isnull(s.stoc,0) between @filtruStocJ and @filtruStocS
	order by o, patindex('%'+@filtruDenumire+'%', n.denumire), n.denumire
	
	IF EXISTS (
		SELECT 1
		FROM syscolumns sc, sysobjects so
		WHERE so.id = sc.id
			AND so.NAME = 'nomencl'
			AND sc.NAME = 'detalii'
		)
	BEGIN
		SET @areDetalii = 1

		ALTER TABLE #wNomencl ADD detalii XML
		
		update #wNomencl  set detalii= n.detalii
		from nomencl n 
		inner join #n100 nn	on nn.cod=n.Cod  
		where n.Cod=#wNomencl.cod
	END
	ELSE
		SET @areDetalii = 0
	
	
	select * from #wNomencl for xml raw, root('Date')
	
	select @areDetalii as areDetaliiXml for xml raw,root('Mesaje')
	drop table #n100
	drop table #stocpecod
	end
end try
begin catch
set @mesaj_eroare=ERROR_MESSAGE()
raiserror(@mesaj_eroare,11,1)
end catch	

/*
select * from nomencl
*/
