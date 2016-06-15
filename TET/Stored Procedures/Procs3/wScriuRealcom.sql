--***
Create 
procedure wScriuRealcom @sesiune varchar(50), @parXML xml 
as
declare @tip varchar(2), @subtip varchar(2), @data datetime, @datajos datetime, @datasus datetime, @lmantet varchar(9), @marca varchar(6), @marca_veche varchar(6), 
@loc_de_munca varchar(9), @loc_de_munca_vechi varchar(9), @bonuriregie int, 
@numar_document varchar(20), @numar_document_vechi varchar(20), 
@datadoc datetime, @datadoc_veche datetime, @comanda varchar(20), @comanda_veche varchar(20), @cod_reper varchar(20), @cod_operatie varchar(20), 
@cantitate decimal(10,3), @categoria_salarizare varchar(4), @norma_de_timp decimal(13,6), @tarif_unitar decimal(12,5), 
@densalariat varchar(50), @denlmantet varchar(30), @denfunctie varchar(30), @salarincadrare float, 
@Bugetari int, @OreLuna int, @NrMedOl decimal(6,3),
@userASiS varchar(20), @docXML xml, @docXMLIaDLSalarii xml, @eroare xml, @mesaj varchar(254), @ptupdate int

begin try
	--BEGIN TRAN
	set @Bugetari=dbo.iauParL('PS','UNITBUGET')
	select @lmantet=xA.row.value('@lmantet', 'varchar(9)') from @parXML.nodes('row') as xA(row)
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuRealcomSP')
		exec wScriuRealcomSP @sesiune, @parXML OUTPUT
	exec wValidareRealcom @sesiune, @parXML
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crsRealcom cursor for
	select isnull(tip, '') as tip, isnull(subtip, '') as subtip, isnull(data, '01/01/1901') as data, 
	isnull(Marca_veche, isnull(marca, '')) as Marca_veche, 
	(case when isnull(marca, '')='' then isnull(marca_poz, '') else isnull(marca, '') end) as Marca, 
	isnull(bonuriregie, 0) as bonuriregie, 
	(case when isnull(lm, '')='' then isnull(loc_de_munca, '') else isnull(lm, '') end) as loc_de_munca, 
	isnull(loc_de_munca_vechi, '') as loc_de_munca_vechi, 
	isnull(numar_document, '') as numar_document, 
	isnull(numar_document_vechi, '') as numar_document_vechi, 
	isnull(datadoc, isnull(data,'01/01/1901')) as datadoc, 
	isnull(datadoc_veche, '01/01/1901') as datadoc_veche, 
	isnull(comanda, '') as comanda, 
	isnull(comanda_veche, '') as comanda_veche, 
	isnull(cod_reper, '') as cod_reper, 
	isnull(cod_operatie, '') as cod_operatie, 
	isnull(cantitate, 0) as cantitate, 
	isnull(categoria_salarizare, '') as categoria_salarizare, 
	isnull(norma_de_timp, 0) as norma_de_timp, 
	isnull(tarif_unitar, 0) as tarif_unitar,
	isnull(densalariat,'') as densalariat, 
	isnull(denlmantet,'') as denlmantet,
	isnull(salarincadrare,0) as salarincadrare, 
	isnull(ptupdate, 0) as ptupdate
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		tip varchar(2) '../@tip',
		subtip varchar(2) '@subtip',
		data datetime '../@data',
		marca_veche varchar(6) '@o_marca',
		marca varchar(6) '../@marca',
		marca_poz varchar(6) '@marca',
		bonuriregie int '@bonuriregie',
		loc_de_munca varchar(9) '../@lmantet',
		lm varchar(9) '@lm',
		loc_de_munca_vechi varchar(9) '@o_lm',
		numar_document varchar(20) '@nrdoc',
		numar_document_vechi varchar(20) '@o_nrdoc',
		datadoc datetime '@datadoc',
		datadoc_veche datetime '@o_datadoc',
		comanda varchar(20) '@comanda',
		comanda_veche varchar(20) '@o_comanda',
		cod_reper varchar(20) '@codtehn',
		cod_operatie varchar(20) '@codoperatie',
		cantitate decimal(10,3) '@cantitate',
		categoria_salarizare varchar(4) '@categsal',
		norma_de_timp float '@normatimp', 
		tarif_unitar float '@tarifunitar',
		densalariat varchar(50) '../@densalariat', 
		denlmantet varchar(30) '../@denlmantet', 
		denfunctie varchar(30) '../@denfunctie', 
		salarincadrare float '../@salarincadrare', 
		ptupdate int '@update'
	)

	open crsRealcom
	fetch next from crsRealcom into @tip, @subtip, @data, @marca_veche, @marca, @bonuriregie, @loc_de_munca, @loc_de_munca_vechi, 
	@numar_document, @numar_document_vechi, @datadoc, @datadoc_veche, @comanda, @comanda_veche, @cod_reper, 
	@cod_operatie, @cantitate, @categoria_salarizare, @norma_de_timp, @tarif_unitar,
	@densalariat, @denlmantet, @salarincadrare, @ptupdate
	while @@fetch_status=0
	begin
		select @datajos=dbo.bom(@datadoc), @datasus=dbo.eom(@datadoc)
		if isnull(@numar_document,'')=''
			begin
				declare @UltNrDoc int
				set @UltNrDoc=isnull((select top 1 cast((case when @marca<>'' then substring(numar_document,3,18) else numar_document end) as int)
				from realcom
				where data between @datajos and @datasus and (@marca<>'' and marca<>'' or @marca='' and marca='')
				order by (case when @marca<>'' then convert(float,substring(numar_document,3,18)) else convert(float,numar_document) end) desc),0)
				set @UltNrDoc=@UltNrDoc+1
				set @numar_document=(case when @tip ='AI' or @subtip='MN' then 'PS' else '' end)+cast(@UltNrDoc as char(13)) -- Tratat subtip MN sa prefixeze cu PS
			end
		set @categoria_salarizare=(case when @bonuriregie=1 then '1' else '' end)
		set @OreLuna=dbo.iauParLN(@data,'PS','ORE_LUNA')
		set @NrMedOl=dbo.iauParLN(@data,'PS','NRMEDOL')
		
		if @subtip='MN'				-- Pentru macheta de realizari machete (subtip MN) sa calculeze pretul unitar daca nu este introdus
			set @bonuriregie=1

		if @ptupdate=0 and @cod_reper<>'' and @cod_operatie<>'' and @norma_de_timp=0
			select @norma_de_timp=Norma_timp from tehnpoz where Cod_tehn=@cod_reper and Cod=@cod_operatie
		if @ptupdate=0 and @bonuriregie=0 and @cod_reper<>'' and @cod_operatie<>'' and @tarif_unitar=0 
			select @tarif_unitar=isnull(Tarif_unitar,@tarif_unitar)
				from tehnpoz where Cod_tehn=@cod_reper and Cod=@cod_operatie
		if @ptupdate=0 and @bonuriregie=1 and @marca<>'' and @tarif_unitar=0
			select @tarif_unitar=round(convert(decimal(13,5),(case when @bugetari=1 then salar_de_baza else salar_de_incadrare end)/
				((case when tip_salarizare in ('1','2') then @OreLuna else @NrMedOL end)*(case when salar_lunar_de_baza=0 then 8 else salar_lunar_de_baza end)/8)),5)
			from personal where marca=@marca
		if @ptupdate=1 and (@marca<>@marca_veche or @datadoc<>@datadoc_veche or @loc_de_munca<>@loc_de_munca_vechi or @comanda<>@comanda_veche 
			or @numar_document<>@numar_document_vechi)
			delete from Realcom where Data=@datadoc and Marca=@marca_veche and Loc_de_munca=@Loc_de_munca_vechi and 
			Comanda=@Comanda and Numar_document=@Numar_document_vechi

		exec scriuRealcom @marca, @loc_de_munca, @numar_document, @datadoc, @comanda, @cod_reper, @cod_operatie, 
		@cantitate, @categoria_salarizare, @norma_de_timp, @tarif_unitar

		fetch next from crsRealcom into @tip, @subtip, @data, @marca_veche, @marca, @bonuriregie, @loc_de_munca, @loc_de_munca_vechi, 
		@numar_document, @numar_document_vechi, @datadoc, @datadoc_veche, @comanda, @comanda_veche, @cod_reper, 
		@cod_operatie, @cantitate, @categoria_salarizare, @norma_de_timp, @tarif_unitar,
		@densalariat, @denlmantet, @salarincadrare, @ptupdate
	end
	set @docXMLIaDLSalarii='<row tip="'+rtrim(@tip)+'" subtip="'+rtrim(@subtip)+'" marca="'+rtrim(@marca)
	+'" data="'+convert(char(10),@data,101)+'" lmantet="'+rtrim(@lmantet)+'" densalariat="'+ rtrim(@densalariat)+'" denlmantet="'+rtrim(@denlmantet)+'" salarincadrare="'+ rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'"/>'
	exec wIaPozRealcom @sesiune=@sesiune, @parXML=@docXMLIaDLSalarii 
	--COMMIT TRAN
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0)=0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
--
declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crsRealcom' and session_id=@@SPID )
if @cursorStatus=1 
	close crsRealcom 
if @cursorStatus is not null 
	deallocate crsRealcom 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
