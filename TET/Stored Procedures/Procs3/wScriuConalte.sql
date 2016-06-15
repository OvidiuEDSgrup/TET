--***
Create procedure wScriuConalte @sesiune varchar(50), @parXML xml 
as
declare @ptupdate int, @tip varchar(2), @subtip varchar(2), @datalunii datetime, @Datalunii_1 datetime, 
@o_marca varchar(6), @marca varchar(6), @o_tipconcediu varchar(2), @tip_concediu varchar(2), 
@o_datainceput datetime, @data_inceput datetime, @ora_inceput varchar(10), @data_sfarsit datetime, @ora_sfarsit varchar(10), @Zile_CO int, 
@codac varchar(20), @explicatii varchar(40), @Indemnizatie_CO float, @Introd_manual int, @Data_operarii datetime, @Ora_operarii char(6),
@densalariat varchar(50), @denlm varchar(30), @lmpontaj varchar(30), 
@denlmpontaj varchar(30), @denfunctie varchar(30), @Zile int, @Ore int, @Ore_CFS int, @Ore_nemotivate int, @Ore_invoiri int, @Ore_delegatie int, 
@userASiS varchar(20), @docXML xml, @docXMLIaDLSalarii xml, @docXMLPontaj xml, @eroare xml, @mesaj varchar(254)

begin try
	--BEGIN TRAN
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuConalteSP')
		exec wScriuConalteSP @sesiune, @parXML OUTPUT
	if exists (select 1 from sysobjects where [type]='P' and [name]='wValidareConalte')
		exec wValidareConalte @sesiune, @parXML
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	declare crsConalte cursor for
	select isnull(ptupdate, 0) as ptupdate, isnull(tip, '') as tip, isnull(subtip, '') as subtip, 
	isnull(datalunii,'01/01/1901') as datalunii, isnull(o_marca, isnull(marca, '')) as o_marca, 
	(case when isnull(marca, '')='' then isnull(marca_poz, '') else isnull(marca, '') end) as marca, 
	isnull(o_tipconcediu, '') as o_tipconcediu, 
	isnull(tip_concediu, '') as tip_concediu, 
	isnull(o_datainceput, '01/01/1901') as o_datainceput, 
	isnull(data_inceput, '01/01/1901') as data_inceput, 
	isnull(ora_inceput, '') as ora_inceput, 
	isnull(data_sfarsit, '01/01/1901') as data_sfarsit, 
	isnull(ora_sfarsit, '') as ora_sfarsit, 
	isnull(ore,0) as ore, 
	isnull(explicatii,'') as explicatii, 
	isnull(densalariat,'') as densalariat, 
	isnull(denlm,'') as denlm,
	isnull(denfunctie,'') as denfunctie,
	(case when isnull(lmpontaj,'')='' then (select p.loc_de_munca from personal p where p.marca=isnull(a.marca, a.marca_poz)) else isnull(lmpontaj,'') end) as lmpontaj,
	isnull(denlmpontaj,'') as denlmpontaj
	from OPENXML(@iDoc, '/row/row')
	WITH 
	(
		ptupdate int '@update',
		tip varchar(2) '../@tip', 
		subtip varchar(2) '@subtip', 
		datalunii datetime '../@data',
		o_marca varchar(6) '@o_marca', 
		marca varchar(6) '../@marca', 
		marca_poz varchar(6) '@marca', 
		o_tipconcediu varchar(2) '@o_tipconcediu', 
		tip_concediu varchar(2) '@tipconcediu', 
		o_datainceput datetime '@o_datainceput', 
		data_inceput datetime '@datainceput', 
		ora_inceput varchar(10) '@orainceput', 
		data_sfarsit datetime '@datasfarsit', 
		ora_sfarsit varchar(10) '@orasfarsit', 
		ore int '@oreca', 
		explicatii varchar(40) '@explicatii', 
		densalariat varchar(50) '../@densalariat', 
		denlm varchar(30) '../@denlm', 
		denfunctie varchar(30) '../@denfunctie', 
		lmpontaj varchar(30) '@lm', 
		denlmpontaj varchar(30) '@denlm' 
	) a

	open crsConalte
	fetch next from crsConalte into @ptupdate, @tip, @subtip, @datalunii, @o_marca, @marca, @o_tipconcediu, @tip_concediu, 
	@o_datainceput, @data_inceput, @ora_inceput, @data_sfarsit, @ora_sfarsit, @ore, @explicatii, @densalariat, @denlm, @denfunctie, @lmpontaj, @denlmpontaj 
	while @@fetch_status=0
	begin
		set @zile=0
		select @Zile=dbo.Zile_lucratoare(@data_inceput,@data_sfarsit) where @ore=0 and not (@data_inceput=@data_sfarsit and @ora_inceput<>'' and @ora_sfarsit<>'')
		set @Introd_manual=0
		set @Indemnizatie_CO=0
		set @Data_operarii=convert(datetime,convert(char(10),getdate(),104),104)
		set @Ora_operarii=RTrim(replace(convert(char(8),getdate(),108),':',''))
		set @data_inceput=@data_inceput+convert(char(8),convert(datetime,(case when @ora_inceput='' then '00:00' else @ora_inceput end)+':00'),108)
		set @data_sfarsit=@data_sfarsit+convert(char(8),convert(datetime,(case when @ora_sfarsit='' then '00:00' else @ora_sfarsit end)+':00'),108)
		if @Ore=0 and @tip_concediu in ('2','3') and @ora_inceput<>'' and @ora_sfarsit<>''
			set @Ore=DATEDIFF(HOUR,@data_inceput,@data_sfarsit)
			
		if @ptupdate=1 and (@marca<>@o_marca or @Data_inceput<>@o_datainceput or @Tip_concediu<>@o_tipconcediu)
			delete from conalte where Data=@Datalunii and Marca=@o_marca and Tip_concediu=@o_tipconcediu and Data_inceput=@o_datainceput
		exec scriuConalte @Datalunii, @Marca, @Tip_concediu, @Data_inceput, @Data_sfarsit, @Zile, @Introd_manual, @ore, @userASiS, @Data_operarii, @Ora_operarii

		set @Datalunii_1=dbo.bom(@Datalunii)
		select @Ore_CFS=sum((case when ca.tip_concediu='1' then ca.Zile else 0 end))*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end)),
			@Ore_nemotivate=sum((case when ca.tip_concediu='2' then ca.Zile else 0 end))*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end))
				+sum((case when ca.tip_concediu='2' then ca.Indemnizatie else 0 end)),
			@Ore_invoiri=sum((case when ca.tip_concediu='3' then ca.Zile else 0 end))*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end))
				+sum((case when ca.tip_concediu='3' then ca.Indemnizatie else 0 end)),
			@Ore_delegatie=sum((case when ca.tip_concediu='4' then ca.Zile else 0 end))*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end))
		from Conalte ca
			left outer join personal p on ca.Marca=p.Marca
		where ca.data=@Datalunii and ca.Marca=@Marca

		If @Ore_CFS<>0 or @Ore_nemotivate<>0 or @Ore_delegatie<>0 or @Ore_invoiri<>0
		Begin
			set @docXMLPontaj='<row tip="'+rtrim(@tip)+'" marca="'+rtrim(@marca)+'" data="'+convert(char(10),@datalunii,101)
				+'" densalariat="'+rtrim(@densalariat)+'" lmantet="'+rtrim(@lmpontaj)+'" denlmantet="'+rtrim(@denlm)+'" denfunctie="'+rtrim(@denfunctie)+'">'
				+'<row subtip="'+@subtip+'" data="'+rtrim(convert(char(10),@datalunii,101))
				+(case when @tip_concediu='1' or @o_tipconcediu='1' then '" orecfs="'+rtrim(convert(char(10),@Ore_CFS)) else '' end)
				+(case when @tip_concediu='2' or @o_tipconcediu='2' then '" orenemotivate="'+rtrim(convert(char(10),@Ore_nemotivate)) else '' end)
				+(case when @tip_concediu='3' or @o_tipconcediu='3' then '" oreinvoiri="'+rtrim(convert(char(10),@Ore_invoiri)) else '' end)
				+(case when @tip_concediu='4' or @o_tipconcediu='4' then '" oredelegatii="'+rtrim(convert(char(10),@Ore_delegatie)) else '' end)
				+'" lm="'+rtrim(@lmpontaj)+'" denlm="'+rtrim(@denlmpontaj)+'" /></row>'
			exec wScriuPontaj @sesiune=@sesiune, @parXML=@docXMLPontaj
		End 
		fetch next from crsConalte into @ptupdate, @tip, @subtip, @datalunii, @o_marca, @marca, @o_tipconcediu, @tip_concediu, 
		@o_datainceput, @data_inceput, @ora_inceput, @data_sfarsit, @ora_sfarsit, @ore, @explicatii, @densalariat, @denlm, @denfunctie, @lmpontaj, @denlmpontaj 
	end
	set @docXMLIaDLSalarii='<row tip="'+rtrim(@tip)+'" marca="'+rtrim(@marca)+'" data="'+convert(char(10),@datalunii,101)+'" 		densalariat="'+ rtrim(@densalariat)+'" denlm="'+rtrim(@denlm)+'" denfunctie="'+rtrim(@denfunctie)+'"/>'
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
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crsConalte' and session_id=@@SPID )
if @cursorStatus=1 
	close crsConalte 
if @cursorStatus is not null 
	deallocate crsConalte 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
