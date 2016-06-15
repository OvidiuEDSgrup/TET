--***
create function fCursInterval (@dataJos datetime, @dataSus datetime, @valuta varchar(20)=null)
returns @cursuri table (valuta varchar(20), data datetime, curs decimal(15,4))
as
begin
	declare @cursOrdonat table(valuta varchar(20), data datetime, curs decimal(15,4), rand int, dataSus datetime, original bit)
	declare @cursAnterior table(valuta varchar(20), data datetime)
	declare @valute table(valuta varchar(20), nr_ordine int)
	declare @zileT table (data datetime)
	declare @zile int
	select @zile=datediff(d,@datajos, @datasus)
	
	insert into @valute(valuta, nr_ordine)
	select valuta, row_number() over (order by valuta) from curs c
	where (@valuta is null or c.valuta=@valuta)
	group by valuta
	
	declare @nrOrdine int, @maxOrdine int
	select @nrOrdine=0, @maxOrdine=(select max(nr_ordine) from @valute)
	
	insert into @zileT(data)
	select dateadd(d,n-1,@datajos)
	from tally t
	where t.n<=@zile+1
		
	while (@nrOrdine<@maxOrdine)	--> functioneaza mai bine decat sa se faca simultan pe toate valutele daca se lucreaza cu tabela de cursuri "serioasa"
	begin
		select @nrOrdine=@nrOrdine+1
		select @valuta=valuta from @valute where nr_ordine=@nrOrdine
		
		insert into @cursAnterior(valuta, data)		--> identificarea cursurilor cele mai recente dinainte de perioada in cauza
		select valuta, max(data) from curs c where c.data<@dataJos and c.valuta=@valuta
		group by c.valuta

		insert into @cursOrdonat(valuta, data, curs, rand, dataSus, original)
		select c.valuta, c.data, c.curs, row_number() over (partition by c.valuta order by c.data) as rand, c.data dataSus, 1 original
		from curs c
		where c.data between @datajos and @datasus and c.valuta=@valuta
		union all
		select c.valuta, c.data, c.curs, 0 as rand, c.data dataSus, 1 original
		from curs c inner join @cursAnterior ca on c.data=ca.data and c.valuta=ca.valuta and c.data<@datajos
		order by 1, 2
		
		insert into @cursordonat(valuta, data, curs, rand, dataSus, original)
		select valuta, dateadd(d,1,@datasus), 0, max(c.rand)+1, dateadd(d,1,@datasus), 0 from @cursordonat c group by c.valuta
		
		update c set c.dataSus=dateadd(d,-1,co.data)
		from @cursordonat c inner join @cursordonat co on c.valuta=co.valuta and c.rand=co.rand-1
		and c.original=1
	--/*	
		insert into @cursuri (valuta, data, curs)
	--	select valuta, data, 0 from @cursAnterior a
	--	select '',data,0 from @zileT
	--	select co.valuta+convert(varchar(20),co.deNesters), co.data, co.rand from @cursordonat co
	--/*	
		select co.valuta, t.data, co.curs
		from @zileT t
			inner join @cursordonat co
				on t.data between co.data and co.dataSus	--*/
	/*	
		select co.valuta, t.data, co.curs
		from calstd t
			inner join @cursordonat co
				on t.data between co.data and co.dataSus
	--*/
		order by 1, 2

		delete @cursOrdonat
		delete @cursAnterior
	end
	
	return
end
