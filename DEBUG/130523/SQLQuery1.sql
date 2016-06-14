--exec yso_rapJurnalTvaLaIncasare @cFurnBenef= 'F', @datajos='2013-04-01', @datasus='2013-04-30', @tert=null, @factura=null, @loc_de_munca=null

select tert,factura,'SI',sold,baza,*
		from SoldFacturiTLI 
		where datalunii='2013-03-31' and tipf='f'
			--and (@tert is null or tert=@tert) and (@factura is null or factura=@factura)

select * from ##fTli
where tip='SI'

select rulaj_debit_tli=f.rd, sold_initial_tli=f.si
,*
	from ##jurnalTLI,
		(select tert,factura,sum(case when tip='RD' then suma else 0 end) as rd,
			sum(case when tip='SI' then suma else 0 end) as si 
		from ##fTli group by tert,factura) f 
	where ##jurnalTLI.tert=f.tert and ##jurnalTLI.Factura=f.factura
	and isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)<isnull(rulaj_credit_tli,0)	
	


select doc_incasare=a.numar,data_incasare=a.data,rulaj_credit_tli=a.suma,suma_incasata=a.achitat
,*
	from ##jurnalTLI,
		(select f.tert,f.factura,max(isnull(d.numar,f.factura)) as numar,max(isnull(d.data,'1901-01-01')) as data,
				max(f.suma) as suma,sum(isnull(d.achitat,f.baza)) as achitat
			from ##fTli f
			left outer join ##doctert d on f.tert=d.tert and f.factura=d.factura and abs(d.achitat)>0.01
			where f.tip='RC' group by f.tert,f.factura) a where a.tert=##jurnalTLI.tert and a.factura=##jurnalTLI.Factura
		and isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)<isnull(rulaj_credit_tli,0)	


	select sold_tli=isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)-isnull(rulaj_credit_tli,0),
		baza_sold_tli=(isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)-isnull(rulaj_credit_tli,0))*
			(case when tva=0 then 0 else baza/tva end)
,*
	from ##jurnalTLI
	where abs(isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)-isnull(rulaj_credit_tli,0))>0.01
	and isnull(sold_initial_tli,0)+isnull(rulaj_debit_tli,0)<isnull(rulaj_credit_tli,0)
	
	
	
	
	