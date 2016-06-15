CREATE TABLE [dbo].[comenzi] (
    [Subunitate]              CHAR (9)   NOT NULL,
    [Comanda]                 CHAR (20)  NOT NULL,
    [Tip_comanda]             CHAR (1)   NOT NULL,
    [Descriere]               CHAR (150) NOT NULL,
    [Data_lansarii]           DATETIME   NOT NULL,
    [Data_inchiderii]         DATETIME   NOT NULL,
    [Starea_comenzii]         CHAR (1)   NOT NULL,
    [Grup_de_comenzi]         BIT        NOT NULL,
    [Loc_de_munca]            CHAR (9)   NOT NULL,
    [Numar_de_inventar]       CHAR (13)  NOT NULL,
    [Beneficiar]              CHAR (13)  NOT NULL,
    [Loc_de_munca_beneficiar] CHAR (9)   NOT NULL,
    [Comanda_beneficiar]      CHAR (20)  NOT NULL,
    [Art_calc_benef]          CHAR (200) NOT NULL,
    [detalii]                 XML        NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Sub_Comanda]
    ON [dbo].[comenzi]([Subunitate] ASC, [Comanda] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[comenzi]([Descriere] ASC);


GO
--***
create trigger delcompozprod on comenzi for delete not for replication as
begin
	delete pozprod
	from pozprod p, deleted d
	where p.comanda=d.comanda
end

GO
--***
CREATE trigger comenzisterg on comenzi for insert,update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysscomenzi
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'A', Subunitate, Comanda, Tip_comanda, Descriere, Data_lansarii, Data_inchiderii, Starea_comenzii, Grup_de_comenzi, 
		Loc_de_munca, Numar_de_inventar, Beneficiar, Loc_de_munca_beneficiar, Comanda_beneficiar, Art_calc_benef
   from inserted 
   
insert into sysscomenzi
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'S', Subunitate, Comanda, Tip_comanda, Descriere, Data_lansarii, Data_inchiderii, Starea_comenzii, Grup_de_comenzi, 
		Loc_de_munca, Numar_de_inventar, Beneficiar, Loc_de_munca_beneficiar, Comanda_beneficiar, Art_calc_benef
   from deleted
end

GO

create trigger tr_validComenzi on comenzi for update, delete not for replication as
begin try
	/** 
		Cazul stergerilor 
			- nu se permite stergerea unei cocomenzi daca exista documente pe comanda respectiva
	**/
	if exists (select 1 from deleted) and not exists(select 1 from inserted)
	begin
		if exists(select 1 from DELETED d join pozincon p on d.Subunitate=p.subunitate and d.Comanda=p.comanda)
			raiserror ('Nu puteti sterge o comanda pe care exista documente!', 16, 1)
	end

	/** 
		Cazul actualizari
			- daca comanda are documente nu permite actualizarea comenzii
	**/
	if exists(select 1 from DELETED) and exists(select 1 from INSERTED)
	begin
		if not exists (select 1 from DELETED d join INSERTED i on d.Subunitate=i.Subunitate and d.Comanda=i.Comanda) 
			and exists (select 1 from DELETED d join pozincon p on d.Subunitate=p.Subunitate and d.Comanda=p.Comanda)
			raiserror ('Nu puteti actualiza o comanda pe care exista documente!', 16, 1)
	end
end try

begin catch
	declare @mesaj varchar(max)
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror (@mesaj, 16, 1)
end catch
