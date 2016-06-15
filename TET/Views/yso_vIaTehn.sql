create view yso_vIaTehn as
select Cod_tehn, Denumire
	, Tip_tehn, CASE t.Tip_tehn WHEN 'M' THEN 'Material' WHEN 'P' THEN 'Produs' WHEN 'S' THEN 'Serviciu prestat' ELSE 'Altele' END as Den_tip_tehn
from tehn t
