CREATE TABLE [dbo].[conturi] (
    [Subunitate]                 CHAR (9)     NOT NULL,
    [Cont]                       VARCHAR (20) NULL,
    [Denumire_cont]              CHAR (80)    NOT NULL,
    [Tip_cont]                   CHAR (1)     NOT NULL,
    [Cont_parinte]               VARCHAR (20) NULL,
    [Are_analitice]              BIT          NOT NULL,
    [Apare_in_balanta_sintetica] BIT          NOT NULL,
    [Sold_debit]                 FLOAT (53)   NOT NULL,
    [Sold_credit]                FLOAT (53)   NOT NULL,
    [Nivel]                      SMALLINT     NOT NULL,
    [Articol_de_calculatie]      CHAR (9)     NOT NULL,
    [Logic]                      BIT          NOT NULL,
    [detalii]                    XML          NULL
);




GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[conturi]([Subunitate] ASC, [Cont] ASC);


GO
CREATE NONCLUSTERED INDEX [Sub_ContP]
    ON [dbo].[conturi]([Subunitate] ASC, [Cont_parinte] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[conturi]([Denumire_cont] ASC);


GO



GO

create  trigger tr_validConturi on conturi for insert,update, delete not for replication as

begin try
	if (select max(case when i.cont is null and(p.Cont_creditor is not null or p.Cont_debitor is not null) then '' else 'corect' end)
		from deleted d
		left outer join inserted i on d.Cont=i.Cont and d.Subunitate=i.Subunitate and d.Are_analitice=i.Are_analitice and d.Cont_parinte=i.Cont_parinte
		left outer join pozincon p on d.Cont=p.Cont_creditor or d.Cont=p.Cont_debitor)=''
		raiserror('Eroare operare (pozdoc.tr_validConturi): Acest cont are inregistrari contabile!',16,1)

	-- Daca se incearca stergerea unui cont care are rulaje
	if exists (select 1 from deleted) and not exists(select 1 from inserted)
	begin
		if exists(select 1 from DELETED d join rulaje r on d.Subunitate=r.subunitate and d.cont=r.cont)
			raiserror('Eroare operare (rulaje.tr_validConturi): Exista rulaje pe acest cont!',16,1)
	end
	
	-- Daca se incearca modificare unui cont care are rulaje	
	if exists(select 1 from DELETED) and exists(select 1 from INSERTED)
	begin
		if not exists (select 1 from DELETED d join INSERTED i on d.Subunitate=i.Subunitate and d.cont=i.cont) 
			and exists (select 1 from DELETED d join rulaje r on d.Subunitate=r.Subunitate and d.cont=r.cont)
			raiserror ('Nu puteti actualiza un cont pe care exista rulaje!', 16, 1)
	end

	/* validare indicator bugetar */ 
	if exists (select 1 from sysobjects where [type]='P' and [name]='validIndicatorBugetar') 
		and exists (select 1 from par where tip_parametru='GE' and parametru='BUGETARI' and Val_logica=1)
	Begin
		select DISTINCT detalii.value('(/row/@indicator)[1]','varchar(20)') indbug
		into #indbug 
		from inserted
			where nullif(detalii.value('(/row/@indicator)[1]','varchar(20)'),'') is not null
		exec validIndicatorBugetar
	End
end try

begin catch
	declare @mesaj varchar(max)
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 16, 1)
end catch

GO
--***
CREATE trigger conturisterg on CONTURI for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssc
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Subunitate, Cont, Denumire_cont, Tip_cont, Cont_parinte, Are_analitice, Apare_in_balanta_sintetica, Sold_debit,
	Sold_credit, Nivel, Articol_de_calculatie, Logic
   from deleted
