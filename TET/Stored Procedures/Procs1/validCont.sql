create procedure validCont
as
begin try
	/*
		Se valideaza din #cont (cont, cont_coresp,data)
			- existenta in catalog
			- existenta analiticelor
			- cont necompletat
	*/
	declare 
		@eroare varchar(max)
	
	select ISNULL(cont,'') cont into #contcen from #cont group by cont

	select c.cont 
	into #contErr
	from #contcen c LEFT JOIN conturi cc on c.cont=cc.cont WHERE cc.cont is null and c.cont<>''

	if (select count(*) from #contErr)>0
	begin
		select @eroare = 'Cont inexistent in planul de conturi!'+ char(10) +' Cont, Tip doc., Numar, Data ' + char(10)+
			STUFF((select distinct rtrim(c.cont) +', ' + ct.tip + ', '+ ct.numar + + ', '+ convert(varchar(10), ct.data, 103) +char(10) from #contErr c JOIN #cont ct on ct.cont=c.cont for xml PATH(''),type).value('.','VARCHAR(MAX)'),1,0,'')+char(10)
		raiserror(@eroare,16,1)
	end

	select c.cont 
	into #contErrAn
	from #contcen c
	LEFT JOIN conturi cc on cc.Cont=c.cont and cc.Are_analitice='0' 
	where cc.cont is null and c.cont<>''

	if (select count(*) from #contErrAn)>0
	begin
		select @eroare = 'Contul introdus are analitice!'+ char(10) +' Cont, Tip doc., Numar, Data ' + char(10)+
			STUFF((select distinct rtrim(c.cont) +', ' + ct.tip + ', '+ ct.numar + + ', '+ convert(varchar(10), ct.data, 103) +char(10) from #contErrAn c JOIN #cont ct on ct.cont=c.cont for xml PATH(''),type).value('.','VARCHAR(MAX)'),1,0,'')+char(10)		
		raiserror(@eroare,16,1)		
	end

	/** Conturi invalidate prin operatia de invalidare */
	select c.cont, c.data
	into #contInv
	from #cont c inner join conturi cc on cc.Cont = c.cont
	where c.data between cc.detalii.value('(/row/@data_invalid_jos)[1]', 'datetime') and cc.detalii.value('(/row/@data_invalid_sus)[1]', 'datetime')
	
	if (select count(*) from #contInv) > 0
	begin
		select @eroare = 'Nu se poate opera pe acest(e) cont(uri): ' +
			STUFF((select distinct rtrim(c.cont) + ' ' from #contInv c for xml path(''), type).value('.', 'varchar(max)'), 1, 0, '') + 'Declarat(e) invalid(e)!'
		raiserror(@eroare, 16, 1)
	end
	
end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validCont)'
	raiserror(@mesaj, 16,1)
end catch
