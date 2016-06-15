--***
Create 
procedure wScriuTichete @sesiune varchar(50), @parXML xml 
as
declare @o_marca varchar(6), @marca varchar(6), @data datetime, @datalunii1 datetime, @tip varchar(40), @lmantet varchar(9), 
@o_tip_operatie char(1), @tip_operatie char(1), @o_serie_inceput varchar(13), @serie_inceput varchar(13), @serie_sfarsit varchar(13), 
@nr_tichete int, @valoare_tichet float, @densalariat varchar(50), @denlmantet varchar(30), @denfunctie varchar(30), 
@salarincadrare decimal(10), @userASiS varchar(20), @pValTichet decimal(7,2),
@docXML xml, @docXMLIaDLSalarii xml, @eroare xml, @mesaj varchar(254), @ptupdate int

begin try
	--BEGIN TRAN
	select @lmantet=xA.row.value('@lmantet', 'varchar(9)') from @parXML.nodes('row') as xA(row) 	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuTicheteSP')
		exec wScriuTicheteSP @sesiune, @parXML OUTPUT
	exec wValidareTichete @sesiune, @parXML
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crsTichete cursor for
	select isnull(tip, '') as tip, isnull(o_marca, isnull(marca, '')) as o_marca, 
	(case when isnull(marca, '')='' then isnull(marca_poz, '') else isnull(marca, '') end) as marca, 
	isnull(data, '01/01/1901') as data, 
	isnull(o_tip_operatie, '') as o_tip_operatie,
	isnull(tip_operatie, '') as tip_operatie,
	isnull(o_serie_inceput, '') as o_serie_inceput,
	isnull(serie_inceput, '') as serie_inceput,
	isnull(serie_sfarsit, '') as serie_sfarsit,
	isnull(nr_tichete, 0) as nr_tichete,
	isnull(valoare_tichet, 0) as valoare_tichet,
	isnull(densalariat,'') as densalariat,
	isnull(denlmantet,'') as denlmantet,
	isnull(denfunctie,'') as denfunctie,
	isnull(salarincadrare,0) as salarincadrare,
	isnull(ptupdate, 0) as ptupdate
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		tip char(40) '../@tip', 
		o_marca varchar(6) '@o_marca', 
		marca varchar(6) '../@marca', 
		marca_poz varchar(6) '@marca', 
		data datetime '../@data', 
		o_tip_operatie char(1) '@o_tiptichet',
		tip_operatie char(1) '@tiptichet',
		o_serie_inceput float '@o_serieinceput',
		serie_inceput varchar(13) '@serieinceput',
		serie_sfarsit varchar(13) '@seriesfarsit',
		nr_tichete decimal(5) '@nrtichete', 
		valoare_tichet decimal(12,2) '@valtichet', 
		densalariat varchar(50) '../@densalariat', 
		denlmantet varchar(30) '../@denlmantet', 
		denfunctie varchar(30) '../@denfunctie', 
		salarincadrare float '../@salarincadrare', 
		ptupdate int '@update'
	)

	open crsTichete
	fetch next from crsTichete into @tip, @o_marca, @marca, @data, @o_tip_operatie, @tip_operatie, 
	@o_serie_inceput, @serie_inceput, @serie_sfarsit, @nr_tichete, @valoare_tichet, 
	@densalariat, @denlmantet, @denfunctie, @salarincadrare, @ptupdate
	while @@fetch_status=0
	begin
		select @datalunii1=dbo.BOM(@data), @data=dbo.EOM(@data)
		set @pValTichet=dbo.iauParLN(@data,'PS','VALTICHET')
		select @valoare_tichet=@pValTichet where @valoare_tichet=0 
		if @ptupdate=1 and (@marca<>@o_marca or @tip_operatie<>@o_tip_operatie or @serie_inceput<>@o_serie_inceput)
			delete from Tichete where Data_lunii=@Data and Marca=@o_marca and Tip_operatie=@o_tip_operatie and Serie_inceput=@o_serie_inceput

		exec scriuTichete @Marca, @Data, @Tip_operatie, @Serie_inceput, @Serie_sfarsit, @Nr_tichete, @Valoare_tichet, 0, 0

		exec scriuistPers @DataJos=@datalunii1, @DataSus=@data, @pMarca=@marca, @pLocm='', @Stergere=0, @Scriere=1

		fetch next from crsTichete into @tip, @o_marca, @marca, @data, @o_tip_operatie, @tip_operatie, 
		@o_serie_inceput, @serie_inceput, @serie_sfarsit, @nr_tichete, @valoare_tichet, 
		@densalariat, @denlmantet, @denfunctie, @salarincadrare, @ptupdate
	end
	set @docXMLIaDLSalarii='<row tip="'+rtrim(@tip)+'" marca="'+rtrim(@marca)+'" lmantet="' +rtrim(@lmantet)+'" data="'+convert(char(10),@data,101)+'" densalariat="'+ rtrim(@densalariat)+'" denlmantet="'+rtrim(@denlmantet)+'" denfunctie="'+rtrim(@denfunctie)+'" salarincadrare="'+ rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'"/>'
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
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crsTichete' and session_id=@@SPID )
if @cursorStatus=1 
	close crsTichete 
if @cursorStatus is not null 
	deallocate crsTichete 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
