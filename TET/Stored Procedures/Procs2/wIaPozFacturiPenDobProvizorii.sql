--***
create procedure wIaPozFacturiPenDobProvizorii @sesiune varchar(50), @parXML xml 
as  
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wIaPozFacturiPenDobProvizoriiSP')
begin 
	declare @returnValue int 
	exec @returnValue = wIaPozFacturiPenDobProvizoriiSP @sesiune, @parXML output
	return @returnValue
end
Declare @tip varchar(2),@tert varchar(13),@datajos datetime,@datasus datetime,@mesaj varchar(200),@utilizator varchar(20),@doc xml,@sub int,
	@lista_lm int, @filtruLm varchar(50),@_cautare varchar(200)
begin try
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT

	select @lista_lm=dbo.f_areLMFiltru(@utilizator)

	select
		@datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
		@datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01'),
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(3)'),'')	,
		@tert = isnull(@parXML.value('(/row/@tert)[1]','varchar(13)'),''),
		@filtruLm = isnull(@parXML.value('(/row/@filtruLm)[1]','varchar(50)'),''),
		@_cautare= isnull(@parXML.value('(/row/@_cautare)[1]','varchar(200)'),'')
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	
	/*select (case when p.tip = 'SI' then 'Fara contract' else rtrim(isnull(c.Contract_coresp,c1.contract))end) as contract,
		'Contract: ' + (case when p.tip = 'SI' then 'Fara contract' else rtrim(isnull(c.Contract_coresp,c1.contract))end) as con_fact
	into #contr
	from penalizarifact p
		left join doc s on s.Subunitate=@sub and s.tip=p.tip and p.factura_penalizata=s.factura and p.tert=s.cod_tert	
		left join con c on c.subunitate=@sub and c.Tip='BK' and s.Contractul =c.Contract and p.Tert=c.Tert 
		left join con c1 on c.subunitate=@sub and c1.Tip='BF' and s.Contractul=c1.Contract and p.Tert=c1.Tert 
	where p.Tert=@tert
		and p.Data_penalizare between @datajos and @datasus	
		--and p.stare in ('P','A')
	group by (case when p.tip = 'SI' then 'Fara contract' else rtrim(isnull(c.Contract_coresp,c1.contract))end)

select * from #contr

	set @doc=(select rtrim(p1.contract) as contract,'Contract: ' + rtrim(p1.contract) as con_fact,		
		(select rtrim(isnull(rtrim(p.factura_generata)+' - facturat',rtrim(p.Factura)+' - nefacturat')) as con_fact,p.tip as tip_doc_pen,RTRIM(p.Tert) as tert, rtrim(p.Factura) as factura,rtrim(p.Factura_penalizata)as factura_penalizata,p.Tip_doc_incasare as tip_doc_incasare, 
			RTRIM(p.Nr_doc_incasare) as nr_doc_incasare,CONVERT(char(10),p.Data_doc_incasare,101)as data_doc_incasare, convert(decimal(17,2),p.Sold_penalizare)as sold_penalizare,
			CONVERT(char(10),p.Data_penalizare,101)as data_penalizare,p.Zile_penalizare as zile_penalizare, convert(decimal(17,2),p.Suma_penalizare)as suma_penalizare,
			CONVERT(char(10),f.data,101)as data_fact_penalizata,p.tip_penalizare as tip_penalizare,
			case when tip_penalizare='D' then 'Dobanzi'  else 'Penalitati' end  as dentip_pen ,p.stare as stare,
			(case when p.valid=0 or p.Stare='F' then '#A4A4A4'  else (case when tip_penalizare='D' then '#0B3B0B'  else '#0B0B61' end) end)  as culoare, 
			case when Tip_doc_incasare='IB' then 'Incasat prin chitanta nr. '+rtrim(p.Nr_doc_incasare)+' din data '+ CONVERT(char(10),p.Data_doc_incasare,101)
				when Tip_doc_incasare='NE' then 'Neincasat' when Tip_doc_incasare='NE' then 'Compensat cu fact.'+rtrim(p.Nr_doc_incasare)+' din data '+ CONVERT(char(10),p.Data_doc_incasare,101)
				when Tip_doc_incasare='C3' then 'Compensat in 3' end as stare_fact_pen,'PD' as subtip,p.valid as validare
		from penalizarifact p
			left join doc s1 on s1.Subunitate=@sub and s1.tip=p.Tip and p.factura_penalizata=s1.factura and p.tert=s1.cod_tert	
			left join con c1 on c1.subunitate=@sub and c1.Tip='BK' and (p.Factura_penalizata =c1.Contract or s1.Contractul=c1.Contract) and p.Tert=c1.Tert  
				and c1.Contract_coresp=rtrim(p1.contract)		
			inner join facturi f on f.Subunitate=@sub and f.Tip=0x46 and p.Factura_penalizata=f.Factura and p.Tert=f.Tert			
		where p.Tert=@tert
			and p.Data_penalizare between @datajos and @datasus
			and (c1.Contract_coresp=p1.contract or (p.Tip='SI' and p1.contract='Fara contract'))
			--and p.stare in ('P','A')
		order by p.Factura	
		for xml raw, type)	
	from #contr p1
	for xml raw, root('Ierarhie'))*/
	
	select @_cautare
	
	select (case when ISNULL(p.contract_coresp,'')<>'' then rtrim(ltrim(p.contract_coresp)) else 'Fara Contract' end) as contract
	into #contr
	from penalizarifact p
	where p.Tert=@tert
		and p.Data_penalizare between @datajos and @datasus	
		and (p.Factura_penalizata like rtrim(@_cautare)+'%' or ISNULL(@_cautare,'')='')
		--and p.stare in ('P','A')
	group by (case when ISNULL(p.contract_coresp,'')<>'' then rtrim(ltrim(p.contract_coresp)) else 'Fara Contract' end)
	
	set @doc=(select rtrim(p1.contract) as contract,'Contract: ' + rtrim(p1.contract) as con_fact,		
		(select case when p.Stare='F' then rtrim(p.factura_generata)+' - facturat' else rtrim(p.Factura)+' - nefacturat' end as con_fact,
			p.tip as tip_doc_pen,RTRIM(p.Tert) as tert, rtrim(p.Factura) as factura,
			rtrim(p.Factura_penalizata)as factura_penalizata,p.Tip_doc_incasare as tip_doc_incasare, 
			RTRIM(p.Nr_doc_incasare) as nr_doc_incasare,CONVERT(char(10),p.Data_doc_incasare,101)as data_doc_incasare, convert(decimal(17,2),p.Sold_penalizare)as sold_penalizare,
			CONVERT(char(10),p.Data_penalizare,101)as data_penalizare,p.Zile_penalizare as zile_penalizare, convert(decimal(17,2),p.Suma_penalizare)as suma_penalizare,
			CONVERT(char(10),isnull(f.data,s.data_facturii),101)as data_fact_penalizata,
			p.tip_penalizare as tip_penalizare,
			case when tip_penalizare='D' then 'Dob.'  else 'Pen.' end  as dentip_pen ,p.stare as stare,
			(case when p.valid=0 or p.Stare='F' then '#A4A4A4'  else (case when tip_penalizare='D' then '#0B3B0B'  else '#0B0B61' end) end)  as culoare, 
			case when Tip_doc_incasare='IB' then 'Inc. chitanta nr. '+rtrim(p.Nr_doc_incasare)+' din data '+ CONVERT(char(10),p.Data_doc_incasare,103)
				when Tip_doc_incasare='NE' then 'Neincasat' when Tip_doc_incasare='NE' then 'Compensat cu fact.'+rtrim(p.Nr_doc_incasare)+' din data '+ CONVERT(char(10),p.Data_doc_incasare,103)
				when Tip_doc_incasare='C3' then 'Compensat in 3' end as stare_fact_pen,'PD' as subtip,p.valid as validare,
			
			case when p.tip_penalizare='D' or (isnull(p.procent_penalizare,0.02)=0.02 and p.tip_penalizare='P') then convert(varchar(20),convert(money,round(p.sold_penalizare,2)))+'x'+
				convert(varchar(20),p.zile_penalizare)+'('+convert(varchar(20),dateadd(day,-zile_penalizare,p.data_doc_incasare)+1,4)+'-'+
				convert(varchar(20),p.data_doc_incasare,4)+')x'+isnull(rtrim(p.procent_penalizare),'0.04')+'/100='+
				convert(varchar(20),convert(money,p.suma_penalizare))			
			else case when p.tip_penalizare='P' then convert(varchar(20),convert(money,round(p.sold_penalizare,2)))+'x'+
				case when p.zile_penalizare>30 and p.zile_penalizare<=90 and p.tip_doc_incasare<>'NE' then '5%' 
					when p.zile_penalizare>=90 and p.tip_doc_incasare='NE'  then '15%' end+
				'='+convert(varchar(20),convert(money,p.suma_penalizare)) else '' end end as mod_calcul,
			convert(varchar(10),ISNULL(f.Data_scadentei,s.Data_scadentei),101) as data_scadenta_fact_pen	
				
			/*case when p.tip_penalizare='P' then convert(varchar(20),convert(money,round(p.sold_penalizare,2)))+'x'+
				case when p.zile_penalizare>30 and p.zile_penalizare<=90 and p.tip_doc_incasare<>'NE' then '5%' 
					when p.zile_penalizare>=90 and p.tip_doc_incasare='NE'  then '15%' end+
				'='+convert(varchar(20),convert(money,p.suma_penalizare)) else '' end
			*/	
		from penalizarifact p
			left join facturi f on f.Subunitate=@sub and f.Tip=0x46 and p.Factura_penalizata=f.Factura and p.Tert=f.Tert	
			outer apply (select top 1 k.Subunitate,k.tip,k.Factura,k.data,k.Data_facturii,k.Data_scadentei, k.Cod_tert, k.Contractul from doc k  
				where k.Subunitate='1' and p.Factura_penalizata=k.factura and p.tert=k.cod_tert and k.tip in ('AP','AS') order by data)s	
			left join terti t on p.Tert=t.Tert and t.subunitate='1'
			left join lm on lm.Cod=p.loc_de_munca		
			left join lmfiltrare lu on lu.utilizator=@utilizator and lu.cod=p.loc_de_munca
		where p.Tert=@tert
			and (@lista_lm=0 OR p.loc_de_munca IS null or lu.cod is not null)
			and (p.loc_de_munca like @filtruLm+'%' or lm.Denumire like '%'+@filtruLm+'%' and ISNULL(@filtruLm,'')<>'')
			and (p.Factura_penalizata like rtrim(@_cautare)+'%' or ISNULL(@_cautare,'')='')
			and p.Data_penalizare between @datajos and @datasus
			and (p.Contract_coresp=p1.contract or (p1.contract='Fara contract' and isnull(p.contract_coresp,'')=''))
			and p.Data_penalizare between @datajos and @datasus	
			--and p.stare in ('P','A')
		order by p.Factura	
		for xml raw, type)	
	from #contr p1
	for xml raw, root('Ierarhie'))	

if @doc is not null
	set @doc.modify('insert attribute _expandat {"da"} into (/Ierarhie)[1]')

select @doc for xml path('Date')   	 	

end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
