CREATE TABLE [dbo].[terti] (
    [Subunitate]               VARCHAR(9)     NOT NULL,
    [Tert]                     VARCHAR(13)    NOT NULL,
    [Denumire]                 VARCHAR(80)    NOT NULL,
    [Cod_fiscal]               CHAR (16)    NOT NULL,
    [Localitate]               CHAR (35)    NOT NULL,
    [Judet]                    CHAR (20)    NOT NULL,
    [Adresa]                   CHAR (60)    NOT NULL,
    [Telefon_fax]              CHAR (20)    NOT NULL,
    [Banca]                    CHAR (20)    NOT NULL,
    [Cont_in_banca]            CHAR (35)    NOT NULL,
    [Tert_extern]              BIT          NOT NULL,
    [Grupa]                    CHAR (3)     NOT NULL,
    [Cont_ca_furnizor]         VARCHAR (20) NULL,
    [Cont_ca_beneficiar]       VARCHAR (20) NULL,
    [Sold_ca_furnizor]         FLOAT (53)   NOT NULL,
    [Sold_ca_beneficiar]       FLOAT (53)   NOT NULL,
    [Sold_maxim_ca_beneficiar] FLOAT (53)   NOT NULL,
    [Disccount_acordat]        REAL         NOT NULL,
    [detalii]                  XML          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[terti]([Subunitate] ASC, [Tert] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[terti]([Denumire] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod_fiscal]
    ON [dbo].[terti]([Cod_fiscal] ASC);


GO
CREATE NONCLUSTERED INDEX [yso_tert]
    ON [dbo].[terti]([Tert] ASC);


GO
CREATE NONCLUSTERED INDEX [yso_grupa_tert]
    ON [dbo].[terti]([Subunitate] ASC, [Grupa] ASC)
    INCLUDE([Tert]);


GO

create trigger tr_validTert on terti for update, delete not for replication as
begin try
	/** 
		Cazul stergerilor 
			- nu se permite stergerea unei cocomenzi daca exista documente pe comanda respectiva
	**/
	if exists (select 1 from deleted) and not exists(select 1 from inserted)
	begin
		if exists(select 1 from DELETED d join pozdoc p on d.Subunitate=p.subunitate and d.tert=p.Tert)
			raiserror ('Nu puteti sterge un tert pe care exista documente!', 16, 1)
	end

	/** 
		Cazul actualizari
			- daca comanda are documente nu permite actualizarea comenzii
	**/
	if exists(select 1 from DELETED) and exists(select 1 from INSERTED)
	begin
		if not exists (select 1 from DELETED d join INSERTED i on d.Subunitate=i.Subunitate and d.tert=i.tert) 
			and exists (select 1 from DELETED d join pozdoc p on d.Subunitate=p.Subunitate and d.tert=p.tert)
			raiserror ('Nu puteti actualiza un tert pe care exista documente!', 16, 1)
	end
end try

begin catch
	rollback transaction
	declare @mesaj varchar(max)
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror(@mesaj, 16, 1)
end catch

GO
--***
CREATE trigger tertisterg on terti for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysst
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Subunitate, Tert, Denumire, Cod_fiscal, Localitate, Judet, Adresa, Telefon_fax, Banca, Cont_in_banca, 
	Tert_extern, Grupa, Cont_ca_furnizor, Cont_ca_beneficiar, Sold_ca_furnizor, Sold_ca_beneficiar, 
	Sold_maxim_ca_beneficiar, Disccount_acordat
   from deleted

GO
CREATE TRIGGER yso_tr_completezLimitaCredit ON Terti 
AFTER INSERT
AS
UPDATE Terti SET Sold_maxim_ca_beneficiar=9999
WHERE Terti.Sold_maxim_ca_beneficiar=0 
	AND EXISTS (SELECT TOP (1) 1 FROM inserted I WHERE I.Subunitate=Terti.Subunitate and I.Tert=Terti.Tert)
	