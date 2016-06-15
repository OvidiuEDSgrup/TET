
create procedure yso_validezDateGenDoc @sesiune varchar(50), @parXML xml OUTPUT
as

declare @utilizator varchar(20),@sub varchar(9),@tipCon varchar(2),@data datetime,@contract varchar(20),@tert varchar(13),
	@numarDoc varchar(13),@dataDoc datetime,@tipDoc varchar(2)

begin try
	select @tipCon=ISNULL(@parXML.value('(/*/@tip)[1]', 'varchar(2)'), ''),
		@data=ISNULL(@parXML.value('(/*/@data)[1]', 'datetime'), ''),
		@contract=ISNULL(@parXML.value('(/*/@numar)[1]', 'varchar(20)'), ''),
		@tert=ISNULL(@parXML.value('(/*/@tert)[1]', 'varchar(13)'), ''),
		@tipDoc=ISNULL(@parXML.value('(/*/@tipdoc)[1]', 'varchar(2)'), ''),
		@dataDoc=ISNULL(@parXML.value('(/*/@datadoc)[1]', 'datetime'), ''),
		@numarDoc=ISNULL(@parXML.value('(/*/@numardoc)[1]', 'varchar(13)'), '')
	
	declare @codstocinsuficient varchar(20), @stocinsuficient float, @msgErr nvarchar(2048)
		,@lRezStocBK bit, @cListaGestRezStocBK CHAR(200)

	EXEC luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@lRezStocBK OUTPUT, @val_n=0, @val_a=@cListaGestRezStocBK OUTPUT

	select @msgErr=isnull(@msgErr+CHAR(13),'')+RTRIM(max(n.denumire))+' ('+RTRIM(p.Cod)+')'
			+', lipsa: '+ rtrim(CONVERT(decimal(10,2),MAX(isnull(x.cant_doc,p.Cantitate))-SUM(isnull(s.Stoc,0))))
	FROM pozcon p 
		inner join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert and c.Data=p.Data
		left join #xmlDateGenDoc x on x.subunitate=p.Subunitate and x.tip=p.Tip and x.contract=p.Contract 
						and x.data=p.Data and x.tert=p.Tert and x.cod=p.Cod and x.numar_pozitie=p.Numar_pozitie 
		left join nomencl n on n.Cod=p.Cod
		left JOIN stocuri s 
			ON p.Subunitate=s.Subunitate and p.Cod=s.Cod and s.Stoc>=0.001 
				and s.Cod_gestiune=x.gestiune
	WHERE p.Subunitate=@Sub and p.Tip='BK' and p.Contract=@contract and p.Data=@data and p.Tert=@tert
		AND n.Tip<>'S'
		AND (s.Stoc is null 
			or s.Tip_gestiune NOT IN ('F','T') and (s.contract=p.contract 
				or s.contract<>p.contract 
					and (@lRezStocBK=0 or CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(@cListaGestRezStocBK)+';')<=0)))
	GROUP BY p.Cod
	having SUM(isnull(s.Stoc,0))<MAX(isnull(x.cant_doc,p.Cantitate))-max(p.Cant_realizata)
	
	if len(@msgErr)>0
	begin
		set @msgErr='Stoc insuficient la articolele: '++CHAR(13)+@msgErr	
		raiserror(@msgErr,16,1)
	end
	
	declare @valFactura float=0, @soldmaxim float, @sold float, @zileScadDepasite bit
	
	select	@valFactura = 
		sum(round(round(convert(decimal(17,5),p.pret*(1-p.discount/100)*(1-isnull(pe.pret,0)/100)*(1-isnull(pe.cantitate,0)/100))
		*(1+(p.cota_tva-case when isnull(gp.tip_gestiune,'') in ('A','V') then p.cota_tva else 0 end)/100),2)
		*(isnull(x.cant_doc,p.Cantitate)-isnull(x.cant_generata,(case when @tipDoc='TE' then p.Pret_promotional else p.cant_realizata end))),2))
	from pozcon p
		left join #xmlDateGenDoc x on x.subunitate=p.Subunitate and x.tip=p.Tip and x.contract=p.Contract 
						and x.data=p.Data and x.tert=p.Tert and x.cod=p.Cod and x.numar_pozitie=p.Numar_pozitie 
		left join pozcon pe on pe.Subunitate='EXPAND' and pe.Tip=p.Tip and pe.Contract=p.Contract and pe.Tert=p.Tert and pe.Data=p.Data and pe.Cod=p.Cod      
		left join gestiuni gp on gp.cod_gestiune = p.Punct_livrare
	where p.Subunitate=@sub and p.Tip='BK' and p.Contract=@contract and p.Data=@data and p.Tert=@tert 
	
	if isnull(@valFactura,0) > 0.001
	begin
		declare @xml xml
		set @xml=(select @tert tert for xml raw)
		exec wIaSoldTert @sesiune='', @parXML=@xml output
		
		-- procedura returneaza null daca nu trebuie validat soldul
		if @xml is not null
		begin 
			select	@sold=@xml.value('(/row/@sold)[1]','float'),
					@soldmaxim=@xml.value('(/row/@soldmaxim)[1]','float'),
					@zileScadDepasite= @xml.value('(/row/@zilescadentadepasite)[1]','bit')
			
			if @zileScadDepasite=1
				set @msgErr = isnull(@msgErr+CHAR(13),'')+'Tertul are facturi cu scadenta depasita.'
			
			if @xml.value('(/row/@soldmaxim)[1]','float') is not null and @sold+@valFactura>@soldmaxim
				set @msgErr = isnull(@msgErr+CHAR(13),'')+'Generarea facturii ar cauza depasirea soldului maxim pentru acest tert.'
					+CHAR(13)+ 'Soldul maxim permis este '+ CONVERT(varchar(30), convert(decimal(12,2), @soldmaxim)) + ' RON.'
					+CHAR(13)+ 'Soldul anterior este '+ CONVERT(varchar(30), convert(decimal(12,2), @sold)) + ' RON.'
					+CHAR(13)+ 'Valoarea pozitiei (modificarii) curente '+ CONVERT(varchar(30), convert(decimal(12,2), @valFactura)) + ' RON.'
			
			if len(@msgErr)>0
			begin
				raiserror(@msgErr,11,1)
			end
		end
	end
end try 
begin catch 
	declare @eroare varchar(250)
	set @eroare='(yso_validezDateGenDoc): '+ERROR_MESSAGE() 
	raiserror(@eroare, 16, 1)
end catch 