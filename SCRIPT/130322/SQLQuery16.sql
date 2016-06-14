declare @codstocinsuficient varchar(20), @stocinsuficient float, @msgErr nvarchar(2048)
			,@lRezStocBK bit, @cListaGestRezStocBK CHAR(200)
	EXEC luare_date_par @tip='GE', @par='REZSTOCBK', @val_l=@lRezStocBK OUTPUT, @val_n=0, @val_a=@cListaGestRezStocBK OUTPUT

	select s.Contract,s.Tip_gestiune,s.Stoc,s.Cod_gestiune,p.Cant_aprobata-p.Cant_realizata,*--@msgErr=isnull(@msgErr+CHAR(13),'')+RTRIM(max(n.denumire))+' ('+RTRIM(p.Cod)+')'+', lipsa: '+ rtrim(CONVERT(decimal(10,2),MAX(p.Cant_aprobata)-isnull(SUM(s.Stoc),0)))
	FROM pozcon p 
		inner join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Tert=p.Tert and c.Data=p.Data
		left join nomencl n on n.Cod=p.Cod
		left JOIN stocuri s 
			ON p.Subunitate=s.Subunitate and p.Cod=s.Cod and (s.Cod_gestiune=p.Factura and c.Stare='1' or s.Cod_gestiune=c.Cod_dobanda and c.Stare='4')
	WHERE s.Cod in ('00610612','5090 018000000')
	and p.Subunitate='1' and p.Tip='BK' and p.Contract='9820957' and p.Data='2013-01-11' and p.Tert='15976734     '
		AND n.Tip<>'S'
		AND (s.Stoc is null 
or s.Tip_gestiune NOT IN ('F','T') --AND s.Stoc>=0.001 
--and (s.contract=p.contract 
	--and s.contract<>p.contract and (@lRezStocBK=0 or CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(@cListaGestRezStocBK)+';')<=0)
	)
		
	order by s.cod
	--GROUP BY p.Cod
	--having isnull(SUM(s.Stoc),0)<MAX(p.Cant_aprobata-p.Cant_realizata)
	
--select @msgErr