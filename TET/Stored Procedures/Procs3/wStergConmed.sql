--***
Create procedure wStergConmed @sesiune varchar(50), @parXML xml
as
declare @iDoc int, @eroare xml

begin try
	exec sp_xml_preparedocument @iDoc output, @parXML

	declare @tip varchar(2), @subtip varchar(2), @Ore_CM int,@datalunii datetime, @marca varchar(6), @data datetime, 
	@data_inceput datetime, @locm varchar(9), @nrcrt int, @stergere varchar(2), @parXMLPontaj xml, @mesaj varchar(254)
	Select @tip=tip, @subtip=subtip, @data=Data, @marca=marca, @data_inceput=data_inceput, @locm=loc_de_munca 
	from OPENXML (@iDoc, '/row')
	WITH
	(
		Tip varchar(2) '@tip', 
		subtip varchar(2) '@subtip', 
		Data datetime '@data', 
		Marca varchar(6) '@marca', 
		Data_inceput datetime '@datainceput', 
		Loc_de_munca varchar(6) '@lm' 
	) 

	delete from Conmed 
	where Data=dbo.eom(@Data) and Marca=@Marca and Data_inceput=@Data_inceput

	delete from infoconmed 
	where Data=dbo.eom(@Data) and Marca=@Marca and Data_inceput=@Data_inceput

	set @datalunii=dbo.eom(max(@Data))
	select @nrcrt=numar_curent
	from pontaj a where a.marca=@marca and data between dbo.bom(@data) and @datalunii and loc_de_munca=@locm 
		and ore_concediu_medical<>0
	Select @Ore_CM=isnull(sum(cm.Zile_lucratoare)*max((case when p.Salar_lunar_de_baza<>0 then Salar_lunar_de_baza else 8 end)),0)
	from conmed cm
		left outer join personal p on cm.Marca=p.Marca
	where cm.Data_inceput between dbo.bom(@Data) and dbo.eom(@Data) and cm.Marca=@Marca and cm.Tip_diagnostic<>'0-'

	Set @parXMLPontaj='<row tip="'+@tip+'" subtip="'+@subtip+'" marca="'+rtrim(@marca)+'" data="'+convert(char(10),@datalunii,101)+'" densalariat=" " denlm=" " denfunctie=" " salarincadrare="0" orecm="'+rtrim(convert(char(10),@Ore_CM))+'" lm="'+rtrim(@locm)+'" nrcrt="'+convert(char(3),@nrcrt)+'" />'
	exec wStergPontajEfectiv @sesiune=@sesiune, @parXML=@parXMLPontaj, @stergere=0

	exec sp_xml_removedocument @iDoc 
--select 'ok' as msg for xml raw
	exec wIaPozSalarii @sesiune=@sesiune, @parXML=@parXML 
end try

begin catch
	--ROLLBACK TRAN
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
