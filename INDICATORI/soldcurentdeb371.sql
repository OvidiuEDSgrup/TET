--select c.data_lunii,--Loc_de_munca,
--select Rul_prec_debit+Rul_curent_debit+Sold_inc_an_debit-Sold_inc_an_credit
--	-(Rul_prec_credit+Rul_curent_credit+0),*
select r.data_lunii,--max(r.Cont),r.Loc_de_munca,
sum(r.rul_curent)+(select rul_prec=isnull(sum(round(convert(decimal(15,3),round((Rulaj_debit-Rulaj_credit),2)),2)),0)
	from rulaje 
	where valuta='' and cont=max(r.Cont) and Data>=rtrim(YEAR(r.Data_lunii))+'-01-01'
		and Data<rtrim(YEAR(r.Data_lunii))+'-'+rtrim(MONTH(r.Data_lunii))+'-01') 
from (select c.data_lunii,cont,Loc_de_munca,
		sum(round(convert(decimal(15,3), round((rulaj_debit-Rulaj_credit),2)),2)) as rul_curent
	from rulaje r inner join CalStd c on c.Data=r.Data
	where valuta='' and cont like '371'
	group by c.data_lunii,cont,Loc_de_munca) r
where 1=1
EXPANDEZ({r.data_lunii})
--where Data between RTRIM(c.An)+'-01-01' and c.Data_lunii 
--and Data_lunii between '2012-08-01' and '2012-08-31'
group by r.data_lunii--,r.Loc_de_munca
having r.Data_lunii='2012-08-31'

