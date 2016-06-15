--***
/**	functie Case de sanat.pe marci	*/
Create
function fCase_sanatate_marci  (@data datetime, @marca char(6))
returns @cassan_salariati table (marca char(6), casa_de_sanatate char(13))
as
begin
	insert @cassan_salariati
	select p.marca, 
		(case when isnull((select top 1 e.val_inf from extinfop e where e.marca=p.marca and e.cod_inf='CASASAN' and e.Val_inf<>'' 
		and e.data_inf<=@data order by e.data_inf desc),'')='' then
		isnull((case when charindex(',',p.adresa)<>0 then ltrim(rtrim(substring(p.adresa,charindex(',',p.adresa)+1,3))) else left(p.adresa,2) end),'')
		else 
		isnull((select top 1 e.val_inf from extinfop e where e.marca=p.marca and e.cod_inf='CASASAN' and e.Val_inf<>'' 
		and e.data_inf<=@data order by e.data_inf desc),'')
		end)
	from personal p
	where (@marca='' and p.marca in (select n.marca from net n where n.data=@data) or p.marca=@marca)

	return
end
