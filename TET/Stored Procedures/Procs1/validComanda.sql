create procedure validComanda
as
begin try
	/** 
		Procedura valideaza set-uri de date: comanda din tabela #comenzi(comanda,data)
		Se valideaza:
			- existenta in catalog
			- validare strica in functie de parametru
		Se va valid si in raport cu data din tabela VALIDCAT pe tip=COMANDA
		
	*/
	declare @validcomstrict int, @msgEroare varchar(8000)
	select top 1 @validcomstrict=val_numerica from par where tip_parametru='GE' and parametru = 'COMANDA'
	
	
	if @validcomstrict=1 and exists(select 1 from #comenzi where comanda='')
		raiserror('Comanda necompletata!',16,1)
	
	if exists(select 1 from #comenzi c1 left join comenzi cc on cc.Comanda=c1.comanda  where  c1.comanda<>'' and cc.comanda IS null) 
	begin
		select @msgEroare=isnull(@msgEroare+', ','Comanda inexistenta in catalog: ')+ rtrim(c1.comanda)
		from #comenzi c1 left join comenzi cc on cc.Comanda=c1.comanda  where  c1.comanda<>'' and cc.comanda IS null
		
		set @msgEroare=@msgEroare+'.'

		raiserror(@msgEroare,16,1)
	end	

	----validare operare documente pe comenzi inchise
	--if exists(select 1 from #comenzi c1 left join comenzi cc on cc.Comanda=c1.comanda  where  c1.comanda<>'' and cc.Starea_comenzii='I') 
	--begin
	--	select @msgEroare=isnull(@msgEroare+', ','Nu se pot opera documente pe comenzi inchise: ')+ rtrim(c1.comanda)
	--	from #comenzi c1 left join comenzi cc on cc.Comanda=c1.comanda  where  c1.comanda<>''and cc.Starea_comenzii='I'
		
	--	set @msgEroare=@msgEroare+'.'

	--	raiserror(@msgEroare,16,1)
	--end	

end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validComanda)'
	raiserror(@mesaj, 16,1)
end catch
