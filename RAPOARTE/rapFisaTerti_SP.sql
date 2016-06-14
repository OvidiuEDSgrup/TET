--***	Procedura pentru raportul CG\Financiar\Fisa terti si Fisa terti pe intervale
/**	--> exemplu de apel:
	exec rapFisaTerti_SP @sesiune='',@cFurnBenef=N'F',@cData='2014-12-31',@cTert=NULL,@judet=NULL,@cFactura=null,@cContTert=NULL,@soldmin=N'0.01',@soldabs=0,@dDataFactJos=NULL,@dDataFactSus=NULL,
	@dDataScadJos=NULL,@dDataScadSus=NULL,@aviz_nefac=N'0',@grupa=NULL,@grupa_strict=N'0',@exc_grupa=NULL,@fsolddata1=0,@comanda=NULL,@indicator=NULL,@cDataJos=NULL,@tipdoc=N'F',@locm=NULL,@punctLivrare=NULL,@fsold=0,
	@moneda=N'0',@valuta=NULL,@centralizare=N'0',@gestiune=NULL,@soldcumulat=0,@ordonare=N'0',@grupare=N'GR'

	
*/
if exists (select * from sysobjects where name ='rapFisaTerti_SP')
drop procedure rapFisaTerti_SP
go
--***
CREATE procedure rapFisaTerti_SP AS

set transaction isolation level read uncommitted
declare @q_eroare varchar(1000)
set @q_eroare=''

begin try
	--alter table #fisa add categ_yso varchar(50) null
/*	
	select sursa,
		rtrim(f.denumire) denumire, oras, furn_benef, f.subunitate, f.tert, rtrim(factura) factura, tip,
		rtrim(numar) numar, data,
		soldi, valoare, tva, total, achitat, valuta, curs, rtrim(loc_de_munca) loc_de_munca,
		left(comanda,20) comanda, rtrim(cont_de_tert) cont_de_tert, fel, rtrim(cont_coresp) cont_coresp
		, rtrim(explicatii) explicatii,
		numar_pozitie,
		gestiune, data_facturii, data_scadentei, nr_dvi, barcod, pozitie, peSold, soldf, sold_cumulat,
		soldi_valuta, valoare_valuta, tva_valuta, total_valuta, achitat_valuta, soldf_valuta,
		sold_cumulat_valuta, ordonare, f.indicator indicator,
		rtrim(t.grupa) as gtert, rtrim(g.denumire) dengtert, rtrim(l.denumire) as denlm,
		rtrim(t.grupa) as grupa, rtrim(i.descriere) as den_pctlivrare, grupare1, denumire1,
		grupare2, denumire2
--*/ update f set categ_yso=
			(case when f.cont_de_tert like '411%' and f.cont_coresp like '472%' then 'Facturi avans'
				when (f.cont_de_tert like '5311%' or f.cont_de_tert like '512%') and f.cont_coresp like '472%' then 'Incasari avans'
				when f.cont_de_tert like '411%' and (f.cont_coresp like '707.1%' or f.cont_coresp like '4427%')  then 'Facturi marfa'
				when f.cont_de_tert like '411%' and (f.cont_coresp like '70[48]%' or f.cont_coresp like '4427%')  then 'Facturi servicii'
				when f.cont_de_tert like '411%' and (f.cont_coresp like '70[48]%' or f.cont_coresp like '44271%')  then 'Facturi servicii'
				else categ_yso end)
	from #fisa f left join terti t on t.subunitate=f.subunitate and f.tert=t.tert
		left join gterti g on t.grupa=g.grupa
		left join lm l on f.loc_de_munca=l.cod
		left join infotert i on i.subunitate=t.subunitate and i.tert=f.tert and i.identificator=f.nr_dvi
	
end try
begin catch
	set @q_eroare=ERROR_MESSAGE()+' (rapFisaTerti_SP)'
end catch
	
	--> erorile in reporting nu apar, asa ca se vor returna ca date, urmand ca in raport sa se trateze situatia:
if (@q_eroare<>'')
	raiserror(@q_eroare,16,1)	
