
create procedure RefacereEfecte @dData datetime, @cTipEf char(1), @cTert char(13), @cEfect varchar(40)
as
 begin try
	declare @Sb char(9)
	set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')

	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
		raiserror('RefacereEfecte: Accesul este restrictionat pe anumite locuri de munca! Nu este permisa refacerea in aceste conditii!',16,1)
		return
	end

	delete efecte where subunitate=@Sb and (isnull(@cTipEf,'')='' or tip=@cTipEf) and (isnull(@cTert, '')='' or tert=@cTert) and (isnull(@cEfect, '')='' or nr_efect=@cEfect)

	insert into efecte 
	(Subunitate, Tip, Tert, Nr_efect, Cont, Data, Data_scadentei, 
	Valoare, Valuta, Curs, Valoare_valuta, Decontat, Sold, Decontat_valuta, Sold_valuta, 
	Loc_de_munca, Comanda, Data_decontarii, Explicatii)
	select subunitate, tip_efect, tert, efect, max(cont), max(data_efect), max(data_scadentei), 
	sum(valoare), max(valuta), max(curs), sum(valoare_valuta), sum(achitat), sum(valoare-achitat), sum(achitat_valuta), sum(valoare_valuta-achitat_valuta), 
	max(loc_de_munca), max(comanda), max(case when abs(achitat)>=0.01 or abs(achitat_valuta)>=0.01 then data else '01/01/1901' end), max(left(explicatii, 30))
	from dbo.fEfecte(null, @dData, @cTipEf, @cTert, @cEfect, null, null, null, null)
	group by subunitate, tip_efect, tert, efect
end try
begin catch
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
