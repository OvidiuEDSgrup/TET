select left(capitol,1) as capitol, 
	capitol as subcapitol,
	rand_decont, 
	denumire_indicator, 
	valoare,
	tva
from deconttva 
	where data between '10/01/2012' and '10/31/2012'
order by capitol, 
	convert(int,(case when CHARINDEX('.',Rand_decont)<>0 then LEFT(Rand_decont,CHARINDEX('.',Rand_decont)-1) else (case when Rand_decont in ('NREVIDPL','CEREALE','INTERNE','RAMBURSTVA') then 100 else Rand_decont end) end))