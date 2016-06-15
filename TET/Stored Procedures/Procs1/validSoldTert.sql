
create procedure validSoldTert
as
begin try
	/*	Se lucreaza cu #validSold (tert, valoare)	*/
	declare
		@err varchar(1000)

	IF OBJECT_ID('tempdb.dbo.#vfacturi') IS NOT NULL
		DROP TABLE #vfacturi
		
	/* Luam facturile cu sold ale tertului pt. studiu: le putem afecta in SP in asa fel incat sa invalidam una sau ambele validari de mai jos (sold, scadeta)
	*/
	select
		f.Subunitate, f.Loc_de_munca, f.Tip, f.Factura, f.Tert, f.Data, f.Data_scadentei, f.Valoare, f.TVA_11, f.TVA_22, f.Valuta, f.Curs, f.Valoare_valuta, 
		f.Achitat, f.Sold, f.Cont_de_tert, f.Achitat_valuta, f.Sold_valuta, f.Comanda, f.Data_ultimei_achitari
	into #vfacturi
	from facturi f
	join #validSold vs on f.Tert=vs.tert and ABS(f.sold)>0.01 and f.tip=0x46
	
	/*	Luam soldul tertului	*/
	update vs
		set sold=df.sold
	from #validSold vs
	JOIN
	(
		select f.tert, sum(f.sold) sold
		from #vfacturi f 
		JOIN #validSold vs	on vs.tert=f.tert
		group by f.tert
	) df on df.tert=vs.tert
	
	/*	Limita de sold din terti	*/
	update vs
		set sold_max=t.Sold_maxim_ca_beneficiar
	from #validSold vs
	JOIN Terti t on t.tert=vs.tert	
	
	/*	Eventualele exceptii care ar fi	*/
	update vs
		set sold_max=es.sold_max
	from #validSold vs
	JOIN 
	(
		select et.tert tert, et.sold_max sold_max, RANK() over (partition by et.tert order by et.panala desc, et.idExceptie desc) rk
		from ExceptiiSoldTert et
		JOIN #validSold vs on et.tert=vs.tert
		where GETDATE() between et.dela and et.panala
	) es on es.rk=1 and es.tert=vs.tert	
	
	IF EXISTS(select 1 from sys.objects where name='validSoldTertSP')
		exec validSoldTertSP

	IF EXISTS (select 1 from #validSold vs join #vfacturi f on f.tert=vs.tert and f.sold>0.01 and f.data_scadentei<convert(date,getdate()))
		RAISERROR('Beneficiarul are facturi cu scadenta depasita!',16,1)

	IF EXISTS(select 1 from #validSold where valoare+sold>sold_max)
	BEGIN
		select top 1 @err = 'Beneficiarul are limita de sold ' + convert(varchar(10), convert(decimal(15,2), sold_max)) +', sold actual '+convert(varchar(10), convert(decimal(15,2), sold)) +' !' 
		from #validSold where valoare+sold>sold_max
		RAISERROR (@err, 16, 1)
	END
end try
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
