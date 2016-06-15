--***
/**	functie mod de plata la data	*/
Create function fMod_plata_la_data 
	(@data datetime, @marca char(6))
returns @mod_plata table 
	(marca char(6), banca char(30))
as
begin
	insert @mod_plata
	select p.marca, 
		(case when isnull((select top 1 e.val_inf from extinfop e where e.marca=p.marca and e.cod_inf='BANCA' and e.Val_inf<>'' 
			and e.data_inf<=@data order by e.data_inf desc),'')='' then p.Banca
		else 
			isnull((select top 1 e.val_inf from extinfop e where e.marca=p.marca and e.cod_inf='BANCA' and e.Val_inf<>'' 
			and e.data_inf<=@data order by e.data_inf desc),'')
		end)
	from personal p
	where (@marca='' and p.marca in (select n.marca from net n where n.data=@data) or p.marca=@marca)

	return
end
