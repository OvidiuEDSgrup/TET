/****** Object:  StoredProcedure [dbo].[wUAIaPozDatelunare]    Script Date: 01/05/2011 23:51:25 ******/
--***
create procedure [dbo].[wUAIaPozDatelunare] @sesiune varchar(30), @parXML XML
as

Declare @id_contract int,@tip varchar(2),@factura varchar(13),@data datetime,@datajos datetime,@datasus datetime 
select
	 @id_contract = isnull(@parXML.value('(/row/@id_contract)[1]','int'),0),
	 @datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
     @datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01')
	
select  p.Id as id, p.Id_contract as id_contract,RTRIM(p.tip) as tip,CONVERT(char(10),p.datajos,101) as datajos,CONVERT(char(10),p.datasus,101) as datasus,
		RTRIM(p.Saptamana)as saptamana,RTRIM(p.Tura)as tura,p.Info as info,RTRIM(p.Locatar)as locatar,RTRIM(p.Cod_serviciu)as cod_serviciu,
		convert(decimal(12,3),p.planificat)as planificat,convert(decimal(12,3),p.realizat)as realizat,convert(decimal(12,3),p.Cantitate_de_facturat)as Cantitate_de_facturat,
		convert(decimal(12,3),p.Tarif)as tarif,RTRIM(p.Document)as document,CONVERT(char(10),p.data,101) as data,RTRIM(p.cod_serviciu)+' - '+rtrim(c.Denumire) as denServiciu,
		(CONVERT(char(10),p.datajos,101)+' - '+CONVERT(char(10),p.datasus,101)) as perioada,'DL' subtip,
		rtrim(ll.nume) as denlocatar,
		(case when p.Tip='PV' then 'PV-Proces verbal' when p.Tip='CF' then 'CF-Confirmare' when p.Tip='ME' then 'ME-Minim exceptie' 
		      when p.Tip='MM' then 'MM-Minim' when p.Tip='FX' then 'FX-Cantitate Fixa' when p.Tip='EX' then 'EX-Exceptie' else '' end) as denTip,
		(case when p.Tip='PV' then '#FF0000' when p.Tip='CF' then '#C47451' when p.Tip='ME' then '#617C58' 
		      when p.Tip='MM' then '#6698FF' when p.Tip='EX' then '#000000' else '#000000' end) as culoare    

from uacantitati p left outer join NomenclAbon AS c ON c.Cod = p.Cod_serviciu 
left outer join locatari ll on p.Locatar=ll.Locatar and p.Id_contract=ll.Id_contract
                     
where p.Id_contract=@id_contract
order by p.Data  desc	
for xml raw
--select * from uacantitati
