--***
if exists (select * from sysobjects where name ='wACCodIntrareSP')
drop procedure wACCodIntrareSP
go
--*** 
CREATE procedure wACCodIntrareSP @sesiune varchar(50),@parXML XML
as/*sp
if exists(select * from sysobjects where name='wACCodIntrareSP' and type='P')
	exec wACCodIntrareSP @sesiune,@parXML
else sp*/begin
	declare @Sb varchar(9), @StocCom int, @StocComLivr int, @StocLot int, @StocFurn int, 
		@IesLuna int, @IesZi int, @StCust35 int, @StCust8 int, 
		@searchText varchar(80), @tip varchar(2), @subtip varchar(2), @data datetime,
		@cod varchar(20), @gestiune varchar(20), @gestprim varchar(20), @restDF int, 
		@comanda varchar(20), @lm varchar(9), @contract varchar(20), @lot varchar(20), @furnizor varchar(13), @tertfiltru varchar(13), 
		@cont_corespondent varchar(40), @DataExp datetime,
		@Iesire int, @IntrareCuMinus int, @DataSupStoc datetime, @Custodie int, @Folosinta int, @cantitate float, @SubgestFolLM int --/*sp
		,@tert varchar(20), @locatie varchar(20), @gestiuneCustodie int--sp*/
	
	select @Sb='', @StocCom=0, @StocComLivr=0, @StocLot=0, @StocFurn=0, @IesLuna=0, @IesZi=0, @StCust35=0, @StCust8=0,@DataExp=0, @SubgestFolLM=0 
	select @Sb=(case when tip_parametru='GE' and parametru='SUBPRO' then val_alfanumerica else @Sb end),
		@StocCom=(case when tip_parametru='GE' and parametru='STOCPECOM' then val_logica else @StocCom end),
		@StocComLivr=(case when tip_parametru='GE' and parametru='STOCCOML' then val_logica else @StocComLivr end),
		@StocLot=(case when tip_parametru='GE' and parametru='STOCLOT' then val_logica else @StocLot end),
		@DataExp=(case when tip_parametru='GE' and parametru='DATEXP' then val_logica else @DataExp end),
		@StocFurn=(case when tip_parametru='GE' and parametru='STOCFURN' then val_logica else @StocFurn end),
		@IesLuna=(case when tip_parametru='GE' and parametru='IESLUNCRT' then val_logica else @IesLuna end),
		@IesZi=(case when tip_parametru='GE' and parametru='IESSLAZI' then val_logica else @IesZi end),
		@StCust35=(case when tip_parametru='GE' and parametru='STCUST35' then val_logica else @StCust35 end),
		@StCust8=(case when tip_parametru='GE' and parametru='STCUST8' then val_logica else @StCust8 end), 
		@SubgestFolLM=(case when tip_parametru='GE' and parametru='SUBGLMFOL' then val_logica else @SubgestFolLM end)
	from par 

	select	@searchText=isnull(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), ''),
			@tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
			@subtip=isnull(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), ''),
			@data=isnull(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),
			@cod=isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'),isnull(@parXML.value('(/row/@cCod)[1]','varchar(20)'),'')),
			@gestiune=isnull(@parXML.value('(/row/@gestiune)[1]', 'varchar(20)'), ''),
			@gestprim=isnull(@parXML.value('(/row/@gestprim)[1]', 'varchar(20)'), ''),
			@comanda=isnull(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), ''),
			@lm=isnull(@parXML.value('(/row/@lm)[1]', 'varchar(9)'), ''),
			@contract=isnull(@parXML.value('(/row/@contract)[1]', 'varchar(20)'), ''),
			@lot=isnull(@parXML.value('(/row/@lot)[1]', 'varchar(20)'), ''),
			@furnizor=isnull(@parXML.value('(/row/@furnizor)[1]', 'varchar(13)'), ''),
			@tertfiltru=isnull(@parXML.value('(/row/@tertfiltru)[1]', 'varchar(13)'), ''),
			@cont_corespondent=isnull(@parXML.value('(/row/@contcorespondent)[1]', 'varchar(40)'), ''),
			@cantitate = isnull(@parXML.value('(/row/@cantitate)[1]', 'float'), '')--/*sp
			,@tert=isnull(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), '')
			,@locatie=coalesce(@parXML.value('(/row/@locatie)[1]', 'varchar(20)'),@parXML.value('(/row/detalii/row/@locatie)[1]', 'varchar(20)'), '')
	if @gestiune<>''
		select 	@gestiuneCustodie=ISNULL(g.detalii.value('(/row/@custodie)[1]','int'),0) from gestiuni g where g.Subunitate=@Sb and g.Cod_gestiune=@gestiune
	--sp*/
	set @restDF=0
	if @tip='DF' and @subtip='RO'
		set @restDF=1

	/*
	 TE, DF si PF sunt considerate iesiri; daca au camp pt. cod intrare primitor acesta nu va avea si autocomplete; exceptie subtip RO (restituire obiecte) la DF
	 => DF este iesire din depozit, nu si intrare in folosinta*/
	select @searchText=REPLACE(@searchText, ' ', '%'), 
		@Iesire=(case when @tip in ('AP', 'AC', 'CM', 'TE', 'AE', 'DF', 'PF', 'CI') then 1 else 0 end), 
		@IntrareCuMinus=(case when @Iesire=0 and @cantitate<0 then 1 else 0 end), 
		@DataSupStoc=(case when @Iesire=1 and @data>'01/01/1901' and (@IesLuna=1 or @IesZi=1) then (case when @IesLuna=1 then dbo.eom(@data) else @data end) else '12/31/2999' end),
		@Custodie=(case when @tip='AI' and (@StCust35=1 and left(@cont_corespondent, 2)='35' or @StCust8=1 and left(@cont_corespondent, 1)='8') then 1 else 0 end), 
		@Folosinta=(case when @tip in ('PF', 'CI', 'AF') or @restDF=1 then 1 else 0 end)--/*sp
		,@gestiune=(case when @Custodie=1 then @tert else @gestiune end)--sp*/

	select top 100
	rtrim(s.cod_intrare) 
		as cod,
	ltrim(rtrim(convert(char(18),convert(decimal(12,3),s.stoc))))+' '+n.um
		+ (case when @DataExp=1 and @Iesire=1 then ' Data exp: '+isnull(convert(char(10),s.Data_expirarii,101),'') when @tip in ('CI') then ' Data Exp. '+ convert(char(10),s.Data_expirarii,101) else '' end) 
		as info,
	(case when @Folosinta=1 and @SubgestFolLM=1 then 'L.M. '+rtrim(s.loc_de_munca)+' '+rtrim(left(lm.denumire,20)) else 'Cont '+rtrim(s.cont)+', '+convert(char(10),s.data,103) end)
		+', Pret '+ltrim(rtrim(convert(char(18),convert(decimal(11,5),s.Pret)))) 
		+ (case when @StocLot=1 and (@Iesire=1 or @IntrareCuMinus=1) then ' Lot: '+isnull(RTRIM(ltrim(s.lot)),'') else '' end)
		as denumire
	from stocuri s
	inner join nomencl n on n.cod=s.cod
	left join lm on lm.cod=s.loc_de_munca
	left join pozdoc pd on pd.idpozdoc=s.idIntrareFirma 
	where s.subunitate=@Sb and (@Custodie=1 and s.tip_gestiune='T' or @Folosinta=1 and s.tip_gestiune='F' or @Custodie=0 and @Folosinta=0 and s.tip_gestiune not in ('F', 'T'))
	and (@gestiune='' or s.cod_gestiune=@gestiune and @restDF=0 or s.cod_gestiune=@gestprim and @restDF=1)
	and (@cod='' or s.cod=@cod)
	and (@searchText='' or s.cod_intrare like @searchText+'%' or s.lot like @searchText+'%')
	and ((@Iesire=0 and @IntrareCuMinus=0) or (@Iesire=1 and @cantitate>=0 and s.stoc>=0.001 and s.data<=@DataSupStoc or (@IntrareCuMinus=0 or s.stoc>=0.001) and @cantitate<0))
	and (@Iesire=0 or @StocCom=0 or @comanda='' or s.comanda=@comanda)
	and (@Iesire=0 or @StocComLivr=0 or @contract='' or s.contract=@contract)
	and (@Iesire=0 or @StocFurn=0 or @furnizor='' or s.furnizor=@furnizor)
	and (@Iesire=0 or @StocLot=0 or @lot='' or s.lot=@lot)
	and (@tertfiltru='' or isnull(pd.tert,'')=@tertfiltru)--/*SP
	and (@Iesire=0 or @gestiuneCustodie=0 or s.Locatie=@locatie) --or @locatie='' SP*/
	order by rtrim(s.cod_intrare)
	for xml raw
end
