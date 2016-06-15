--***
create procedure [dbo].[wIaFolSalariati] @sesiune varchar(30), @parXML XML
AS  
  
	Declare  @marca varchar(9)

select @marca=isnull(@parXML.value('(/row/@marca)[1]', 'varchar(9)'), '')  

select top 100 a.Tip_gestiune as tip_gestiuen,rtrim(a.Cod_gestiune) as cod_gestiune,RTRIM(a.cod)as cod,RTRIM(a.cont)as cont, convert(varchar(10),a.Data,101) as data,
		convert(varchar(10),a.Data_ultimei_iesiri,101) as data_ultimei_iesiri,convert(decimal(12,4),a.Pret) as pret,RTRIM(Cod_intrare)as cod_intrare,
		convert(decimal(12,4),Intrari) as intrari,convert(decimal(12,4),Iesiri) as iesiri,convert(decimal(12,4),a.stoc) as stoc,
		convert(decimal(12,2),TVA_neexigibil) as tva_neexigibil,RTRIM(a.Loc_de_munca) as loc_de_munca,RTRIM(n.denumire) as denumire,
		RTRIM(Comanda) as comanda,RTRIM(contract) as contract,convert(decimal(12,4),Stoc_initial) as stoc_initial
from stocuri a 
		left outer join nomencl n on n.Cod=a.cod
where a.Cod_gestiune=@marca
  and a.Tip_gestiune in ('F')
  and a.Stoc <>0
order by a.Cod
for xml raw
--select * from stocuri where  Cod_gestiune='11' and cod='0001'
