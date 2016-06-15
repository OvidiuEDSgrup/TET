create view yso_vIaStoclim as 
select Subunitate=rtrim(sl.Subunitate)
	, Tip_gestiune=rtrim(sl.Tip_gestiune), Cod_gestiune=rtrim(sl.Cod_gestiune), Den_gestiune=rtrim(g.Denumire_gestiune)
	, Cod=rtrim(sl.Cod), Den_cod=RTRIM(n.Denumire)
	, Data=CONVERT(char(10),sl.data,126)
	, Stoc_min=convert(decimal(12,3),sl.Stoc_min)
	, Stoc_max=convert(decimal(12,3),sl.Stoc_max)
	, Pret=CONVERT(decimal(15,5),sl.pret)
	, Locatie=RTRIM(Locatie)
from Stoclim sl 
	inner join nomencl n on n.Cod=sl.Cod
	inner join gestiuni g on g.Subunitate=sl.Subunitate and g.Tip_gestiune=sl.Tip_gestiune and g.Cod_gestiune=sl.Cod_gestiune
where sl.data<'2999-01-01'
