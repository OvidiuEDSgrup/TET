exec sp_executesql N'declare @q_ContJos varchar(13),@q_ContSus varchar(13),@q_pLuna int,@q_pAn int,@q_lb_den varchar(2),@q_valuta varchar(20), @q_curs float
	,@q_tipb varchar(20)
	,@q_tipBalanta smallint
	,@q_conturiRecompuse int
	,@q_indicator varchar(100)

select @q_ContJos=@ContJos, @q_ContSus=@ContSus, @q_pLuna=MONTH(@data), @q_pAn=year(@data), @q_lb_den=@limba, @q_valuta=@valuta 
	,@q_curs=isnull((case when @curs=0 then 1 else @curs end),1), @q_tipb=@tipb
	,@q_tipBalanta=@tipBalanta, @q_conturiRecompuse=@conturiRecompuse,@q_indicator=@indicator

exec rapBalantaContabilaLocm @contjos=@q_ContJos,@contsus=@q_ContSus, @pLuna=@q_pLuna, @pAn=@q_pAn, @limba=@q_lb_den, @valuta=@q_valuta,
	@curs=@q_curs, @cLM=@locm, @tipb=@q_tipb, @tipBalanta=@q_tipBalanta, @conturiRecompuse=@q_conturiRecompuse, @indicator=@q_indicator',N'@ContJos nvarchar(5),@ContSus nvarchar(18),@data datetime,@valuta nvarchar(4000),@curs nvarchar(4000),@locm nvarchar(4000),@tipb nvarchar(4000),@tipBalanta int,@limba nvarchar(4000),@conturiRecompuse int,@indicator nvarchar(4000)',