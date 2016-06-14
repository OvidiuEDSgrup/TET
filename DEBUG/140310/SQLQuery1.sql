select isnull(dateadd(d, 0, 0), a.Data_bon)
,it.Discount,* from antetBonuri a left join infotert it on it.subunitate='1' and it.tert=a.Tert and it.identificator=''
order by a.IdAntetBon desc