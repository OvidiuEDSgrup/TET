CREATE procedure [dbo].[yso_xIaPreturiNomenclator] --@sesiune varchar(50), @parXML XML  
as
	--declare @f_cod_categ varchar(10), @f_tip_pret varchar(10), @f_articol varchar(20), @dataSus datetime, @dataJos datetime,
	--		@f_den_categ varchar(100), @f_den_articol varchar(100)
	
	--set @f_articol= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_articol)[1]','varchar(20)'),''),' ','%')+'%'
	--set @f_cod_categ= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_cod_categ)[1]','varchar(10)'),''),' ','%')+'%'
	--set @f_tip_pret= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_tip_pret)[1]','varchar(10)'),''),' ','%')+'%'
	--set @f_den_articol= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_den_articol)[1]','varchar(100)'),''),' ','%')+'%'
	--set @f_den_categ= '%'+REPLACE(ISNULL(@parXML.value('(/row/@f_den_categ)[1]','varchar(100)'),''),' ','%')+'%'
	--set @dataJos=@parXML.value('(/row/@datajos)[1]','datetime')
	--set @dataSus=@parXML.value('(/row/@datasus)[1]','datetime')
	
select --top 100
	 *
from yso_vIaPreturiNomenclator
--where p.tip_pret like @f_tip_pret and p.um like @f_cod_categ and p.cod_produs like @f_articol and 
--	 p.data_inferioara between @dataJos and @dataSus and n.denumire like @f_den_articol and c.Denumire like @f_den_categ
--for xml raw,root('Date')
