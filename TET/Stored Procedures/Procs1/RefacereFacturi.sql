--***
/*	exemplu de apel
	exec RefacereFacturi @cFurnBenef='F', @dData='07/31/2014', @cTert=null, @cFactura=null
*/
create procedure RefacereFacturi @cFurnBenef char(1)='', @dData datetime='2999-12-31', @cTert char(13)=null, @cFactura char(20)=null
as
 begin try

	declare @Sb char(9), @parXML xml
	
	set @Sb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'),'')

	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)

		raiserror('RefacereFacturi: Accesul este restrictionat pe anumite locuri de munca! Nu este permisa refacerea in aceste conditii!',16,1)

	IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'tr_validfacturi') AND type='TR')
		alter table facturi disable trigger tr_validfacturi

	delete facturi 
	where subunitate=@Sb 
		and (isnull(@cFurnBenef, '')='' or tip=(case when @cFurnBenef='B' then 0x46 else 0x54 end)) 
		and (isnull(@cTert, '')='' or tert=@cTert) and (isnull(@cFactura, '')='' or factura=@cFactura)
/*
	insert into facturi (Subunitate, Loc_de_munca, Tip, Factura, Tert, Data, Data_scadentei, Valoare, 
	TVA_11, TVA_22, Valuta, Curs, Valoare_valuta, Achitat, Sold, Cont_de_tert, Achitat_valuta, Sold_valuta, 
	Comanda, Data_ultimei_achitari)
	select subunitate, loc_de_munca, (case when a.tip='B' then 0x46 else 0x54 end), factura, tert, data, 
	data_scadentei, valoare, 0, tva, valuta, curs, valoare_valuta, achitat, sold, cont_factura, 
	achitat_valuta, sold_valuta, comanda, data_ultimei_achitari
	from dbo.fFacturiCen(@cFurnBenef, '01/01/1921', @dData, @cTert, @cFactura, null, null, null, null, null, null) a
	where not exists (select 1 from facturi f where f.subunitate=a.subunitate and f.tip=(case when 
	a.tip='B' then 0x46 else 0x54 end) and f.tert=a.tert and f.factura=a.factura)
*/
	if object_id('tempdb..#pfacturi') is not null 
		drop table #pfacturi
	create table #pfacturi (subunitate varchar(9))
	exec CreazaDiezFacturi @numeTabela='#pfacturi'

	set @parXML=(select @cFurnBenef as furnbenef, '01/01/1921' as datajos, convert(char(10),@dData,101) as datasus, 1 as cen, rtrim(@cTert) as tert, rtrim(@cFactura) as factura for xml raw)
	exec pFacturi @sesiune=null, @parXML=@parXML

	insert into facturi (Subunitate, Loc_de_munca, Tip, Factura, Tert, Data, Data_scadentei, Valoare, TVA_11, TVA_22, 
		Valuta, Curs, Valoare_valuta, Achitat, Sold, Cont_de_tert, Achitat_valuta, Sold_valuta, Comanda, Data_ultimei_achitari)
	select subunitate, loc_de_munca, tip, factura, tert, data, data_scadentei, valoare, 0, tva, 
		valuta, curs, valoare_valuta, achitat, sold, cont_factura, 	achitat_valuta, sold_valuta, comanda, data_ultimei_achitari
	from #pfacturi a
	where not exists (select 1 from facturi f where f.subunitate=a.subunitate and f.tip=a.tip and f.tert=a.tert and f.factura=a.factura)

	IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'tr_validfacturi') AND type='TR')
		alter table facturi enable trigger tr_validfacturi
end try

begin catch
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
