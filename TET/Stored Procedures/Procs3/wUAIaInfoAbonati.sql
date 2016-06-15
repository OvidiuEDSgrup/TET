create PROCEDURE [dbo].[wUAIaInfoAbonati]  
 @sesiune [varchar](50),  
 @parXML [xml]  
WITH EXECUTE AS CALLER
AS  
set transaction isolation level READ UNCOMMITTED  
  
 Declare  @codabonat varchar(30),@filtrucontract varchar(30),@filtrudenabonat varchar(30)  
select @codabonat=isnull(@parXML.value('(/row/@codabonat)[1]', 'varchar(30)'), '')  

select top 100 a.abonat as codabonat,rtrim(a.denumire) as denumireabonat,rtrim(a.inmatriculare) as inmatriculare,
rtrim(a.cod_fiscal) as cod_fiscal,rtrim(a.telefon) as telefon,rtrim(a.banca) as codbanca,rtrim(b.denumire) as denbanca,
rtrim(a.Cont_in_Banca) as contbanca,convert(int,a.categorie) as categorie,rtrim(a.cod_postal) as codpostal,
(case when a.categorie=1 then 'agenti juridici' else (case when a.categorie=2 then 'institurii publice' else (case when a.categorie=3 then 'populatie' else 
 (case when a.categorie=4 then 'provizioane' else (case when a.categorie=5 then 'asociatii' else 'alte' end) end) end) end) end) as dencategorie,
 RTRIM(t.denumire) as dentert,a.Platitor_tva as pltva,(case when a.platitor_tva=1 then 'DA' else 'NU' end) as denpltva
from abonati a left outer join bancibnr b on a.Banca=b.Cod
left outer join terti t on a.Tert_din_CG=t.tert
where a.abonat=@codabonat
order by a.denumire
for xml raw
