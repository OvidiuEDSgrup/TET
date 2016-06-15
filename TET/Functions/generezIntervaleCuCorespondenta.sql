--***

create function generezIntervaleCuCorespondenta (
	@tipint int,		--> tip interval - obligatoriu;
									--		1=luna
									--		2=decada
									--		3=saptamana
									--		4=zi
	@datajos datetime, -->	inceput interval; obligatoriu
	@datasus datetime, -->	sfarsit interval; obligatoriu
	@corespondenta int	--> tip bifa - 1 = se doresc perechi data - data_interval, 0 = se doresc doar intervale
	)
returns @r table (data datetime, dataInterval datetime)	--> dataInterval este ultima zi din interval
as
begin
	DECLARE @datains DATETIME
	set @corespondenta=isnull(@corespondenta,0)
	if (@tipint=4)
			INSERT INTO @r(data, dataInterval)		-->	zile; se genereaza la fel indiferent de par "@corespondenta"
			SELECT DATEADD(D,(t.n-1),@datajos), DATEADD(D,(t.n-1),@datajos)
			FROM tally t WHERE (t.n-2)<DATEDIFF(D,@datajos,@datasus)
	if (@corespondenta=1)	-- se genereaza intervalele, impreuna cu datele asociate; update ar fi costisitor, deci se merge doar pe insert-uri
	begin
		if (@tipint=1)
			INSERT INTO @r(data, dataInterval)		-->	luni
			SELECT DATEADD(D,(t.n-1),@datajos),
				--dbo.eom(DATEADD(D,(t.n-1),@datajos))	--> nu se foloseste aceasta varianta pentru a mari viteza de executie
				dateadd(d,-day(dateadd(M,1,dateadd(D,(t.n-1),@datajos))),dateadd(M,1,dateadd(D,(t.n-1),@datajos)))
			FROM tally t WHERE (t.n-2)<DATEDIFF(D,@datajos,@datasus)
		
		if (@tipint=2)
			INSERT INTO @r(data, dataInterval)		-->	decade
			SELECT DATEADD(D,(t.n-1),@datajos),
				(case when day(DATEADD(D,(t.n-1),@datajos))<=10 then dateadd(day,-day(DATEADD(D,(t.n-1),@datajos)),DATEADD(D,(t.n-1),@datajos))+10			--> decade
					when day(DATEADD(D,(t.n-1),@datajos))<=20 then dateadd(day,-day(DATEADD(D,(t.n-1),@datajos)),DATEADD(D,(t.n-1),@datajos))+20
					else dbo.eom(DATEADD(D,(t.n-1),@datajos)) 
					end)
			FROM tally t WHERE (t.n-2)<DATEDIFF(D,@datajos,@datasus)
		if (@tipint=3)
		INSERT INTO @r(data, dataInterval)		-->	saptamani
			SELECT DATEADD(D,(t.n-1),@datajos),
				dateadd(d,-(datepart(dw,DATEADD(D,(t.n-1),@datajos))+(@@datefirst-15))%7,DATEADD(D,(t.n-1),@datajos))
			FROM tally t WHERE (t.n-2)<DATEDIFF(D,@datajos,@datasus)
		return
	end		--> urmeaza variantele fara asociere data - data interval; e separat pentru ca e mai putin costisitor sa fie generate astfel,
				-- in cazul respectiv
	if (@tipint<='2')
	begin
		set @datains=@datajos --dateadd(m,1,@datajos)  
		set @datains=dateadd(d,-day(@datains),@datains)  

		INSERT INTO @r(data,dataInterval)							--> pe luni
		SELECT dbo.eom(DATEADD(M,t.n,@datains)), dbo.eom(DATEADD(M,t.n,@datains))
		FROM tally t WHERE t.n<=DATEDIFF(M,@datains,@datasus)

		if (@tipint='2') insert into @r					--> pe decada
		 select dateadd(d,-day(data)+10,data),dateadd(d,-day(data)+10,data) from @r
		   where dateadd(d,-day(data)+10,data) between dateadd(d,-10,@datajos) and dateadd(d,10,@datasus) group by data union all   
		 select dateadd(d,-day(data)+20,data),dateadd(d,-day(data)+20,data) from @r   
		   where dateadd(d,-day(data)+20,data) between dateadd(d,-10,@datajos) and dateadd(d,10,@datasus) group by data  
		 return
	END
		declare @pas int
		if (@tipint='3')									--> pe saptamani
			begin
			 set @datains=dateadd(d,-(datepart(dw,@datajos)+(@@datefirst-15))%7,@datajos)
			 set @pas=7
			end

	IF @tipint ='3'
	INSERT INTO @r
	SELECT DATEADD(D,(t.n-1)*@pas,@datains), DATEADD(D,(t.n-1)*@pas,@datains)
	FROM tally t WHERE (t.n-2)*@pas<DATEDIFF(D,@datains,@datasus)
	return
	  -- pana aici am ales datele in care ne intereseaza soldul  
end
