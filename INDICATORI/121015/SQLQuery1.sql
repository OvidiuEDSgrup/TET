select *--SUM(e.Valoare) 
from Expval e 
--full join ##tmpmvb t on t.indicator=e.Cod_indicator and t.tip=e.Tip and t.data_lunii=e.Data
--and t.echipa=e.Element_1 and t.agent=e.Element_2 and t.client=e.Element_3 and t.grupa=e.Element_4 and t.articol=e.Element_5
where e.Cod_indicator='vmb' --and e.Data='2012-08-31'

select * from ##tmpmvb 