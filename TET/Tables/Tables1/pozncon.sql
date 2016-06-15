CREATE TABLE [dbo].[pozncon] (
    [Subunitate]    CHAR (9)     NOT NULL,
    [Tip]           CHAR (2)     NOT NULL,
    [Numar]         CHAR (13)    NOT NULL,
    [Data]          DATETIME     NOT NULL,
    [Cont_debitor]  VARCHAR (20) NULL,
    [Cont_creditor] VARCHAR (20) NULL,
    [Suma]          FLOAT (53)   NOT NULL,
    [Valuta]        CHAR (3)     NOT NULL,
    [Curs]          FLOAT (53)   NOT NULL,
    [Suma_valuta]   FLOAT (53)   NOT NULL,
    [Explicatii]    CHAR (50)    NOT NULL,
    [Utilizator]    CHAR (10)    NOT NULL,
    [Data_operarii] DATETIME     NOT NULL,
    [Ora_operarii]  CHAR (6)     NOT NULL,
    [Nr_pozitie]    INT          NOT NULL,
    [Loc_munca]     CHAR (9)     NOT NULL,
    [Comanda]       CHAR (40)    NOT NULL,
    [Tert]          CHAR (13)    NOT NULL,
    [Jurnal]        CHAR (3)     NOT NULL,
    [detalii]       XML          NULL,
    [idPozncon]     INT          IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_idPozncon] PRIMARY KEY NONCLUSTERED ([idPozncon] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [Poznc]
    ON [dbo].[pozncon]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Nr_pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Poznc1]
    ON [dbo].[pozncon]([Subunitate] ASC, [Tip] ASC, [Numar] ASC, [Data] ASC, [Jurnal] ASC, [Nr_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Poznc2]
    ON [dbo].[pozncon]([Subunitate] ASC, [Data] ASC, [Cont_debitor] ASC, [Cont_creditor] ASC);


GO
create trigger ScriuPozNconDocDeContat on pozncon for insert,update,delete
as
	insert into DocDeContat(subunitate,tip,numar,data)
		select iu.subunitate,iu.tip,iu.numar,iu.data
		from
			(select i.subunitate,i.tip,i.numar,i.data from inserted i
			union
			select u.subunitate,u.tip,u.numar,u.data from deleted u) iu
		left outer join DocDeContat dc on iu.subunitate=dc.subunitate and dc.tip=iu.tip and iu.numar=dc.numar and iu.data=dc.data
		where dc.subunitate is null --doar daca nu exista
		group by iu.subunitate,iu.tip,iu.numar,iu.data		

GO
--***
/*Pentru creat antet note contabile*/
create trigger nconant on pozncon for update,insert,delete as
begin
-------------	din tabela par (parametri trimis de Magic):
	declare @docdef int
	set @docdef=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='DOCDEF'),0)
-------------
insert into ncon (Subunitate,Tip,Numar,Data,Jurnal,Nr_pozitii,Valuta,Curs,Valoare,Valoare_valuta,Stare)
	select subunitate, tip, numar, data, max(jurnal), 0, max(valuta), max(curs), 0, 0, (case when @docdef=1 and
	right(max(utilizator),1)='2' then 2 else 0 end)
	from inserted where numar not in 
	(select numar from ncon where subunitate=inserted.subunitate and 
	data=inserted.data and tip=inserted.tip) group by subunitate, tip, numar, data

/*Pentru calculul valorilor*/
declare @valoare float, @valoarev float, @numar_poz int
declare @csub char(9), @ctip char(2), @cnr char(13), @cdata datetime, @semn int, @suma float, @sumav float
declare @gsub char(9), @gtip char(2), @gnr char(13), @gdata datetime, @gfetch int

declare tmp cursor for
select subunitate, tip, numar,data,1,suma, suma_valuta 
	from inserted union all
select subunitate, tip, numar,data,-1,suma, suma_valuta
	from deleted 
order by subunitate, tip, numar, data

open tmp
fetch next from tmp into @csub, @ctip, @cnr,@cdata,@semn,@suma, @sumav
set @gsub=@csub
set @gtip=@ctip
set @gnr=@cnr
set @gdata=@cdata
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @valoare=0
	set @valoarev=0
	set @numar_poz=0
	while @gsub=@csub and @gtip=@ctip and @gdata=@cdata and @gnr=@cnr and @gfetch=0
	begin
		set @numar_poz=@numar_poz+@semn
		set @valoare=@valoare+@semn*@suma
		set @valoarev=@valoarev+@semn*@sumav
		fetch next from tmp into @csub, @ctip, @cnr, @cdata, @semn,@suma, @sumav
		set @gfetch=@@fetch_status
	end
	update ncon set valoare=valoare+@valoare, valoare_valuta=valoare_valuta+@valoarev, 
		nr_pozitii=nr_pozitii+@numar_poz 
		where ncon.subunitate=@gsub and ncon.tip=@gtip and ncon.numar=@gnr and ncon.data=@gdata
	delete from ncon
		where ncon.subunitate=@gsub and ncon.tip=@gtip and @gtip in ('IC','MA','ME','MI','MM','PS') and 
		ncon.numar=@gnr and ncon.data=@gdata and ncon.nr_pozitii=0
	set @gsub=@csub
	set @gtip=@ctip
	set @gnr=@cnr
	set @gdata=@cdata
end

close tmp
deallocate tmp
end

GO

create trigger tr_ValidPozNCon on pozncon for insert, update, delete NOT FOR REPLICATION as
declare 
	@errCt varchar(50), @msgErrCt varchar(500), @utilizator varchar(100)

begin try
	set @utilizator=dbo.fIaUtilizator(null)

	/** Validare formule contabile + conturi in sine */
	IF UPDATE(cont_debitor) OR UPDATE(cont_creditor)
		BEGIN
		create table #formulecontabile (cont_credit varchar(40), cont_debit varchar(40), tip varchar(2), numar varchar(20), data datetime)
		insert into #formulecontabile(cont_credit, cont_debit, tip, numar, data)
		select cont_debitor, cont_creditor, tip, numar, Data from INSERTED
		exec validFormuleContabile
	END
	
	/* Validare loc de munca */
	if UPDATE(loc_munca) 
	begin
		create table #lm(utilizator varchar(50),cod varchar(20),data datetime)
		insert into #lm(utilizator,cod,data)
		select distinct @utilizator,loc_munca,data from inserted	
			where left(cont_debitor,1) not in ('8','9') and left(cont_creditor,1) not in ('8','9')
		exec validLM
	end

	/** Validare comanda */
	IF UPDATE(comanda)
	BEGIN
		select DISTINCT LEFT(comanda,20) comanda into #comenzi from INSERTED 
			where left(cont_debitor,1) not in ('8','9') and left(cont_creditor,1) not in ('8','9')
		exec validComanda		
	END

	/** Validare valuta si curs */
	IF UPDATE(valuta) or UPDATE(curs)
	BEGIN
		select DISTINCT tip, numar, data, valuta, curs into #valute
			from INSERTED where valuta<>'' or curs<>0
		exec validValuta
	END

	/** Validare luna inchisa Contabilitate */
	create table #lunaconta (data datetime)
	insert into #lunaconta (data)
	select DISTINCT data from inserted
			where left(cont_debitor,1) not in ('9') and left(cont_creditor,1) not in ('9')
	union all
	select DISTINCT data from deleted
			where left(cont_debitor,1) not in ('9') and left(cont_creditor,1) not in ('9')
	exec validLunaInchisaConta

	/* validare indicator bugetar */ 
	if exists (select 1 from sysobjects where [type]='P' and [name]='validIndicatorBugetar')
		and exists (select 1 from par where tip_parametru='GE' and parametru='BUGETARI' and Val_logica=1)
	Begin
		select DISTINCT detalii.value('(/row/@indicator)[1]','varchar(20)') indbug
		into #indbug 
		from inserted
			where isnull(detalii.value('(/row/@indicator)[1]','varchar(20)'),'')<>''
		exec validIndicatorBugetar
	End

end try 
begin catch
	ROLLBACK TRANSACTION
	declare 
		@mesaj varchar(max)
	set @mesaj = ERROR_MESSAGE() + ' (tr_ValidPozNCon)'
	raiserror ( @mesaj,16,1 )
end catch

GO
--***
create trigger poznconsterg on pozncon for update, delete /*with append*/ NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspn
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Data_operarii, Ora_operarii,
	Subunitate, Tip, Numar, Data, Cont_debitor, Cont_creditor, Suma, Valuta, Curs, Suma_valuta, Explicatii, 
	Utilizator, Nr_pozitie, Loc_munca, Comanda, Tert, Jurnal
   from deleted
