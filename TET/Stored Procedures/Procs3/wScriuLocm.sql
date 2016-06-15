--***
CREATE procedure wScriuLocm @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @mesaj varchar(200), @detalii xml, @docDetalii xml, 
	@lm char(9), @referinta int, @tabReferinta int, @mesajEroare varchar(100)

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

IF OBJECT_ID('tempdb..#xmllm') IS NOT NULL drop table #xmllm
IF OBJECT_ID('tempdb..#proprietati') IS NOT NULL drop table #proprietati

begin try
	select isnull(ptupdate, 0) as ptupdate, upper(lm) as lm, isnull(lm_vechi, lm) as lm_vechi, upper(denumire) as denumire, nivel, upper(lm_parinte) as lm_parinte, 
	tip_comanda, upper(comanda) as comanda, centru, denumire_centru, isnull(id_domeniu,0) as id_domeniu, isnull(id_domeniu_vechi,0) as id_domeniu_vechi,
	isnull(ordinestat,'') as ordinestat, isnull(ordinestat_vechi,'') as ordinestat_vechi, isnull(codfiscal,'') as codfiscal, isnull(codfiscal_vechi,'') as codfiscal_vechi, detalii,
	isnull(lminchcont, 0) as lminchcont, isnull(lminchcont_vechi, 0) as lminchcont_vechi
	into #xmllm
	from OPENXML(@iDoc, '/row')
	WITH
	(
		detalii xml 'detalii',
		ptupdate int '@update', 
		lm char(9) '@lm', 
		lm_vechi char(9) '@o_lm', 
		denumire char(80) '@denlm', 
		nivel int '@nivel', 
		lm_parinte char(9) '@parinte', 
		tip_comanda char(1) '@tipcomanda', 
		comanda char(20) '@comanda', 
		centru char(6) '@centru', 
		denumire_centru char(20) '@dencentru',
		codfiscal varchar(20) '@codfiscal',
		codfiscal_vechi varchar(20) '@o_codfiscal',
		id_domeniu int '@id_domeniu',
		id_domeniu_vechi int '@o_id_domeniu',
		ordinestat int '@ordinestat',
		ordinestat_vechi int '@o_ordinestat',
		lminchcont bit '@lminchcont',
		lminchcont_vechi bit '@o_lminchcont'
	)
	exec sp_xml_removedocument @iDoc 

	-- salvarea detaliilor e tratata doar la importul unui singur loc de munca
	select top 1 @detalii = detalii from #xmllm

	if exists (select 1 from #xmllm where isnull(lm, '')='')
		raiserror('Cod necompletat', 16, 1)

	select @lm=x.lm
	from #xmllm x, lm
	where lm.cod=x.lm and (x.ptupdate=0 or x.ptupdate=1 and x.lm<>x.lm_vechi)
	if @lm is not null
	begin
		set @mesajEroare='Locul de munca ' + RTrim(@lm) + ' este deja introdus'
		raiserror(@mesajEroare, 16, 1)
	end
	
	select @referinta=dbo.wfReflm(x.lm_vechi), 
		@lm=(case when @referinta>0 and @lm is null then x.lm_vechi else @lm end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmllm x
	where x.ptupdate=1 and x.lm<>x.lm_vechi
	if @lm is not null
	begin
		set @mesajEroare='Locul de munca ' + RTrim(@lm) + ' are ' + (case @tabReferinta when 1 then 'descendenti' when 2 then 'inregistrari' else 'documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	update x
	set nivel=(case when x.ptupdate=0 or x.lm<>x.lm_vechi then isnull(s.nivel, 0) else null end)
	from #xmllm x
	left outer join strlm s on s.lungime=len(x.lm)
	
	select @lm=x.lm
	from #xmllm x
	where x.nivel=0
	if @lm is not null
	begin
		set @mesajEroare='Nu exista nivel corespunzator locului de munca ' + RTrim(@lm)
		raiserror(@mesajEroare, 16, 1)
	end
	
	update x
	set lm_parinte=isnull(lm.cod, '')
	from #xmllm x 
	left outer join strlm s on s.nivel=x.nivel-1
	left outer join lm on lm.cod=left(x.lm, s.lungime)
	where x.nivel>1
	
	select @lm=x.lm
	from #xmllm x
	where x.nivel>1 and isnull(x.lm_parinte, '')=''
	if @lm is not null
	begin
		set @mesajEroare='Nu exista locul de munca parinte pentru ' + RTrim(@lm)
		raiserror(@mesajEroare, 16, 1)
	end

	insert lm
	(Nivel, Cod, Cod_parinte, Denumire)
	select x.Nivel, x.lm, isnull(x.lm_parinte, ''), isnull(x.denumire, '')
	from #xmllm x
	where x.ptupdate=0

	select top 1 @lm=x.lm	from #xmllm x
	SET @docDetalii = (SELECT @lm as lm, 'lm' as tabel, @detalii for xml raw)
	exec wScriuDetalii  @parXML=@docDetalii
	
	insert speciflm
	(Loc_de_munca, Tipul_comenzii, Marca, Comanda)
	select
	x.lm, isnull(x.tip_comanda, ''), isnull(x.centru, ''), isnull(x.comanda, space(20))+isnull(x.denumire_centru, '')
	from #xmllm x
	where x.ptupdate=0

	update lm
	set nivel=isnull(x.nivel, lm.nivel), cod=isnull(x.lm, lm.cod), 
		Cod_parinte=isnull(x.lm_parinte, lm.cod_parinte), denumire=isnull(x.denumire, lm.denumire)
	from lm, #xmllm x
	where x.ptupdate=1 and lm.cod=x.lm_vechi
	
	update s
	set Loc_de_munca=isnull(x.lm, s.loc_de_munca), tipul_comenzii=isnull(x.tip_comanda, s.tipul_comenzii), 
		marca=isnull(x.centru, s.marca), comanda=isnull(x.comanda, left(s.comanda, 20))+isnull(x.denumire_centru, substring(s.comanda, 21, 40))
	from speciflm s, #xmllm x
	where x.ptupdate=1 and s.Loc_de_munca=x.lm_vechi

--	scriere domeniu/ordine stat de plata/personal ca si proprietate pe loc de munca
	declare @input XML
	select ptupdate, 'DOMENIU' as codproprietate, (case when id_domeniu=0 then '' else convert(char(10),id_domeniu) end) as valoare, 
		(case when id_domeniu_vechi=0 then '' else convert(char(10),id_domeniu_vechi) end) as o_valoare
	into #proprietati
	from #xmllm x
	union all 
	select ptupdate , 'ORDINESTAT' as codproprietate, (case when ordinestat=0 then '' else convert(char(10),ordinestat) end) as valoare, 
		(case when ordinestat_vechi=0 then '' else convert(char(10),ordinestat_vechi) end) as o_valoare
	from #xmllm x
	union all 
	select ptupdate , 'CODFISCAL' as codproprietate, codfiscal as valoare, codfiscal_vechi as o_valoare
	from #xmllm x
	union all
	select ptupdate, 'LMINCHCONT' as codproprietate, (case when lminchcont = 0 then '' else convert(char(1), lminchcont) end) as valoare,
		(case when lminchcont_vechi = 0 then '' else convert(char(1), lminchcont_vechi) end) as o_valoare
	from #xmllm x

	set @input=(select top 1 'LM' as '@tip', rtrim(lm) as '@cod', 
			--formare proprietati de scris
			(select ptupdate as '@update', codproprietate as '@codproprietate', valoare as '@valoare', o_valoare as '@o_valoare'
			from #proprietati x
			for XML path,type)
		from #xmllm x
		for xml Path,type)
--	de vazut ce se intampla daca nu am de trimis proprietati
	if exists (select 1 from #proprietati)
		exec wScriuProprietati @sesiune, @input	 
end try

begin catch
	set @mesaj = ('wScriuLocm: ')+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

IF OBJECT_ID('tempdb..#xmllm') IS NOT NULL drop table #xmllm
IF OBJECT_ID('tempdb..#proprietati') IS NOT NULL drop table #proprietati

--select @mesaj as mesajeroare for xml raw
