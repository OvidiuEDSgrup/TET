--***
create procedure rapAnexaPenalitatiDobanzi(@datajos datetime, @datasus datetime, @tert varchar(13),@contract varchar(20),
	@tipPen char(1)/*P- penalitati, D- dobanzi, T-toate*/,@factura_generata varchar(20), @factura_penalizata varchar(20),@stare varchar(1)/*P-provizorie, F-facturat, T- toate*/,
	@valid int/*1- valid, 0-invalid, 2- toate*/, @lm varchar(13))
as
begin
	select @datajos=isnull(@datajos,@datasus)
	select p.tip as tip, p.Tert, rtrim(t.denumire) denumire, replace(rtrim(ltrim(p.Factura_penalizata)),'I','')as Factura_penalizata,p.Tip_doc_incasare,
		rtrim(ltrim(p.Nr_doc_incasare)) as Nr_doc_incasare, CONVERT(char(10),p.data_doc_incasare,103) as data_doc_incasare,
		convert(decimal(17,2),p.Sold_penalizare) as sold_penalizare, CONVERT(char(10),p.Data_penalizare,103) as Data_penalizare, p.Zile_penalizare,
		convert(decimal(17,2),p.Suma_penalizare)as Suma_penalizare, CONVERT(char(10),isnull(f.data,s.Data_facturii),103) as data_fact_penalizata, 
		CONVERT(char(10),isnull(f.Data_scadentei,s.Data_scadentei),103) as data_scad_fact_penalizata,			
		p.tip_penalizare,p.Stare,p.valid,p.contract_coresp,p.procent_penalizare, rtrim(p.loc_de_munca) as lm, rtrim(ltrim(p.factura_generata)) as factura_generata,
		convert(char(10),p.data_factura_generata,103) as data_factura_generata, rtrim(ltrim(p.punct_livrare)) as punct_livrare,
		
		/*case when p.tip_penalizare='D' then convert(varchar(20),convert(money,round(p.sold_penalizare,2)))+'x'+
				convert(varchar(20),p.zile_penalizare)+'('+convert(varchar(20),dateadd(day,-zile_penalizare,p.data_doc_incasare)+1,4)+'-'+
				convert(varchar(20),p.data_doc_incasare,4)+')x'+isnull(rtrim(p.procent_penalizare),'0.04')+'/100='+
				convert(varchar(20),convert(money,p.suma_penalizare))			
			else case when p.tip_penalizare='P' then convert(varchar(20),convert(money,round(p.sold_penalizare,2)))+'x'+
				case when p.zile_penalizare>30 and p.zile_penalizare<=90 and p.tip_doc_incasare<>'NE' then '5%' 
					when p.zile_penalizare>=90 and p.tip_doc_incasare='NE'  then '15%' end+
				'='+convert(varchar(20),convert(money,p.suma_penalizare)) else '' end end as mod_calcul,
		*/		
		case when p.tip_penalizare='D' or (isnull(p.procent_penalizare,0.02)=0.02 and p.tip_penalizare='P') then convert(varchar(20),convert(money,round(p.sold_penalizare,2)))+'x'+
				convert(varchar(20),p.zile_penalizare)+'('+convert(varchar(20),dateadd(day,-zile_penalizare,p.data_doc_incasare)+1,4)+'-'+
				convert(varchar(20),p.data_doc_incasare,4)+')x'+isnull(rtrim(p.procent_penalizare),'0.04')+'/100='+
				convert(varchar(20),convert(money,p.suma_penalizare))			
			else case when p.tip_penalizare='P' then convert(varchar(20),convert(money,round(p.sold_penalizare,2)))+'x'+
				case when p.zile_penalizare>30 and p.zile_penalizare<=90 and p.tip_doc_incasare<>'NE' then '5%' 
					when p.zile_penalizare>=90 and p.tip_doc_incasare='NE'  then '15%' end+
				'='+convert(varchar(20),convert(money,p.suma_penalizare)) else '' end end as mod_calcul	
	from penalizarifact p 
		left join facturi f on f.Factura=p.Factura_penalizata and f.Tert=p.Tert and f.Tip=0x46
		outer apply (select top 1 k.Subunitate,k.tip,k.Factura,k.data,k.Data_facturii,k.Data_scadentei, k.Cod_tert, k.Contractul from doc k  
				where k.Subunitate='1' and p.Factura_penalizata=k.factura and p.tert=k.cod_tert and k.tip in ('AP','AS') order by data)s	
		left join terti t on p.Tert=t.Tert and t.subunitate='1'
	where p.Data_penalizare between @datajos and @datasus
		and (p.Tert=@tert or ISNULL(@tert,'')='')
		and (p.loc_de_munca=@lm or ISNULL(@lm,'')='')
		and (p.contract_coresp=@contract or ISNULL(@contract,'')='')
		and (p.factura_generata=@factura_generata or ISNULL(@factura_generata,'')='')
		and (p.Factura_penalizata=@factura_penalizata or ISNULL(@factura_penalizata,'')='')
		and (p.tip_penalizare=@tipPen or @tipPen='T')
		and (p.Stare=@stare or @stare='T') 
		and (p.valid=@valid or @valid=2) 		
	order by t.Denumire, p.Factura_penalizata, p.tip_penalizare,p.Data_penalizare
end

/*
select * from penalizarifact
*/
