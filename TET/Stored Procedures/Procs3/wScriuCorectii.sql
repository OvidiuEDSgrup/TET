--***
Create procedure wScriuCorectii @sesiune varchar(50), @parXML xml 
as
declare @tip varchar(20), @subtip varchar(20), @datalunii datetime, @o_data datetime, @data datetime, @vdata datetime, @DataJos datetime, @dataSus datetime, 
@o_marca varchar(6), @marca varchar(6), @o_lm varchar(9), @loc_de_munca varchar(9), @o_tipcor varchar(2), @tip_corectie_venit varchar(2), 
@Suma_neta decimal(10), @Suma_corectie decimal(10,2), @Procent_corectie float, 
@o_TipAchitare int, @o_SumaAchitata decimal(10,2), @TipAchitare int, @SumaAchitata decimal(10,2), @Data_achitare datetime, 
@densalariat varchar(50), @denlm varchar(30), @denfunctie varchar(30), @salarincadrare float, 
@userASiS varchar(20), @docXML xml, @docXMLIaDLSalarii xml, @eroare xml, @mesaj varchar(254), @ptupdate int

begin try
	--BEGIN TRAN
	select @subtip=isnull(xA.row.value('@subtip', 'varchar(20)'),'') from @parXML.nodes('/row/row') as xA(row) 	
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuCorectiiSP')
		exec wScriuCorectiiSP @sesiune, @parXML output
	exec wValidareCorectii @sesiune, @parXML
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	declare crsCorectii cursor for
	select isnull(tip, '') as tip, 
	isnull(datalunii,'01/01/1901') as datalunii, 
	isnull(o_data,isnull(data,'01/01/1901')) as o_data, 
	isnull(data,'01/01/1901') as data, 
	isnull(o_marca, isnull(marca, '')) as o_marca, 
	(case when isnull(marca, '')='' then isnull(marca_poz, '') else isnull(marca, '') end) as marca, 
	isnull(o_lm, isnull(loc_de_munca, '')) as o_lm, 
	(case when isnull(loc_de_munca,'')='' then (select p.loc_de_munca from personal p where p.marca=isnull(a.marca,a.marca_poz)) else isnull(loc_de_munca,'') end) as loc_de_munca, 
	isnull(o_tipcor, (case when isnull(tip_corectie_venit,'')='' then isnull(tip_corectie_venit_poz,'') else isnull(tip_corectie_venit,'') end)) as o_tipcor,
	(case when isnull(tip_corectie_venit,'')='' then isnull(tip_corectie_venit_poz,'') else isnull(tip_corectie_venit,'') end) as tip_corectie_venit, 
	isnull(Suma_neta, '') as Suma_neta, 
	isnull(Suma_corectie, '') as Suma_corectie, 
	isnull(Procent_corectie, '') as Procent_corectie, 
	isnull(o_TipAchitare, 0) as o_TipAchitare, 
	isnull(o_SumaAchitata, 0) as o_SumaAchitata, 
	isnull(TipAchitare, 0) as TipAchitare, 
	isnull(SumaAchitata, 0) as SumaAchitata, 
	isnull(densalariat,'') as densalariat, 
	isnull(denlm,'') as denlm,
	isnull(denfunctie,'') as denfunctie,
	isnull(salarincadrare,0) as salarincadrare,
	isnull(ptupdate, 0) as ptupdate
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		tip char(40) '../@tip', 
		datalunii datetime '../@data',
		o_data datetime '@o_data',
		data datetime '@data',
		o_marca char(6) '@o_marca', 
		marca char(6) '../@marca', 
		marca_poz char(6) '@marca', 
		o_lm char(9) '@o_lm', 
		loc_de_munca char(9) '@lm', 
		o_tipcor varchar(2) '@o_tipcor', 
		tip_corectie_venit varchar(2) '../@tipcor', 
		tip_corectie_venit_poz varchar(2) '@tipcor', 
		Suma_neta float '@sumaneta',
		Suma_corectie float '@sumacorectie',
		Procent_corectie float '@procentcorectie',
		o_TipAchitare int '@o_tipachitare', 
		o_SumaAchitata float '@o_sumaachitata', 
		TipAchitare int '@tipachitare', 
		SumaAchitata float '@sumaachitata', 
		densalariat char(50) '../@densalariat', 
		denlm char(30) '../@denlm', 
		denfunctie char(30) '../@denfunctie', 
		salarincadrare float '../@salarincadrare',
		ptupdate int '@update'
	) a

	open crsCorectii
	fetch next from crsCorectii into @tip, @datalunii, @o_data, @data, @o_marca, @marca, @o_lm, @loc_de_munca, @o_tipcor, @tip_corectie_venit, 
		@Suma_neta, @Suma_corectie, @Procent_corectie, @o_TipAchitare, @o_SumaAchitata, @TipAchitare, @SumaAchitata, 
		@densalariat, @denlm, @denfunctie, @salarincadrare, @ptupdate
	while @@fetch_status=0
	begin
		Set @vdata=(case when isnull((select Vizibil from webConfigForm where Meniu='SL' and tip=@tip and subTip=@subtip and Nume='Data'),0)<>0 
			then @data else @datalunii end)

		if @ptupdate=1 and (@data<>@o_data or @marca<>@o_marca or @loc_de_munca<>@o_lm or @Tip_corectie_venit<>@o_tipcor)
			delete from corectii where Data=@Data and Marca=@o_marca and Loc_de_munca=@o_lm and Tip_corectie_venit=@o_tipcor

		exec scriuCorectii @vData,@Marca,@Loc_de_munca,@Tip_corectie_venit,@Suma_corectie,@Procent_corectie, @Suma_neta
		set @Data_achitare=DateAdd(year,200,@vData)
		if @TipAchitare<>0 or @SumaAchitata<>0 or @o_TipAchitare<>0 or @o_SumaAchitata<>0
			exec scriuCorectii @Data_achitare,@Marca,@Loc_de_munca,@Tip_corectie_venit,@SumaAchitata,@TipAchitare, 0
		
		select @dataJos=dbo.BOM(@data), @dataSus=dbo.EOM(@data)
		exec scriuistPers @DataJos=@DataJos, @DataSus=@DataSus, @pMarca=@marca, @pLocm='', @Stergere=0, @Scriere=1

		fetch next from crsCorectii into @tip, @datalunii, @o_data, @data, @o_marca, @marca, @o_lm, @loc_de_munca, @o_tipcor, @tip_corectie_venit, 
			@Suma_neta, @Suma_corectie, @Procent_corectie, @o_TipAchitare, @o_SumaAchitata, @TipAchitare, @SumaAchitata, 
			@densalariat, @denlm, @denfunctie, @salarincadrare, @ptupdate
	end
	set @docXMLIaDLSalarii='<row tip="'+rtrim(@tip)+'" tipcor="'+rtrim(@tip_corectie_venit)+'" subtip="'+rtrim(@subtip)+
	'" marca="'+rtrim(@marca)+'" data="'+convert(char(10),@vdata,101)+'" codac="'+rtrim(@tip_corectie_venit)+ 
	'" densalariat="'+rtrim(@densalariat)+'" denlm="'+rtrim(@denlm)+'" denfunctie="'+rtrim(@denfunctie)+ 
	'" salarincadrare="'+rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'"/>'
	exec wIaPozSalarii @sesiune=@sesiune, @parXML=@docXMLIaDLSalarii 
	--COMMIT TRAN
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0)=0
		set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
--
declare @cursorStatus int
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crsCorectii' and session_id=@@SPID)
if @cursorStatus=1 
	close crsCorectii 
if @cursorStatus is not null 
	deallocate crsCorectii 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
