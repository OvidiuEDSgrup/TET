create view yso_vIaTehnpoz as 
select tp.Cod_tehn, rtrim(t.Denumire) as Den_tehn
	, tp.Tip, CASE tp.Tip WHEN 'M' THEN 'Material' WHEN 'R' THEN 'Rezultat' ELSE 'Altele' END as Den_tip
	, tp.Cod, RTRIM(n.Denumire) as Den_cod
	, tp.Nr
	, rtrim(tp.Subtip) as Tip_resursa, CASE tp.Tip WHEN 'M' THEN 'Material' WHEN 'P' THEN 'Produs' ELSE 'Altele' END as Den_tip_resursa
	, tp.Specific as Consum_specific
from tehnpoz tp 
	inner join tehn t on t.Cod_tehn=tp.Cod_tehn
	inner join nomencl n on n.Cod=tp.Cod
