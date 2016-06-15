
--***

create procedure inregDocAccizeProd @sesiune varchar(50), @parXML xml 
as
declare @Sub char(9), @cContAcc varchar(40)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
exec luare_date_par 'GE', 'CACCIZE', 1, 1, @cContAcc output

begin try
	if object_id('tempdb..#accizeProd') is not null 
		drop table #accizeProd

	select p.Subunitate, p.tip, p.numar, p.data, max(p.utilizator) as utilizator, p.cont_venituri, p.Loc_de_munca, p.comanda, max(p.jurnal) as jurnal,
		max(p.data_operarii) as data_operarii, max(p.ora_operarii) as ora_operarii, max(p.cont_factura) as cont_factura, 
		convert(decimal(17,5), max(ic.suma_inreg)) - (sum(p.Cantitate)*sum(p.accize_datorate)) as valoare, --sum(p.Cantitate)*sum(p.accize_datorate) as acciza
		sum(p.Cantitate*p.accize_datorate) as acciza
	into #accizeProd
	from pozdoc p 
	inner join #pozdoc pd on p.subunitate=pd.subunitate and p.tip=pd.tip and p.numar=pd.numar and p.data=pd.data and p.idPozDoc=pd.idPozDoc
--	citesc valoarea inregistrarilor contabile generate prin inregDoc din tabela temporara
	outer apply (select sum(round(convert(decimal(17,5), suma), 2)) as suma_inreg 
		from #pozincon po where po.subunitate = p.subunitate and po.tip = p.tip and po.numar = p.numar and po.data = p.data and po.cont_creditor=p.cont_venituri and po.Loc_de_munca=p.Loc_de_munca and po.Comanda=p.Comanda
				and po.TipInregistrare ='VENFACTURA') ic 
	where p.subunitate = @Sub and p.tip in ('AP') 
	group by p.Subunitate, p.tip, p.numar, p.data, p.cont_venituri, p.comanda, p.Loc_de_munca

	insert into #pozincon (TipInregistrare, Subunitate, Tip, Numar, Data, Valuta, Curs, Suma_valuta, Utilizator, Loc_de_munca, Comanda, Jurnal, 
		Cont_debitor, Cont_creditor, Suma, Explicatii, Data_operarii, Ora_operarii)
	select 'ACCIZE', ap.Subunitate, ap.Tip, ap.Numar, ap.Data, '', 0, 0, ap.utilizator, ap.Loc_de_munca, ap.Comanda, ap.jurnal,
		ap.Cont_factura, @cContAcc, ap.acciza, 'ACCIZE', ap.data_operarii, ap.ora_operarii
	from #accizeProd ap

	update p set Suma = ap.valoare
	from #pozincon p, #accizeProd ap
	where ap.subunitate = p.subunitate and ap.tip = p.tip and ap.numar = p.numar and ap.data = p.data and p.cont_creditor=ap.cont_venituri and ap.Loc_de_munca=p.Loc_de_munca and ap.Comanda=p.Comanda
		and p.Subunitate = @Sub and p.Tip = 'AP' and p.TipInregistrare ='VENFACTURA'
	
end try

begin catch
	declare @mesaj varchar(500)
	set @mesaj = ERROR_MESSAGE() + ' (inregDocAccizeProd)'
	raiserror(@mesaj, 11, 1)
end catch

if object_id('tempbd..#accizeProd') is not null
	drop table #accizeProd


