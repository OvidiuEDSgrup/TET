--***
create function fCalculSolduri(@data datetime)
returns @solduri table(subunitate varchar(20), cont varchar(40), loc_de_munca varchar(20), valuta varchar(20), debit decimal(15,4), credit decimal(15,4))
begin
	declare @datajos datetime
	select @datajos=convert(varchar(20),year(@data))+'-1-1'

	insert into @solduri(subunitate, cont, loc_de_munca, valuta, debit, credit)
	select 
		r.subunitate, r.cont, r.loc_de_munca, r.valuta, 
		(case when max(c.Tip_cont)='P' then 0 when max(c.Tip_cont)='A' then sum(rulaj_debit)-sum(rulaj_credit) else 
				(case when sum(rulaj_debit)-sum(rulaj_credit)>0 then sum(rulaj_debit)-sum(rulaj_credit) else 0 end)
			end) as debit,
		(case when max(c.Tip_cont)='A' then 0 when max(c.Tip_cont)='P' then -sum(rulaj_debit)+sum(rulaj_credit) else 
				(case when sum(rulaj_debit)-sum(rulaj_credit)>0 then 0 else -sum(rulaj_debit)+sum(rulaj_credit) end)
			end) as credit
	from rulaje r left join conturi c on r.cont=c.Cont
	where r.data between @datajos and @data
	group by r.subunitate, r.cont, r.loc_de_munca, r.valuta
	order by r.subunitate, r.cont, r.loc_de_munca, r.valuta
	return
end
