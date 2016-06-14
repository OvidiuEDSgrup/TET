select * from par p where p.Parametru='210.bv'
select * from proprietati r where r.tip='UTILIZATOR' and cod='filiala_bv' and cod_proprietate in ('GESTPV') and valoare<>'' and r.Valoare_tupla=''
select top 1 a.Val_alfanumerica,dbo.fStrToken(a.Val_alfanumerica,1,';') 
from proprietati p inner join par a on a.Tip_parametru='PG' and a.Parametru=p.Valoare
where p.tip='UTILIZATOR' and p.cod='filiala_bv' and cod_proprietate in ('GESTPV') and valoare<>'' and p.Valoare_tupla=''
			and p.Valoare='210.bv'