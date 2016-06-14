declare @parxml xml
set @parxml=
(select --'123456789012345678901' as Alfa1, 12345678901234567855555555555555555901 as Val1
Cod, Denumire, rtrim(tip_cod) as tip_cod, UM, UM2, '' as Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari
, Comision_vamal, Randament, Cod_NC8, UM_suplimentara, _eroareimport 
from yso_vIaCodvama
where cod='39173900'
for xml raw)
select @parxml
	declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	select top 0 * into #yso_vIaCodvamatmp from yso_vIaCodvama
	insert codvama 
	(Cod, Denumire, UM, UM2, Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari, Comision_vamal, Randament, Alfa1, Alfa2, Val1, Val2)
	select 
	Cod, Denumire, UM, UM2, Coef_conv, Taxa_UE, Taxa_AELS, Taxa_GB, Taxa_alte_tari, Comision_vamal, Randament, Cod_NC8, UM_suplimentara, tip_cod, 0 
	from OPENXML(@iDoc, '/row',0)
	with #yso_vIaCodvamatmp
--	(Cod	char(30),
--Denumire	char(150),
--tip_cod	float(8),
--UM	char(3),
--UM2	char(3),
--Coef_conv	float(8),
--Taxa_UE	real,
--Taxa_AELS	real,
--Taxa_GB	real,
--Taxa_alte_tari	real,
--Comision_vamal	real,
--Randament	float(8),
--Cod_NC8	varchar(20),
--UM_suplimentara	varchar(20),
--_eroareimport	nvarchar(1000))

drop table #yso_vIaCodvamatmp
--(Cod	char(30),
--Denumire	char(150),
--UM	char(3),
--UM2	char(3),
--Coef_conv	float(8),
--Taxa_UE	real,
--Taxa_AELS	real,
--Taxa_GB	real,
--Taxa_alte_tari	real,
--Comision_vamal	real,
--Randament	float(8),
--Alfa1	char(20),
--Alfa2	char(20) ,
--Val1	float(8),
--Val2	float(8))
	
	exec sp_xml_removedocument @iDoc 