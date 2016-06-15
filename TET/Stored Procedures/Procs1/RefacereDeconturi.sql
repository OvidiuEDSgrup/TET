
create procedure RefacereDeconturi @dData datetime, @cMarca char(6), @cDecont varchar(40)
as

begin try 
	declare @Sb char(9), @parXML xml
	set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')

	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
		raiserror('RefacereDeconturi: Accesul este restrictionat pe anumite locuri de munca! Nu este permisa refacerea in aceste conditii!',16,1)

	delete deconturi where subunitate=@Sb and tip='T' and (isnull(@cMarca, '')='' or marca=@cMarca) and (isnull(@cDecont, '')='' or decont=@cDecont)

	set @parXML=(select @dData as datasus, @cMarca as marca, @cDecont as decont, 1 as grmarca, 1 as grdec, 1 as cen for xml raw)
	if object_id('tempdb..#pdeconturi') is not null 
		drop table #pdeconturi
	create table #pdeconturi (subunitate varchar(9))
	exec CreazaDiezDeconturi @numeTabela='#pdeconturi'
	exec pDeconturi @sesiune=null, @parxml=@parXML

	insert into deconturi
		(Subunitate, Tip, Marca, Decont, Cont, Data, Data_scadentei, Valoare, Valuta, Curs, 
		Valoare_valuta, Decontat, Sold, Decontat_valuta, Sold_valuta, 
		Loc_de_munca, Comanda, Data_ultimei_decontari, Explicatii)
	select
		subunitate, 'T', marca, decont, max(cont), min(data), min(data_scadentei),  sum(valoare), max(valuta), max(curs), 
		sum(valoare_valuta), sum(decontat), sum(valoare-decontat), sum(decontat_valuta), sum(valoare_valuta-decontat_valuta), 
		max(loc_de_munca), max(comanda), max(case when abs(decontat)>=0.01 or abs(decontat_valuta)>=0.01 then data else '01/01/1901' end), max(left(explicatii, 30))  
	from #pdeconturi 
	--from dbo.fDeconturiCen(null, @dData, @cMarca, @cDecont,1,1, null, 0, 0)
	group by subunitate, marca, decont
end try

begin catch
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
