--***
Create procedure wScriuConcodih @sesiune varchar(50), @parXML xml 
as
declare @ptupdate int, @tip varchar(2), @subtip varchar(2), @datalunii datetime, @Datalunii_1 datetime, 
@o_marca varchar(6), @marca varchar(6), @o_tipconcediu varchar(2), @tip_concediu varchar(2), 
@o_datainceput datetime, @data_inceput datetime, @data_sfarsit datetime, @Zile_CO int, 
@xZile_CO int, @IndNetaCO decimal(10), @codac varchar(20), @explicatii varchar(40), @Introd_manual int, @Indemnizatie_CO float, 
@dataop datetime, @nData_op float, 
@densalariat varchar(50), @denlm varchar(30), @lmpontaj varchar(30), 
@denlmpontaj varchar(30), @denfunctie varchar(30), @salarincadrare float, @Ore_CO int, @Ore_COEV int, 
@userASiS varchar(20), @docXML xml, @docXMLIaDLSalarii xml, @docXMLPontaj xml, @eroare xml, @mesaj varchar(254), @COEV_macheta int
Set @COEV_macheta=dbo.iauParL('PS','COEVMCO')

begin try
	--BEGIN TRAN
	if exists (select 1 from sysobjects where [type]='P' and [name]='wScriuConcodihSP')
		exec wScriuConcodihSP @sesiune, @parXML OUTPUT
	if exists (select 1 from sysobjects where [type]='P' and [name]='wValidareConcodih')
		exec wValidareConcodih @sesiune, @parXML
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	declare crsConcodih cursor for
	select isnull(ptupdate, 0) as ptupdate, isnull(tip, '') as tip, isnull(subtip, '') as subtip, 
	isnull(datalunii,'01/01/1901') as datalunii, isnull(o_marca, isnull(marca, '')) as o_marca, 
	(case when isnull(marca, '')='' then isnull(marca_poz, '') else isnull(marca, '') end) as marca, 
	isnull(o_tipconcediu, '') as o_tipconcediu, 
	isnull(tip_concediu, '') as tip_concediu, 
	isnull(o_datainceput, '01/01/1901') as o_datainceput, 
	isnull(data_inceput, '01/01/1901') as data_inceput, 
	isnull(data_sfarsit, '01/01/1901') as data_sfarsit, 
	isnull(Zile_CO, 0) as Zile_CO, 
	isnull(calcul_manual,0) as calcul_manual, 
	isnull(indemnizatieco,0) as indemnizatie_CO,
	isnull(IndNetaCO, 0) as IndNetaCO, 
	isnull(dataop, convert(datetime,convert(char(10),getdate(),101),101)) as dataop, 
	isnull(explicatii,'') as explicatii, 
	isnull(densalariat,'') as densalariat, 
	isnull(denlm,'') as denlm,
	isnull(denfunctie,'') as denfunctie,
	isnull(salarincadrare,0) as salarincadrare, 
	(case when isnull(lmpontaj,'')='' then (select p.loc_de_munca from personal p where p.marca=isnull(a.marca, a.marca_poz)) else 		isnull(lmpontaj,'') end) as lmpontaj,
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
		data_sfarsit datetime '@datasfarsit', 
		Zile_CO int '@zileco', 
		calcul_manual int '@calculmanual',
		indemnizatieco decimal(10) '@indemnizatieco', 
		IndNetaCO decimal(10) '@indnetaco', 
		dataop datetime '@dataop', 
		explicatii varchar(40) '@explicatii', 
		densalariat varchar(50) '../@densalariat', 
		denlm varchar(30) '../@denlm', 
		denfunctie varchar(30) '../@denfunctie', 
		salarincadrare float '../@salarincadrare',  
		lmpontaj varchar(30) '@lm', 
		denlmpontaj varchar(30) '@denlm' 
	) a

	open crsConcodih
	fetch next from crsConcodih into @ptupdate, @tip, @subtip, @datalunii, @o_marca, @marca, @o_tipconcediu, @tip_concediu, 
	@o_datainceput, @data_inceput, @data_sfarsit, @xZile_CO, @Introd_manual, @Indemnizatie_CO, @IndNetaCO, @dataop, @explicatii, @densalariat, @denlm, @denfunctie, @salarincadrare, @lmpontaj, @denlmpontaj 
	while @@fetch_status=0
	begin
		Set @Zile_CO=dbo.Zile_lucratoare(@data_inceput,(case when @data_sfarsit>@datalunii then @datalunii else @data_sfarsit end))
		if @tip_concediu in ('3','6') and @xZile_CO>@Zile_CO
			set @Zile_CO=@xZile_CO
		Set @nData_op=datediff(day,convert(datetime,'01/01/1901'),@dataop)+693961
		if @ptupdate=1 and (@marca<>@o_marca or @Data_inceput<>@o_datainceput or @Tip_concediu<>@o_tipconcediu)
		Begin
			delete from concodih where Data=@Datalunii and Marca=@o_marca and Tip_concediu=@o_tipconcediu and Data_inceput=@o_datainceput
			delete from concodih where Data=@Datalunii and Marca=@o_marca and Tip_concediu='9' and Data_inceput=@o_datainceput
		End
		exec scriuConcodih @Datalunii, @Marca,@Tip_concediu,@Data_inceput,@Data_sfarsit, @Zile_CO, @Indemnizatie_CO, @nData_op, 0, 0, 0, @Introd_manual
		Set @Datalunii_1=dbo.bom(@Datalunii)
		exec calcul_concedii_de_odihna @Datalunii_1, @Datalunii, @Marca,@data_inceput,@Zile_CO, @Indemnizatie_CO, '', 0, 0, 0, 0, 0, '01/01/1901', 0, 0
		if @IndNetaCO<>0
			exec scriuConcodih @Datalunii,@Marca,'9',@Data_inceput,@Data_sfarsit, 0, @IndNetaCO, @nData_op, 0, 0, 0

--	calcul ore concediu de odihna si obligatii cetatenesti (CO eveniment) de pus in pontaj
		Select @Ore_CO=isnull(sum(co.Zile_CO)*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end)),0) 
		from concodih co
			left outer join personal p on co.Marca=p.Marca
		where co.data=@Datalunii and co.Marca=@Marca
			and co.Tip_concediu in ('1','4','5','7','8') 
			and (@COEV_macheta=0 or @COEV_macheta=1 and co.Tip_concediu not in ('2','E'))

		Select @Ore_COEV=isnull(sum(co.Zile_CO)*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end)),0) 
		from concodih co
			left outer join personal p on co.Marca=p.Marca
		where co.data=@Datalunii and co.Marca=@Marca and @COEV_macheta=1 and co.Tip_concediu in ('2','E')

		If @Ore_CO<>0 or @Ore_COEV<>0 or @tip_concediu in ('3','6') and @o_tipconcediu in ('1','4','5','7','8')
		Begin
			Set @docXMLPontaj='<row tip="'+rtrim(@tip)+'" marca="'+rtrim(@marca)+'" data="'+convert(char(10),@datalunii,101)+'" densalariat="'+rtrim(@densalariat)+'" denlm="'+rtrim(@denlm)+'" denfunctie="'+rtrim(@denfunctie)+'" salarincadrare="'+rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'">'
			+'<row subtip="'+@subtip+'" data="'+rtrim(convert(char(10),@datalunii,101))+'" oreco="'+rtrim(convert(char(10),@Ore_CO))+'" oreobligatii="'+rtrim(convert(char(10),@Ore_COEV))
			+'" lm="'+rtrim(@lmpontaj)+'" denlm="'+rtrim(@denlmpontaj)+	'" /></row>'
			exec wScriuPontaj @sesiune=@sesiune, @parXML=@docXMLPontaj
		End 
		fetch next from crsConcodih into @ptupdate, @tip, @subtip, @datalunii, @o_marca, @marca, @o_tipconcediu, @tip_concediu, 
		@o_datainceput, @data_inceput, @data_sfarsit, @xZile_CO, @Introd_manual, @Indemnizatie_CO, @IndNetaCO, @dataop, @explicatii, @densalariat, @denlm, @denfunctie, @salarincadrare, @lmpontaj, @denlmpontaj
	end
	set @docXMLIaDLSalarii='<row tip="'+rtrim(@tip)+'" marca="'+rtrim(@marca)+'" data="'+convert(char(10),@datalunii,101)+'" densalariat="'+ rtrim(@densalariat)+'" denlm="'+rtrim(@denlm)+'" denfunctie="'+rtrim(@denfunctie)+'" salarincadrare="'+ rtrim(convert(char(10),convert(decimal(10,2),@salarincadrare)))+'"/>'
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
set @cursorStatus=(select is_open from sys.dm_exec_cursors(0) where name='crsConcodih' and session_id=@@SPID )
if @cursorStatus=1 
	close crsConcodih 
if @cursorStatus is not null 
	deallocate crsConcodih 
--
begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
