--***
Create procedure wScriuResal @sesiune varchar(50), @parXML xml 
as
declare @tip varchar(2), @subtip varchar(2), @data datetime, @o_marca varchar(6), @marca varchar(6), 
@o_codbenef varchar(13), @Cod_beneficiar varchar(13), @o_nrdoc varchar(10), @Numar_document varchar(10), 
@Data_document datetime, @Valoare_totala_pe_doc float, @Retinere_progr_la_avans float, @Retinere_progr_la_lichidare float, @Procent_progr_la_lichidare float, @codac varchar(20), @explicatii varchar(40), 
@densalariat varchar(50), @denlm varchar(30), @denfunctie varchar(30), @salarincadrare float, @userASiS varchar(20), 
@docXML xml, @docXMLIaDLSalarii xml, @eroare xml, @mesaj varchar(254), @ptupdate int, @dataj datetime, @datas datetime

begin try
	--BEGIN TRAN
	select @subtip=xA.row.value('@subtip', 'varchar(2)') from @parXML.nodes('row') as xA(row) 	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuResalSP')
		exec wScriuResalSP @sesiune, @parXML OUTPUT
	exec wValidareResal @sesiune, @parXML 
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crsResal cursor for
	select isnull(tip, '') as tip, 
	isnull(data,'01/01/1901') as data, isnull(o_marca, isnull(marca, '')) as o_marca, 
	(case when isnull(marca, '')='' then isnull(marca_poz, '') else isnull(marca, '') end) as marca, 
	isnull(o_codbenef, isnull(Cod_beneficiar, '')) as o_codbenef, 
	(case when isnull(Cod_beneficiar, '')='' then isnull(Cod_beneficiar_poz, '') else isnull(Cod_beneficiar, '') end) as Cod_beneficiar, 
	isnull(o_nrdoc, '') as o_nrdoc, 
	isnull(Numar_document, '') as Numar_document, 
	isnull(dbo.bom(Data_document),'01/01/1901') as Data_document, 
	isnull(Valoare_totala_pe_doc,0) as Valoare_totala_pe_doc, 
	isnull(Retinere_progr_la_avans,0) as Retinere_progr_la_avans,
	isnull(Retinere_progr_la_lichidare,0) as Retinere_progr_la_lichidare,
	isnull(Procent_progr_la_lichidare,0) as Procent_progr_la_lichidare,
	isnull(explicatii,'') as explicatii, 
	isnull(densalariat,'') as densalariat, 
	isnull(denlm,'') as denlm,
	isnull(denfunctie,'') as denfunctie,
	isnull(salarincadrare,0) as salarincadrare,
	isnull(ptupdate,0) as ptupdate
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		tip char(40) '../@tip', 
		data datetime '../@data',
		o_marca varchar(6) '@o_marca', 
		marca char(6) '../@marca', 
		marca_poz char(6) '@marca', 
		o_codbenef char(13) '@o_codbenef', 
		Cod_beneficiar char(13) '../@codbenef', 
		Cod_beneficiar_poz char(13) '@codbenef', 
		o_nrdoc char(10) '@o_nrdoc', 
		Numar_document char(10) '@nrdoc', 
		Data_document datetime '../@data', 
		Valoare_totala_pe_doc float '@valtotala',
		Retinere_progr_la_avans float '@progravans',
		Retinere_progr_la_lichidare float '@progrlich',
		Procent_progr_la_lichidare float '@procent',
		explicatii char(40) '@explicatii', 
		densalariat char(50) '../@densalariat', 
		denlm char(30) '../@denlm', 
		denfunctie char(30) '../@denfunctie', 
		salarincadrare float '../@salarincadrare',
		ptupdate int '@update' 
	)

	open crsResal
	fetch next from crsResal into @tip, @data, @o_marca, @marca, @o_codbenef, @Cod_beneficiar, @o_nrdoc, @Numar_document, 
	@Data_document, @Valoare_totala_pe_doc, @Retinere_progr_la_avans, @Retinere_progr_la_lichidare, 
	@Procent_progr_la_lichidare, @explicatii, @densalariat, @denlm, @denfunctie, @salarincadrare, @ptupdate
	while @@fetch_status=0
	begin
		if isnull(@Numar_document,'')=''
		begin
			declare @UltNrDoc int
			exec luare_date_par 'PS','NRDOCRET', 0, @UltNrDoc OUTPUT, ''
			set @UltNrDoc=@UltNrDoc+1
			set @Numar_document=cast(@UltNrDoc as char(10))
			exec setare_par 'PS','NRDOCRET', 'Ultimul nr. de document generat', 1, @UltNrDoc, ''
		end

		if @ptupdate=1 and (@marca<>@o_marca or @cod_beneficiar<>@o_codbenef or @Numar_document<>@o_nrdoc)
			delete from resal where Data=@Data and Marca=@o_marca and cod_beneficiar=@o_codbenef and Numar_document=@o_nrdoc

		exec scriuResal @data, @marca, @Cod_beneficiar, @Numar_document, @Data_document, @Valoare_totala_pe_doc, 0, 
		@Retinere_progr_la_avans, @Retinere_progr_la_lichidare, @Procent_progr_la_lichidare, 0, 0

		select @dataj=dbo.bom(@data), @datas=dbo.eom(@data)
--		nu apelez momentan procedura de calcul retineri intrucat daca nu exista sume in brut si net, nu da nici un efect.	
--		exec calcul_retineri_si_rest_plata @dataj, @data, @Marca, ''

		exec scriuistPers @DataJos=@dataj, @DataSus=@datas, @pMarca=@marca, @pLocm='', @Stergere=0, @Scriere=1
		
		fetch next from crsResal into @tip, @data, @o_marca, @marca, @o_codbenef, @Cod_beneficiar, @o_nrdoc, @Numar_document, 
		@Data_document, @Valoare_totala_pe_doc, @Retinere_progr_la_avans, @Retinere_progr_la_lichidare, 
		@Procent_progr_la_lichidare, @explicatii, @densalariat, @denlm, @denfunctie, @salarincadrare, @ptupdate
	end
	set @docXMLIaDLSalarii='<row tip="'+rtrim(@tip)+'" codbenef="'+rtrim(@cod_beneficiar)+'" marca="'+rtrim(@marca)+'" data="'+convert(char(10),@data,101)
		+'" densalariat="'+rtrim(@densalariat)+'" denlm="'+rtrim(@denlm)+'" denfunctie="'+rtrim(@denfunctie)+'" salarincadrare="'+ rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'"/>'
	exec wIaPozSalarii @sesiune=@sesiune, @parXML=@docXMLIaDLSalarii 
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
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crsResal' and session_id=@@SPID )
if @cursorStatus=1 
	close crsResal 
if @cursorStatus is not null 
	deallocate crsResal 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
