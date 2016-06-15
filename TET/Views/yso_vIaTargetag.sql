create view yso_vIaTargetag as 
select Agent=rtrim(ta.Agent), Denumire_agent=rtrim(lm.Denumire)
	, Client=rtrim(ta.Client), Denumire_client=RTRIM(t.Denumire)
	, Grupa_produs=RTRIM(ta.Produs), Denumire_grupa=RTRIM(g.Denumire)
	, Pct_livr=rtrim(ta.UM)
	, Data_lunii=convert(varchar(10),ta.Data_lunii,101)
	, Cantitate_valoare=convert(decimal(15,2),ta.Comision_suplimentar)
	-- select *
from Targetag ta 
	left join lm on lm.Cod=ta.Agent
	left join terti t on t.tert=ta.Client
	left join grupe g on g.Grupa=ta.Produs
