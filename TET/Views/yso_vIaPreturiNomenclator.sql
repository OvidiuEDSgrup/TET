create view [yso_vIaPreturiNomenclator] as
select rtrim(cod_produs) as cod,
--rtrim(n.denumire) as dencod,
cp.categorie as catpret,
rtrim(cp.Denumire) as dencategpret,
rtrim(p.tip_pret) as tippret,
CASE Tip_pret WHEN '1' THEN 'Pret standard' WHEN '2' THEN 'Pret promo' WHEN '9' THEN 'Pret impus' ELSE '' END as dentippret,
convert(datetime,convert(date,data_inferioara)) as data_inferioara,
convert(datetime,convert(date,data_superioara)) as data_superioara,
convert(decimal(12,3),p.Pret_vanzare) as pret_vanzare,
convert(decimal(12,3),p.Pret_cu_amanuntul) as pret_cu_amanuntul,
CONVERT(nvarchar(500),'') as _eroareimport
from dbo.preturi p
left join dbo.categpret cp on p.UM=cp.Categorie
left join dbo.nomencl n on n.Cod=p.Cod_produs 
--where p.Cod_produs like '143808CUIAC2X20Ÿ'
