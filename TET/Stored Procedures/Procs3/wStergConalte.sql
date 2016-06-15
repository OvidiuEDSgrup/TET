--***
Create procedure wStergConalte @sesiune varchar(50), @parXML xml
as
declare @iDoc int, @eroare xml

begin try
--	BEGIN TRAN
	exec sp_xml_preparedocument @iDoc output, @parXML
	declare @tip varchar(2), @subtip varchar(2), @Ore_CFS int, @Ore_nemotivate int, @Ore_delegatie int, 
	@datalunii datetime, @marca varchar(6), @data datetime, @data_inceput datetime, @ora_inceput varchar(10), @tipconcediu varchar(1), @locm varchar(9), 
	@nrcrt int, @stergere varchar(2), @parXMLPontaj xml, @mesaj varchar(254)

	Select @tip=tip, @subtip=subtip, @data=Data, @marca=marca, @data_inceput=data_inceput, @ora_inceput=isnull(ora_inceput, ''), @tipconcediu=tip_concediu, @locm=loc_de_munca
	from OPENXML (@iDoc, '/row')
	WITH
	(
		Tip varchar(2) '@tip',
		subtip varchar(2) '@subtip',
		Data datetime '@data',
		Marca varchar(6) '@marca',
		Data_inceput datetime '@datainceput',
		Ora_inceput varchar(10) '@orainceput', 
		Tip_concediu char(1) '@tipconcediu',
		Loc_de_munca varchar(6) '@lm' 
	) 

	delete conalte from conalte ca
	where ca.Data=dbo.eom(@Data) and ca.Marca=@Marca 
		and ca.Data_inceput=@Data_inceput+convert(char(8),convert(datetime,(case when @ora_inceput='' then '00:00' else @ora_inceput end)+':00'),108) 
		and ca.Tip_concediu=@tipconcediu

	set @datalunii=dbo.eom(max(@Data))
	select @nrcrt=numar_curent
	from pontaj a 
	where a.marca=@marca and data between dbo.bom(@data) and @datalunii and loc_de_munca=@locm 
		and (ore_concediu_fara_salar<>0 or ore_nemotivate<>0 or spor_cond_10<>0)
	Select @Ore_CFS=isnull(sum((case when ca.tip_concediu='1' then ca.Zile else 0 end))*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end)),0),
		@Ore_nemotivate=isnull(sum((case when ca.tip_concediu='2' then ca.Zile+ca.Indemnizatie else 0 end))*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end)),0),
		@Ore_delegatie=isnull(sum((case when ca.tip_concediu='4' then ca.Zile else 0 end))*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end)),0)
	from conalte ca
		left outer join personal p on ca.Marca=p.Marca
	where ca.Data_inceput between dbo.bom(@Data) and dbo.eom(@Data) and ca.Marca=@Marca 

	set @parXMLPontaj='<row tip="'+rtrim(@tip)+'" marca="'+rtrim(@marca)+'" data="'+convert(char(10),@datalunii,101)
		+'" densalariat=" " denlm=" " denfunctie=" "'
		+' subtip="'+'P1'+'" orecfs="'+rtrim(convert(char(10),@Ore_CFS))
		+'" orenemotivate="'+rtrim(convert(char(10),@Ore_nemotivate))
		+'" oredelegatii="'+rtrim(convert(char(10),@Ore_delegatie))
		+'" lm="'+rtrim(@locm)+'" nrcrt="'+convert(char(3),@nrcrt)+'" />'

	exec wStergPontajEfectiv @sesiune=@sesiune, @parXML=@parXMLPontaj, @stergere=0
	exec sp_xml_removedocument @iDoc 
	exec wIaPozSalarii @sesiune=@sesiune, @parXML=@parXML 
--	COMMIT TRAN
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
