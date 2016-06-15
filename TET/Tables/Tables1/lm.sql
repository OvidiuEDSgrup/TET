CREATE TABLE [dbo].[lm] (
    [Nivel]       SMALLINT  NOT NULL,
    [Cod]         CHAR (9)  NOT NULL,
    [Cod_parinte] CHAR (9)  NOT NULL,
    [Denumire]    CHAR (30) NOT NULL,
    [detalii]     XML       NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[lm]([Cod] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[lm]([Nivel] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[lm]([Denumire] ASC);


GO

create  trigger tr_ValidLM on lm for update, delete NOT FOR REPLICATION as
begin try
	/** 
		Cazul stergerilor 
			- nu se permite stergerea unui loc de munca parinte sau a unui loc de munca cu documente 	
	**/
	IF EXISTS (SELECT 1 from DELETED) and NOT EXISTS( select 1 from inserted)
	begin
		IF EXISTS (select 1 from DELETED d join lm l on d.Cod=l.Cod_parinte)
			RAISERROR ('Nu puteti sterge un loc de munca parinte!', 16, 1)
		IF EXISTS (select 1 from DELETED d join pozincon p on d.Cod=p.Loc_de_munca)
			RAISERROR ('Nu puteti sterge un loc de munca pe care exista documente!', 16, 1)
	end

	/** 
		Actualizari
			- daca locul de munca este parinte pt altele nu se pot actualiza codul si nivelul
			- daca locul de munca are documente nu permite actualizare codului	
	**/
	IF EXISTS (select 1 from DELETED) and EXISTS (select 1 from INSERTED)
	BEGIN
		IF (NOT EXISTS (select 1 from DELETED d join INSERTED i on d.cod=i.cod) OR NOT EXISTS (select 1 from DELETED d join INSERTED i on d.cod=i.cod and i.nivel=d.nivel) )
			and exists (select 1 from DELETED d join lm l on d.Cod=l.Cod_parinte)
			RAISERROR ('Nu puteti actualiza codul si nivelul unui loc de munca parinte!', 16, 1)
		
		IF NOT EXISTS (select 1 from DELETED d join INSERTED i on d.cod=i.cod) 
			and exists (select 1 from DELETED d join pozincon p on d.Cod=p.Loc_de_munca)
			RAISERROR ('Nu puteti actualiza codul unui loc de munca pe care exista documente!', 16, 1)
	end
end try

begin catch
	declare @mesaj varchar(max)
	set @mesaj=error_message() + ' ('+object_name(@@procid)+')'
	raiserror(@mesaj, 16, 1)
end catch

GO
--***
CREATE trigger lmsterg on lm for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssl
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Nivel, Cod, Cod_parinte, Denumire
   from deleted
