create view yso_vIaPreturi as 
select rtrim(cod_produs) as cod,
	RTRIM(n.denumire) as dencod,
	rtrim(cp.Categorie) as catpret,
	rtrim(cp.Denumire) as 'dencategpret',
	rtrim(p.tip_pret) as tippret,
	dtp.denumire as dentippret,
	convert(char(10),data_inferioara,101) as data_inferioara,
	convert(char(10),data_superioara,101) as data_superioara,
	convert(decimal(12,3),p.Pret_vanzare) as pret_vanzare,
	convert(decimal(12,3),p.Pret_cu_amanuntul) as pret_cu_amanuntul
from preturi p
	inner join categpret cp on p.UM=cp.Categorie
	inner join dbo.fTipPret() dtp on p.tip_pret=dtp.tipPret
	left join dbo.nomencl n on n.Cod=p.Cod_produs
	--left outer join fPropUtiliz() fp on cod_proprietate='CATEGPRET' and categorie=fp.valoare
--where p.Cod_produs=@cod
	--and rtrim(cp.Denumire) like @cautare
	--and (@lista_categpret=0 OR fp.valoare is not null)
--order by convert(char(10),data_inferioara,101) desc
