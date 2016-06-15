
CREATE PROCEDURE wACProforme @sesiune VARCHAR(50), @parXML XML
AS
begin
	DECLARE	@searchText VARCHAR(200), @tert varchar(100), @codAvans varchar(100), @STPRINC int
	
	SET @searchText = '%'+replace(ISNULL(@parXML.value('(/*/@searchText)[1]', 'varchar(80)'), ''), ' ', '%')+'%'
	SET @tert = @parXML.value('(/*/@tert)[1]', 'varchar(80)')
	
	--stare in care proforma se poate incasa
	exec luare_date_par 'GE','STPRINC',0,0,@STPRINC OUTPUT

	select pr.idContract, pr.numar, pr.data ,pr.tert, convert(decimal(17,2),0) as valoare_proforma, convert(decimal(17,2),0) as incasat_proforma, pr.valuta
	into #proforme
	from contracte pr
		outer apply(select top 1 stare from JurnalContracte j where j.idContract=pr.idContract order by data desc, idJurnal desc) st
	where pr.tip='PR'
		and (@tert is null or pr.tert=@tert)
		and st.stare=@STPRINC
		and (pr.numar LIKE @searchText OR pr.explicatii LIKE @searchText)

	--calculez valoarea proformelor
	update p set valoare_proforma=isnull(v.val_proforma,0)
	from #proforme p
		cross apply (select sum(pc.cantitate*pc.pret
							--daca proforma in RON sau proforma in valuta si tert extern si neplatitor de TVA, adaug si suma tva
							+(case when isnull(c.valuta,'')='' or (isnull(c.valuta,'')<>'' and t.tert_extern=1 and isnull(ttva.tip_tva,'P')='N') then pc.cantitate*pc.pret*((n.Cota_TVA)/ 100) 
							else 0 end)) as val_proforma 
					from pozcontracte pc 
						inner join contracte c on c.idcontract=pc.idcontract
						inner join nomencl n on n.cod=pc.cod
						inner join terti t on t.tert=p.tert
						outer apply(select top 1 tip_tva from TvaPeTerti tv where tv.tert=t.tert and p.data>tv.dela order by dela desc) ttva
					where pc.idContract=p.idContract) v 
		
	--calculez cat s-a incasat pe fiecare proforma in parte
	update p set incasat_proforma=isnull(inc.achitat,0)
	from #proforme p
		outer apply (select SUM(case when isnull(f.valuta,'')<>'' then f.achitat_valuta else f.Achitat end) as achitat
					from facturi f
						inner join (select distinct pd.factura, pd.tert, pd.Data_facturii
									from JurnalContracte jc
										JOIN LegaturiContracte lc on jc.idJurnal=lc.idJurnal and lc.idPozContract is null and lc.idPozContractCorespondent is null and jc.idContract=p.idContract
										join pozdoc pd on pd.subunitate='1' and pd.idpozdoc=lc.idPozDoc) ft
							on ft.factura=f.Factura and ft.tert=f.Tert and ft.Data_facturii=f.Data and f.Tip=0x46
			) inc

	--sterg proformele care au fost deja incasate total
	delete from #proforme
	where abs(valoare_proforma-incasat_proforma)<0.1

	SELECT top 25
		pr.idContract AS cod, 
		RTRIM(pr.numar) + '/' + replace(CONVERT(VARCHAR(10), pr.data, 103),'/','-')+ISNULL('('+rtrim(t.denumire)+')','') 
			+', Sold:  ' + RTRIM(isnull(valoare_proforma,0)-isnull(incasat_proforma,0)) AS denumire , 
		'Val: ' + rtrim(isnull(valoare_proforma,0)) +', Inc: '+rtrim(isnull(incasat_proforma,0)) + isnull(', Valuta: '+ rtrim(pr.valuta),'') AS info
	FROM #proforme pr
		inner JOIN terti t ON t.tert = pr.tert and t.Subunitate='1'
	FOR XML raw, root('Date')
end
