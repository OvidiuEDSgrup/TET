USE [TET]
GO
/****** Object:  Table [dbo].[pozcon]    Script Date: 12/17/2011 15:20:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pozcon]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[pozcon](
	[Subunitate] [char](9) NOT NULL,
	[Tip] [char](2) NOT NULL,
	[Contract] [char](20) NOT NULL,
	[Tert] [char](13) NOT NULL,
	[Punct_livrare] [char](13) NOT NULL,
	[Data] [datetime] NOT NULL,
	[Cod] [char](30) NOT NULL,
	[Cantitate] [float] NOT NULL,
	[Pret] [float] NOT NULL,
	[Pret_promotional] [float] NOT NULL,
	[Discount] [real] NOT NULL,
	[Termen] [datetime] NOT NULL,
	[Factura] [char](25) NOT NULL,
	[Cant_disponibila] [float] NOT NULL,
	[Cant_aprobata] [float] NOT NULL,
	[Cant_realizata] [float] NOT NULL,
	[Valuta] [char](3) NOT NULL,
	[Cota_TVA] [real] NOT NULL,
	[Suma_TVA] [float] NOT NULL,
	[Mod_de_plata] [char](8) NOT NULL,
	[UM] [char](1) NOT NULL,
	[Zi_scadenta_din_luna] [smallint] NOT NULL,
	[Explicatii] [char](200) NOT NULL,
	[Numar_pozitie] [int] NOT NULL,
	[Utilizator] [char](10) NOT NULL,
	[Data_operarii] [datetime] NOT NULL,
	[Ora_operarii] [char](6) NOT NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozcon]') AND name = N'Cod')
CREATE NONCLUSTERED INDEX [Cod] ON [dbo].[pozcon] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Cod] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[pozcon]') AND name = N'Principal')
CREATE UNIQUE NONCLUSTERED INDEX [Principal] ON [dbo].[pozcon] 
(
	[Subunitate] ASC,
	[Tip] ASC,
	[Contract] ASC,
	[Tert] ASC,
	[Cod] ASC,
	[Data] ASC,
	[Numar_pozitie] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  Trigger [delpozprod]    Script Date: 12/17/2011 15:20:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[delpozprod]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[delpozprod] on [dbo].[pozcon] for delete not for replication as
begin
	delete pozprod
	from pozprod, deleted 
	where deleted.tip=''BK'' and deleted.contract=pozprod.comanda_livrare and deleted.tert=pozprod.beneficiar 
		and deleted.data=pozprod.data_comenzii and deleted.cod=pozprod.cod
end
'
GO
/****** Object:  Trigger [delpozaprov]    Script Date: 12/17/2011 15:20:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[delpozaprov]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[delpozaprov] on [dbo].[pozcon] for delete not for replication as
begin
	delete from pozaprov where pozaprov.tip=''BK'' and exists (select 1 from deleted 
		where deleted.tip=''BK'' and deleted.contract=pozaprov.comanda_livrare and deleted.tert=pozaprov.beneficiar and deleted.data=pozaprov.data_comenzii and deleted.cod=pozaprov.cod)
	delete from pozaprov where exists (select 1 from deleted 
		where deleted.tip=''FC'' and deleted.contract=pozaprov.contract and deleted.tert=pozaprov.furnizor and deleted.data=pozaprov.data and deleted.cod=pozaprov.cod)
end'
GO
/****** Object:  Trigger [livrpozprod]    Script Date: 12/17/2011 15:20:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[livrpozprod]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[livrpozprod] on [dbo].[pozcon] for insert, update, delete not for replication as
begin
declare @cSb char(9), @cComProd char(20), @cCod char(20), @cComLivr char(20), @dLivr datetime, @cBenef char(13), 
	@nCantRealizata float, @nCantDescarc float, @nCantRealizBK float, @nCantLivrata float 
set @cSb=isnull((select max(val_alfanumerica) from par where tip_parametru=''GE'' and parametru=''SUBPRO''), '''')
--realizat BK=>livrat pozprod
declare tmpcmdaprov cursor for
select isnull(i.contract, d.contract) as cntr, isnull(i.data, d.data) as data, isnull(i.tert, d.tert) as tert, 
isnull(i.cod, d.cod) as cod, sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0)) as diferenta 
from inserted i full outer join deleted d on i.subunitate=d.subunitate and i.tip=d.tip and i.contract=d.contract 
	and i.data=d.data and i.tert=d.tert and i.cod=d.cod 
where isnull(i.subunitate, d.subunitate)=@cSb and isnull(i.tip, d.tip)=''BK'' 
group by isnull(i.contract, d.contract), isnull(i.data, d.data), isnull(i.tert, d.tert), isnull(i.cod, d.cod)
having abs(sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0))) >= 0.001
open tmpcmdaprov
fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
while @@fetch_status = 0
begin
	declare tmppozprod cursor for
	select p.comanda, cantitate_realizata, cantitate_livrata
	from pozprod p
	left outer join comenzi c on c.subunitate=@cSb and c.comanda=p.comanda
	where comanda_livrare=@cComLivr and data_comenzii=@dLivr and p.beneficiar=@cBenef and p.cod=@cCod
	order by datediff(day, getdate(), isnull(c.data_lansarii, ''12/31/2999'')) * sign(@nCantRealizBK) 
	open tmppozprod
	fetch next from tmppozprod into @cComProd, @nCantRealizata, @nCantLivrata
	while @@fetch_status = 0 and abs(@nCantRealizBK) >= 0.001
	begin
		if @nCantRealizBK > 0 
			set @nCantDescarc = (case when @nCantRealizata - @nCantLivrata < @nCantRealizBK then @nCantRealizata - @nCantLivrata else @nCantRealizBK end)
		else 
			set @nCantDescarc = (case when @nCantLivrata < abs(@nCantRealizBK) then (-1) * @nCantLivrata else @nCantRealizBK end)
		
		set @nCantRealizBK = @nCantRealizBK - @nCantDescarc
		update pozprod set cantitate_livrata = cantitate_livrata + @nCantDescarc
		where comanda=@cComProd and cod=@cCod and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
		fetch next from tmppozprod into @cComProd, @nCantRealizata, @nCantLivrata
	end
	close tmppozprod
	deallocate tmppozprod

	fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
end
close tmpcmdaprov
deallocate tmpcmdaprov
end
'
GO
/****** Object:  Trigger [cantpozaprov]    Script Date: 12/17/2011 15:20:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[cantpozaprov]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[cantpozaprov] on [dbo].[pozcon] for insert, update, delete not for replication as
begin
declare @cComAprov char(20), @dAprov datetime, @cFurn char(13), @cCod char(20), @nCantReceptie float, 
	@cTip char(2), @cComLivr char(20), @dLivr datetime, @cBenef char(13), @nCantComandata float, @nCantReceptionata float, 
	@nCantDescarc float, @nCantRealizBK float, @nCantRealizata float 
-- realizata FC => receptionata pozaprov
declare tmpcmdaprov cursor for
select isnull(i.contract, d.contract) as cntr, isnull(i.data, d.data) as data, isnull(i.tert, d.tert) as tert, 
isnull(i.cod, d.cod) as cod, sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0)) as diferenta 
from inserted i full outer join deleted d on i.subunitate=d.subunitate and i.tip=d.tip and i.contract=d.contract 
	and i.data=d.data and i.tert=d.tert and i.cod=d.cod 
where isnull(i.tip, d.tip)=''FC'' 
group by isnull(i.contract, d.contract), isnull(i.data, d.data), isnull(i.tert, d.tert), isnull(i.cod, d.cod)
having abs(sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0))) >= 0.001
open tmpcmdaprov
fetch next from tmpcmdaprov into @cComAprov, @dAprov, @cFurn, @cCod, @nCantReceptie
while @@fetch_status = 0
begin
	declare tmppozaprov cursor for
	select tip, comanda_livrare, data_comenzii, beneficiar, cant_comandata, cant_receptionata
	from pozaprov where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod
	order by (case tip when ''BK'' then 1 when ''C'' then 2 else 3 end) * sign(@nCantReceptie), 
		datediff(day, getdate(), data_comenzii) * sign(@nCantReceptie) 
	open tmppozaprov
	fetch next from tmppozaprov into @cTip, @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantReceptionata
	while @@fetch_status = 0 and abs(@nCantReceptie) >= 0.001
	begin
		if @nCantReceptie > 0 
			set @nCantDescarc = (case when @nCantComandata - @nCantReceptionata < @nCantReceptie then @nCantComandata - @nCantReceptionata else @nCantReceptie end)
		else 
			set @nCantDescarc = (case when @nCantReceptionata < abs(@nCantReceptie) then (-1) * @nCantReceptionata else @nCantReceptie end)
		
		set @nCantReceptie = @nCantReceptie - @nCantDescarc
		update pozaprov set cant_receptionata = cant_receptionata + @nCantDescarc
		where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod 
			and tip=@cTip and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
		fetch next from tmppozaprov into @cTip, @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantReceptionata
	end
	close tmppozaprov
	deallocate tmppozaprov
	if (@nCantReceptie >= 0.001) begin -- s-a receptionat mai mult decat s-a comandat
		if exists (select 1 from pozaprov where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod and tip='''' and comanda_livrare='''') 
			update pozaprov set cant_receptionata = cant_receptionata + @nCantReceptie 
			where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod and tip='''' and comanda_livrare=''''
		else
			insert into pozaprov
			(Contract, Data, Furnizor, Cod, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata, Tip)
			select @cComAprov, @dAprov, @cFurn, @cCod, '''', @dAprov, '''', 0, @nCantReceptie, 0, '''' 
	end
	fetch next from tmpcmdaprov into @cComAprov, @dAprov, @cFurn, @cCod, @nCantReceptie
end
close tmpcmdaprov
deallocate tmpcmdaprov

--realizat BK=>realizat pozaprov
declare tmpcmdaprov cursor for
select isnull(i.contract, d.contract) as cntr, isnull(i.data, d.data) as data, isnull(i.tert, d.tert) as tert, 
isnull(i.cod, d.cod) as cod, sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0)) as diferenta 
from inserted i full outer join deleted d on i.subunitate=d.subunitate and i.tip=d.tip and i.contract=d.contract 
	and i.data=d.data and i.tert=d.tert and i.cod=d.cod 
where isnull(i.tip, d.tip)=''BK'' 
group by isnull(i.contract, d.contract), isnull(i.data, d.data), isnull(i.tert, d.tert), isnull(i.cod, d.cod)
having abs(sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0))) >= 0.001
open tmpcmdaprov
fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
while @@fetch_status = 0
begin
	declare tmppozaprov cursor for
	select contract, data, furnizor, cant_receptionata, cant_realizata
	from pozaprov where tip=''BK'' and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef and cod=@cCod
	order by datediff(day, getdate(), data) * sign(@nCantRealizBK) 
	open tmppozaprov
	fetch next from tmppozaprov into @cComAprov, @dAprov, @cFurn, @nCantReceptionata, @nCantRealizata
	while @@fetch_status = 0 and abs(@nCantRealizBK) >= 0.001
	begin
		if @nCantRealizBK > 0 
			set @nCantDescarc = (case when @nCantReceptionata - @nCantRealizata < @nCantRealizBK then @nCantReceptionata - @nCantRealizata else @nCantRealizBK end)
		else 
			set @nCantDescarc = (case when @nCantRealizata < abs(@nCantRealizBK) then (-1) * @nCantRealizata else @nCantRealizBK end)
		
		set @nCantRealizBK = @nCantRealizBK - @nCantDescarc
		update pozaprov set cant_realizata = cant_realizata + @nCantDescarc
		where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod 
			and tip=''BK'' and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
		fetch next from tmppozaprov into @cComAprov, @dAprov, @cFurn, @nCantReceptionata, @nCantRealizata
	end
	close tmppozaprov
	deallocate tmppozaprov
	if (@nCantRealizBK >= 0.001 and RTrim(@cComAprov) <> '''') -- s-a realizat mai mult decat s-a receptionat, am pozitie pe BK in pozaprov
		update pozaprov set cant_realizata = cant_realizata + @nCantRealizBK 
		where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod 
			and tip=''BK'' and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 

	fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
end
close tmpcmdaprov
deallocate tmpcmdaprov
end
'
GO
/****** Object:  Trigger [cantcon]    Script Date: 12/17/2011 15:20:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[cantcon]'))
EXEC dbo.sp_executesql @statement = N'--***
create trigger [dbo].[cantcon] on [dbo].[pozcon] for insert, update, delete not for replication as
begin
declare @csub char(9),@ccod char(20),@cmodpl char(8),@ctip char(2),@ccontr char(20),@ctert char(13),@semn int,@cant float, @dtermen datetime, @pozcon int, @contrcor char(20) 

-------------	din tabela par (parametri trimis de Magic):
	declare @rbfbkapr int, @stbktrans char(1), @stbkaprob char(1), @stbkfact char(1), @stbkreal char(1), 
			@defbkpart int,@pozsurse int
	set @rbfbkapr=isnull((select top 1 val_logica from par where tip_parametru=''UC'' and parametru=''RBFBKAPR''),0)
	set @stbktrans=isnull((select top 1 val_alfanumerica from par where tip_parametru=''UC'' and parametru=''STBKTRANS''),''4'')
	set @stbkaprob=isnull((select top 1 val_alfanumerica from par where tip_parametru=''UC'' and parametru=''STBKAPROB''),''4'')
	set @stbkfact=isnull((select top 1 val_alfanumerica from par where tip_parametru=''UC'' and parametru=''STBKFACT''),'''')
		declare @factbks3 int
		if (@stbkfact='''')
		begin
			set @factbks3=isnull((select top 1 val_logica from par where tip_parametru=''UC'' and parametru=''FACTBKS3''),0)
			set @stbkfact=(case when @factbks3=1 then ''3'' else ''1'' end)
		end
	set @stbkreal=isnull((select top 1 val_alfanumerica from par where tip_parametru=''UC'' and parametru=''STBKREAL''),'''')
	set @defbkpart=isnull((select top 1 val_logica from par where tip_parametru=''UC'' and parametru=''DEFBKPART''),0)
	set @pozsurse=isnull((select top 1 val_logica from par where tip_parametru=''UC'' and parametru=''POZSURSE''),0)
-------------

-- daca exista tabela StructCon se va cauta ramura(pozcon.pret_promotional) pe care se face update 
declare @esteStruct int, @ramura float
Set @esteStruct = (Select count(*) from sysobjects where type = ''U'' and name = ''structcon'')

declare tmpCant cursor for
select subunitate, tip,contract, tert, cod, mod_de_plata, (case when tip=''BK'' and @rbfbkapr=1 then cant_aprobata else cantitate end),1 as semn, termen,pret_promotional from inserted where tip in (''BK'',''FC'', ''BP'')
union all
select subunitate, tip,contract, tert, cod, mod_de_plata, (case when tip=''BK'' and @rbfbkapr=1 then cant_aprobata else cantitate end),-1 as semn, termen,pret_promotional from deleted where tip in (''BK'',''FC'', ''BP'')

open tmpCant
fetch next from tmpCant into @csub,@ctip,@ccontr,@ctert,@ccod,@cmodpl,@cant,@semn, @dtermen, @ramura
declare @fetch int
set @fetch=@@fetch_status 
while @fetch=0 
begin

/* pt completarea cant realizate pe BF de pe BK */

if @ctip=''BK''
begin
	set @contrcor = isnull((select max(contract_coresp) from con 
		where subunitate=@csub and tip=''BK'' and contract=@ccontr and tert=@ctert 
			and contract=@ccontr and tert=@ctert),'''')
				
	update pozcon set cant_realizata = cant_realizata + @cant * @semn
	where subunitate=@csub and tip=''BF'' and tert=@ctert and cod=@ccod and (@pozsurse=0 or mod_de_plata=@cmodpl) 
		and contract=@contrcor

	set @pozcon = (select max(numar_pozitie) 
	from pozcon 
	where subunitate=@csub and tip=''BF'' and tert=@ctert and cod=@ccod and (@pozsurse=0 or mod_de_plata=@cmodpl) 
		and contract=@contrcor)

	update termene set cant_realizata = cant_realizata + @cant * @semn
	where subunitate=@csub and tip=''BF'' and tert=@ctert and cod=(case when @pozsurse=0 then @ccod else ltrim(str(@pozcon)) end) 
		and termen=@dtermen	and contract=@contrcor
end

/* pt completarea cant realizate pe FA de pe FC */
if @ctip=''FC''
	update pozcon set cant_realizata=cant_realizata + @cant * @semn
	where subunitate=@csub and tip=''FA'' and tert=@ctert and cod=@ccod
	and contract=isnull((select contract_coresp from con where tip=''FC'' and subunitate=@csub and contract=@ccontr and tert=@ctert),'''')
	and (@esteStruct = 0 or (exists (select * from structcon s where s.subunitate = @csub and s.tip = @ctip and s.contract = @ccontr and s.tert = @ctert ) and pret_promotional = @ramura))

-- starea transferat - doar daca gestiune_primitoare<>''''
if @ctip=''BK''
begin
	if (@defbkpart=1 or not exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (abs(cant_aprobata)-abs(pret_promotional)>=0.001 or abs(cant_aprobata)>=0.001 and sign(cant_aprobata)*sign(pret_promotional)<1) and punct_livrare<>''''))
and exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (punct_livrare<>'''' or abs(pret_promotional)>=0.001) and abs(cant_aprobata)>=0.001)
		update con set stare=@stbktrans where cod_dobanda<>'''' and subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (stare in (''0'', @stbkaprob, @stbkfact) )--or stare>=@stbkreal)

	-- TE pot genera si din stare Aprobat si din Facturabil -> o las in Facturabil...
	if exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata-pret_promotional>=0.001 /*and punct_livrare <> ''''*/)
		update con set stare=@stbkfact/*@stbkaprob*/ where cod_dobanda<>'''' and subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and stare=@stbktrans
end
-- starea facturat (realizat) - doar daca tert<>''''
if @ctip=''BK'' or @ctip=''BP''
begin
	if not exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (abs(cant_aprobata)-abs(cant_realizata)>=0.001 or abs(cant_aprobata)>=0.001 and sign(cant_aprobata)*sign(cant_realizata)<1))
and exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and abs(cant_aprobata)>=0.001)
		update con set stare=@stbkreal where tert<>'''' and subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and stare in (''0'', @stbktrans, @stbkaprob, @stbkfact)

	if exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (abs(cant_aprobata)-abs(cant_realizata)>=0.001 or abs(cant_aprobata)>=0.001 and sign(cant_aprobata)*sign(cant_realizata)<1)
	and (select max(stare) from con where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr)>=@stbkreal)
		update con set stare=@stbkfact where tert<>'''' and subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and stare>=@stbkreal

	--update con set stare=''0'' where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (stare in (@stbkaprob, @stbktrans, @stbkfact, @stbkreal) and not exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata>0)
end
if @ctip=''FC''
begin
	if not exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata>cant_realizata)
		and exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata>0)
		update con set stare=''6'' where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and stare in (''0'', ''1'', ''3'', ''4'')

	if exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata>cant_realizata)
		update con set stare=''1'' where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and stare=''6''

	--update con set stare=''0'' where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (stare = ''1'' or stare = ''3'' or stare=''4'' or stare=''6'') and not exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata>0)
end
fetch next from tmpCant into @csub,@ctip,@ccontr,@ctert,@ccod,@cmodpl,@cant,@semn, @dtermen, @ramura
set @fetch=@@fetch_status 
end
close tmpCant
deallocate tmpCant
end
'
GO
