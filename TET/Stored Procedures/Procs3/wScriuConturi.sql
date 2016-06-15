
CREATE procedure wScriuConturi @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@iDoc int, @Sub char(9), @mesaj varchar(200), @cont varchar(40), @contParinte varchar(40), @referinta int, @tabReferinta int, @mesajEroare varchar(100), 
		@inexistent int, @faraAnalitice int,@detalii xml

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output  
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	IF OBJECT_ID('tempdb..#xmlconturi') IS NOT NULL
		drop table #xmlconturi

	select 
		isnull(ptupdate, 0) as ptupdate, upper(cont) as cont, isnull(cont_vechi, cont) as cont_vechi, denumire as denumire, tip, cont_parinte, are_analitice, apare_in_balanta_sintetica, 
		apare_in_balanta_de_raportare, atribuire, nivel, artcalc, valuta,detalii
		into #xmlconturi
		from OPENXML(@iDoc, '/row')
		WITH
		(
			detalii xml 'detalii/row',
			ptupdate int '@update', 
			cont varchar(40) '@cont', 
			cont_vechi varchar(40) '@o_cont', 
			denumire char(80) '@dencont', 
			tip char(1) '@tipcont', 
			cont_parinte varchar(40) '@parinte', 
			are_analitice int '@areanalitice', 
			apare_in_balanta_sintetica int '@apareinbalsint', 
			apare_in_balanta_de_raportare int '@apareinbalrap', 
			atribuire int '@atribuire', 
			nivel int '@nivel', 
			artcalc char(9) '@artcalc',
			valuta varchar(20) '@valuta'
		)
		exec sp_xml_removedocument @iDoc 

		-- salvarea detaliilor e tratata doar la importul unui singur cont
		select top 1 @detalii= detalii from #xmlconturi

		if exists (select 1 from #xmlconturi where isnull(cont, '')='')
			raiserror('Cont necompletat', 16, 1)

		select @cont=x.cont
		from #xmlconturi x, conturi c
		where c.subunitate=@Sub and c.cont=x.cont and (x.ptupdate=0 or x.ptupdate=1 and x.cont<>x.cont_vechi)
		if @cont is not null
		begin
			set @mesajEroare='Contul ' + RTrim(@cont) + ' este deja introdus'
			raiserror(@mesajEroare, 16, 1)
		end
	
		select @referinta=dbo.wfRefConturi(x.cont_vechi), 
			@cont=(case when @referinta>0 and @cont is null then x.cont_vechi else @cont end), 
			@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
		from #xmlconturi x
		where x.ptupdate=1 and x.cont<>x.cont_vechi
		if @cont is not null
		begin
			set @mesajEroare='Contul ' + RTrim(@cont) + ' are ' + (case @tabReferinta when 1 then 'analitice' when 2 then 'rulaje' when 3 then 'inregistrari' else 'documente' end)
			raiserror(@mesajEroare, 16, 1)
		end
	
		update x
		set cont_parinte=isnull((select max(c.cont) from conturi c where c.subunitate=@Sub and c.are_analitice=1 and x.cont like RTrim(c.cont)+'%' and len(c.cont)<len(x.cont)), '')
		from #xmlconturi x
		where x.ptupdate=0 and isnull(cont_parinte, '')='' and len(cont)>3

		select @cont=cont from #xmlconturi where cont=isnull(cont_parinte, '')
		if @cont is not null
		begin
			set @mesajEroare='Cont parinte nu poate fi egal cu cont ('+rtrim(@cont)+')!'
			raiserror(@mesajEroare, 16, 1)
		end

		select @cont=cont from #xmlconturi where len(cont)>3 and isnull(cont_parinte, '')=''
		if @cont is not null
		begin
			set @mesajEroare='Cont parinte necompletat pentru contul ' + RTrim(@cont)
			raiserror(@mesajEroare, 16, 1)
		end

		select @cont=x.cont, @inexistent=(case when c.cont is null then 1 else 0 end), 
			@faraAnalitice=(case when isnull(c.are_analitice, -1)=0 then 1 else 0 end)
		from #xmlconturi x
		left outer join conturi c on c.subunitate=@Sub and c.cont=x.cont_parinte
		where x.cont_parinte<>'' and (len(x.cont)<=3 or c.cont is null or c.are_analitice=0)
		if @cont is not null
		begin
			set @mesajEroare='Cont parinte ' + (case when @inexistent=1 then 'inexistent' when @faraAnalitice=1 then 'nedeclarat cu analitice' else 'incorect' end) 
				+ ' pentru contul ' + RTrim(@cont)
			raiserror(@mesajEroare, 16, 1)
		end
		
		/* Validare: sa nu se poata culege la cont parinte, un alt cont in afara celor de nivel superior contului introdus */
		
		select @cont=cont, @contParinte=cont_parinte from #xmlconturi where rtrim(cont) not like rtrim(cont_parinte)+'%'		
		if @contParinte is not null
		begin
			set @mesajEroare='Contul parinte introdus ('+rtrim(@contParinte)+') nu poate fi grup pentru contul ('+rtrim(@cont)+')!'
			raiserror(@mesajEroare, 16, 1)
		end

		update x
		set denumire=(case when x.ptupdate=1 or x.denumire is not null then x.denumire else isnull(cp.denumire_cont, '') end), 
			tip=(case when x.ptupdate=1 or x.tip is not null then x.tip else isnull(cp.tip_cont, 'A') end), 
			apare_in_balanta_sintetica=(case when x.ptupdate=1 or x.apare_in_balanta_sintetica is not null then x.apare_in_balanta_sintetica 
				when len(rtrim(x.cont))<=4 then 1 else x.apare_in_balanta_sintetica end), 
			apare_in_balanta_de_raportare=(case when x.ptupdate=1 or x.apare_in_balanta_de_raportare is not null then x.apare_in_balanta_de_raportare 
				when x.apare_in_balanta_sintetica=1 then 1 else x.apare_in_balanta_de_raportare end), 
			atribuire=(case when x.ptupdate=1 or x.atribuire is not null then x.atribuire else isnull(cp.sold_credit, 0) end), 
			nivel=(case when x.ptupdate=0 or x.cont<>x.cont_vechi then isnull(cp.nivel, 0)+1 else null end)
		from #xmlconturi x
			left join conturi cp on x.cont_parinte<>'' and cp.subunitate=@Sub and cp.cont=x.cont_parinte

		insert conturi
		(Subunitate, Cont, Denumire_cont, Tip_cont, Cont_parinte, Are_analitice, Apare_in_balanta_sintetica, Sold_debit, 
		Sold_credit, Nivel, Articol_de_calculatie, Logic, detalii)
		select @Sub, x.cont, isnull(x.denumire, ''), isnull(x.tip, ''), 
			isnull(x.cont_parinte, ''), isnull(x.are_analitice, 0), isnull(x.apare_in_balanta_sintetica,0), isnull(x.apare_in_balanta_de_raportare,0),  
			isnull(x.atribuire, 0), isnull(x.nivel, 0), isnull(x.artcalc, ''), (case when isnull(x.artcalc, '')='' then 0 else 1 end), x.detalii
		from #xmlconturi x
		where x.ptupdate=0

		update c
		set cont=isnull(x.cont, c.cont), denumire_cont=isnull(x.denumire, c.denumire_cont), 
			tip_cont=isnull(x.tip, c.tip_cont), cont_parinte=isnull(x.cont_parinte, c.cont_parinte), 
			are_analitice=isnull(x.are_analitice, c.are_analitice), apare_in_balanta_sintetica=isnull(x.apare_in_balanta_sintetica, c.apare_in_balanta_sintetica), 
			sold_debit=isnull(x.apare_in_balanta_de_raportare, c.sold_debit), 
			sold_credit=isnull(x.atribuire, c.sold_credit), 
			nivel=isnull(x.nivel, c.nivel), articol_de_calculatie=isnull(x.artcalc, c.articol_de_calculatie),
			logic=(case when isnull(x.artcalc, c.articol_de_calculatie)='' then 0 else 1 end),
			c.detalii=x.detalii
		from conturi c, #xmlconturi x
		where x.ptupdate=1 and c.subunitate=@Sub and c.cont=x.cont_vechi
	
		--proprietate "in valuta"
		delete pr from proprietati pr inner join #xmlconturi c on c.cont=pr.Cod
		where pr.Tip='CONT' AND pr.Cod_proprietate='INVALUTA' and c.valuta=''
	
		update pr set valoare=c.valuta
		from proprietati pr
		inner join #xmlconturi c on c.cont=pr.Cod
		where pr.Tip='CONT' AND pr.Cod_proprietate='INVALUTA' and c.valuta<>''
	
		insert proprietati (Tip,Cod,Cod_proprietate,Valoare,Valoare_tupla)
		select 'CONT',C.cont,'INVALUTA',C.valuta,''
		from #xmlconturi C
		LEFT OUTER JOIN proprietati pr on pr.Tip='CONT' AND cod=c.cont and Cod_proprietate='INVALUTA'
		where pr.Tip is null and c.valuta<>''

		
		IF OBJECT_ID('tempdb..#xmlconturi') IS NOT NULL
			drop table #xmlconturi

end try
begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
