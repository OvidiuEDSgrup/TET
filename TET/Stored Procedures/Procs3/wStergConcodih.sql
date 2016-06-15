--***
Create procedure wStergConcodih @sesiune varchar(50), @parXML xml
as
declare @iDoc int, @eroare xml, @mesaj varchar(254)

begin try
	exec sp_xml_preparedocument @iDoc output, @parXML

	declare @tip varchar(2), @subtip varchar(2), @Ore_CO int,@datalunii datetime,@parXMLPontaj xml, @marca varchar(6), @data datetime, 
	@data_inceput datetime, @tip_concediu varchar(2), @locm varchar(9), @nrcrt int, @stergere varchar(2)
	Select @tip=tip, @subtip=subtip, @data=data, @marca=marca, @data_inceput=data_inceput, @tip_concediu=tip_concediu, @locm=loc_de_munca 
	from OPENXML (@iDoc, '/row')
	WITH
	(
		Tip varchar(2) '@tip', 
		Subtip varchar(2) '@subtip', 
		Data datetime '@data', 
		Marca varchar(6) '@marca', 
		Data_inceput datetime '@datainceput', 
		Tip_concediu varchar(2) '@tipconcediu', 
		Loc_de_munca varchar(6) '@lm' 
	) 
	delete Concodih from Concodih co where
	co.Data=dbo.eom(@Data) and co.Marca=@Marca and co.Data_inceput=@Data_inceput and co.Tip_concediu=@Tip_concediu

	set @datalunii=dbo.eom(max(@Data))
	select @nrcrt=numar_curent
	from pontaj a 
	where a.marca=@marca and data between dbo.bom(@data) and @datalunii and loc_de_munca=@locm 
		and ore_concediu_de_odihna<>0
	Select @Ore_CO=isnull(sum(co.Zile_CO)*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end)),0) 
	from concodih co
		left outer join personal p on co.Marca=p.Marca
	where co.data=@Datalunii and co.Marca=@Marca

	Set @parXMLPontaj='<row tip="'+@tip+'" marca="'+rtrim(@marca)+'" data="'+convert(char(10),@datalunii,101)+'" densalariat=" " denlm=" " denfunctie=" "	salarincadrare="0" subtip="'+@subtip+'" oreco="'+rtrim(convert(char(10),@Ore_CO))+'" lm="'+rtrim(@locm)+'" nrcrt="'+convert(char(3),@nrcrt)+'" />'
	exec wStergPontajEfectiv @sesiune=@sesiune, @parXML=@parXMLPontaj, @stergere=0
	
	exec sp_xml_removedocument @iDoc 
--	select 'ok' as msg for xml raw
	exec wIaPozSalarii @sesiune=@sesiune, @parXML=@parXML
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
