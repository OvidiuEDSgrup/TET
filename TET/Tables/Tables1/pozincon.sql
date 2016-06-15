CREATE TABLE [dbo].[pozincon] (
    [Subunitate]     CHAR (9)     NOT NULL,
    [Tip_document]   CHAR (2)     NOT NULL,
    [Numar_document] VARCHAR (20) NULL,
    [Data]           DATETIME     NOT NULL,
    [Cont_debitor]   VARCHAR (20) NULL,
    [Cont_creditor]  VARCHAR (20) NULL,
    [Suma]           FLOAT (53)   NOT NULL,
    [Valuta]         CHAR (3)     NOT NULL,
    [Curs]           FLOAT (53)   NOT NULL,
    [Suma_valuta]    FLOAT (53)   NOT NULL,
    [Explicatii]     CHAR (50)    NOT NULL,
    [Utilizator]     CHAR (10)    NOT NULL,
    [Data_operarii]  DATETIME     NOT NULL,
    [Ora_operarii]   CHAR (6)     NOT NULL,
    [Numar_pozitie]  INT          NOT NULL,
    [Loc_de_munca]   CHAR (9)     NOT NULL,
    [Comanda]        CHAR (40)    NOT NULL,
    [Jurnal]         VARCHAR (20) NULL,
    [Indbug]         VARCHAR (20) DEFAULT ('') NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Pozincon]
    ON [dbo].[pozincon]([Subunitate] ASC, [Tip_document] ASC, [Numar_document] ASC, [Data] ASC, [Cont_debitor] ASC, [Cont_creditor] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Valuta] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [actualizare]
    ON [dbo].[pozincon]([Subunitate] ASC, [Tip_document] ASC, [Numar_document] ASC, [Data] ASC, [Jurnal] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Data]
    ON [dbo].[pozincon]([Subunitate] ASC, [Data] ASC);


GO
CREATE NONCLUSTERED INDEX [Costuri]
    ON [dbo].[pozincon]([Subunitate] ASC, [Data] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Cont_debitor] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Data_Contd]
    ON [dbo].[pozincon]([Subunitate] ASC, [Data] ASC, [Cont_debitor] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_Data_Contc]
    ON [dbo].[pozincon]([Subunitate] ASC, [Data] ASC, [Cont_creditor] ASC);


GO

create trigger IncRul on pozincon for insert, update, delete 
as begin
-------------	din tabela par (parametri trimis de Magic):
	declare @rulajelm int
	set @rulajelm=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='RULAJELM'),0)
-------------
declare @cSub char(9), @cCont varchar(40), @cLm char(9), @cIndbug varchar(20), @cValuta char(3), @dData datetime, @RulDeb float, @RulCred float

declare tmpincrul cursor for
select subunitate, cont, lm, indbug, valuta, data, sum(SumaDeb), sum(SumaCred)
from
(
	--debit LEI
	select subunitate, cont_debitor as cont, (case when @rulajelm=1 then loc_de_munca else space(9) end) as lm, indbug, space(3) as valuta, 
	dbo.eom(data) as data, sum(round(convert(decimal(15, 3), suma), 2)) as SumaDeb, 0 as SumaCred
	from inserted where cont_debitor<>'' and abs(round(suma,2))>=0.01
	group by subunitate, cont_debitor, (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug, dbo.eom(data)
	union all
	select subunitate, cont_debitor as cont, (case when @rulajelm=1 then loc_de_munca else space(9) end) as lm, indbug, space(3) as valuta, 
	dbo.eom(data) as data, -sum(round(convert(decimal(15, 3), suma), 2)) as SumaDeb, 0 as SumaCred
	from deleted where cont_debitor<>'' and abs(round(suma,2))>=0.01
	group by subunitate, cont_debitor, (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug, dbo.eom(data)
	union all
	--credit LEI
	select subunitate, cont_creditor as cont, (case when @rulajelm=1 then loc_de_munca else space(9) end) as lm, indbug, space(3) as valuta, 
	dbo.eom(data) as data, 0 as SumaDeb, sum(round(convert(decimal(15, 3), suma), 2)) as SumaCred
	from inserted where cont_creditor<>'' and abs(round(suma,2))>=0.01
	group by subunitate, cont_creditor, (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug, dbo.eom(data)
	union all
	select subunitate, cont_creditor as cont, (case when @rulajelm=1 then loc_de_munca else space(9) end) as lm, indbug, space(3) as valuta, 
	dbo.eom(data) as data, 0 as SumaDeb, -sum(round(convert(decimal(15, 3), suma), 2)) as SumaCred
	from deleted where cont_creditor<>'' and abs(round(suma,2))>=0.01
	group by subunitate, cont_creditor, (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug, dbo.eom(data)
	union all
	--debit VALUTA
	select subunitate, cont_debitor as cont, (case when @rulajelm=1 then loc_de_munca else space(9) end) as lm, indbug, valuta, 
	dbo.eom(data) as data, sum(round(convert(decimal(15, 3), suma_valuta), 2)) as SumaDeb, 0 as SumaCred
	from inserted where cont_debitor<>'' and valuta<>'' and abs(round(suma_valuta,2))>=0.01
	group by subunitate, cont_debitor, (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug, valuta, dbo.eom(data)
	union all
	select subunitate, cont_debitor as cont, (case when @rulajelm=1 then loc_de_munca else space(9) end) as lm, indbug, valuta, 
	dbo.eom(data) as data, -sum(round(convert(decimal(15, 3), suma_valuta), 2)) as SumaDeb, 0 as SumaCred
	from deleted where cont_debitor<>'' and valuta<>'' and abs(round(suma_valuta,2))>=0.01
	group by subunitate, cont_debitor, (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug, valuta, dbo.eom(data)
	union all
	--credit VALUTA
	select subunitate, cont_creditor as cont, (case when @rulajelm=1 then loc_de_munca else space(9) end) as lm, indbug, valuta, 
	dbo.eom(data) as data, 0 as SumaDeb, sum(round(convert(decimal(15, 3), suma_valuta), 2)) as SumaCred
	from inserted where cont_creditor<>'' and valuta<>'' and abs(round(suma_valuta,2))>=0.01
	group by subunitate, cont_creditor, (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug, valuta, dbo.eom(data)
	union all
	select subunitate, cont_creditor as cont, (case when @rulajelm=1 then loc_de_munca else space(9) end) as lm, indbug, valuta, 
	dbo.eom(data) as data, 0 as SumaDeb, -sum(round(convert(decimal(15, 3), suma_valuta), 2)) as SumaCred
	from deleted where cont_creditor<>'' and valuta<>'' and abs(round(suma_valuta,2))>=0.01
	group by subunitate, cont_creditor, (case when @rulajelm=1 then loc_de_munca else space(9) end), indbug, valuta, dbo.eom(data)
) a
group by subunitate, cont, lm, indbug, valuta, data

open tmpincrul
fetch next from tmpincrul into @cSub, @cCont, @cLm, @cIndbug, @cValuta, @dData, @RulDeb, @RulCred
while @@fetch_status=0
begin
	exec AdaugInRulaje @cSub, @cCont, @cValuta, @dData, @RulDeb, @RulCred, @cLm, @cIndbug
	
	fetch next from tmpincrul into @cSub, @cCont, @cLm, @cIndbug, @cValuta, @dData, @RulDeb, @RulCred
end
close tmpincrul
deallocate tmpincrul

end

GO
--***
/*Pentru creat antet inregistrari contabile*/
create trigger inconant on pozincon for update,insert,delete as
begin
insert into incon (subunitate,tip_document,numar_document,data,jurnal,Numar_pozitie)
	select subunitate, tip_document, numar_document, data, jurnal, 0 from inserted where numar_document not in 
	(select numar_document from incon where subunitate=inserted.subunitate and data=inserted.data and
	tip_document=inserted.tip_document and jurnal=inserted.jurnal) group by subunitate, tip_document,
	numar_document,data, jurnal

/*Pentru calculul valorilor*/
declare @numar_poz int
declare @csub char(9), @ctip char(2), @cnr char(20), @cdata datetime, @cjurnal char(3), @semn int
declare @gsub char(9), @gtip char(2), @gnr char(20), @gdata datetime, @gjurnal char(3), @gfetch int

declare tmp2 cursor for
select subunitate, tip_document, numar_document, data, jurnal, 1 
	from inserted union all
select subunitate, tip_document, numar_document, data, jurnal, -1
	from deleted 
order by subunitate, tip_document, numar_document, data, jurnal

open tmp2
fetch next from tmp2 into @csub, @ctip, @cnr,@cdata, @cjurnal, @semn
set @gsub=@csub
set @gtip=@ctip
set @gnr=@cnr
set @gdata=@cdata
set @gjurnal=@cjurnal
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @numar_poz=0
	while @gsub=@csub and @gtip=@ctip and @gdata=@cdata and @gnr=@cnr and @gjurnal=@cjurnal and @gfetch=0
	begin
		set @numar_poz=@numar_poz+@semn
		fetch next from tmp2 into @csub, @ctip, @cnr, @cdata, @cjurnal, @semn
		set @gfetch=@@fetch_status
	end
	update incon set numar_pozitie=numar_pozitie+@numar_poz 
		where incon.subunitate=@gsub and incon.tip_document=@gtip and incon.numar_document=@gnr 
		and incon.data=@gdata
	delete from incon
		where incon.subunitate=@gsub and incon.tip_document=@gtip and incon.numar_document=@gnr 
		and incon.data=@gdata and incon.numar_pozitie=0
	set @gsub=@csub
	set @gtip=@ctip
	set @gnr=@cnr
	set @gdata=@cdata
	set @gjurnal=@cjurnal
end

close tmp2
deallocate tmp2
end

GO

create  trigger tr_ValidPozincon on pozincon for insert,update,delete NOT FOR REPLICATION as
begin try
	declare 
		@userASiS varchar(50),@mesaj varchar(255) 
	select @userASiS=dbo.fIaUtilizator(null)

	/* Validare comanda */
	IF UPDATE(COMANDA)
	begin	
		select DISTINCT LEFT(comanda,20) comanda 
		into #comenzi from inserted
			where left(cont_debitor,1) not in ('8','9') and left(cont_creditor,1) not in ('8','9')
		exec validComanda
	end

	/**Validare formule contabile + conturile in sine**/
	create table #formulecontabile (cont_debit varchar(40), cont_credit varchar(40), tip varchar(2), numar varchar(20), data datetime)
	insert into #formulecontabile(cont_debit, cont_credit, tip, numar, data)
	select cont_debitor, cont_creditor, tip_document, numar_document, Data from inserted where suma<>0
	exec validFormuleContabile 

	/** Validare luna inchisa Contabilitate */
	create table #lunaconta (data datetime)
	insert into #lunaconta (data)
	select DISTINCT data from inserted
		where left(cont_debitor,1) not in ('8','9') and left(cont_creditor,1) not in ('8','9')
	union all
	select DISTINCT data from deleted
		where left(cont_debitor,1) not in ('8','9') and left(cont_creditor,1) not in ('8','9')
	exec validLunaInchisaConta	
	
	/* validare indicator bugetar - specific */ 
	if exists (select 1 from sysobjects where [type]='P' and [name]='validIndicatorBugetarPozincon')
	Begin
		select DISTINCT substring(inserted.comanda,21,20) indicator
		into #indicatori from inserted
			where substring(inserted.comanda,21,20)<>''
		exec validIndicatorBugetarPozincon
	End
end try
begin catch
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()+ ' (tr_ValidPozincon)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch

GO
EXECUTE sp_settriggerorder @triggername = N'[dbo].[tr_ValidPozincon]', @order = N'last', @stmttype = N'insert';

