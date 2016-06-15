create view yso_vIaProprietati as 
select pr.Tip
	, pr.Cod
	, Denumire_cod=rtrim(coalesce(n.denumire,t.denumire,''))
	, pr.Cod_proprietate
	, pr.Valoare
	, pr.Valoare_tupla
	-- select *
from Proprietati pr 
	left join tipproprietati tp on tp.Tip=pr.Tip and tp.Cod_proprietate=pr.Cod_proprietate
	left join catproprietati cp on cp.Cod_proprietate=pr.Cod_proprietate
	left join nomencl n on pr.Tip='NOMENCL' and n.Cod=pr.Cod
	left join terti t on pr.Tip='TERT' and t.tert=pr.Cod
