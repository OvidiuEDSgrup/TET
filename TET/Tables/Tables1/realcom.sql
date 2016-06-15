CREATE TABLE [dbo].[realcom] (
    [Marca]                CHAR (6)   NOT NULL,
    [Loc_de_munca]         CHAR (9)   NOT NULL,
    [Numar_document]       CHAR (20)  NOT NULL,
    [Data]                 DATETIME   NOT NULL,
    [Comanda]              CHAR (13)  NOT NULL,
    [Cod_reper]            CHAR (20)  NOT NULL,
    [Cod]                  CHAR (20)  NOT NULL,
    [Cantitate]            FLOAT (53) NOT NULL,
    [Categoria_salarizare] CHAR (4)   NOT NULL,
    [Norma_de_timp]        FLOAT (53) NOT NULL,
    [Tarif_unitar]         FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[realcom]([Data] ASC, [Marca] ASC, [Loc_de_munca] ASC, [Comanda] ASC, [Numar_document] ASC);


GO
CREATE NONCLUSTERED INDEX [Numar_fisa]
    ON [dbo].[realcom]([Numar_document] ASC, [Data] ASC, [Loc_de_munca] ASC);


GO
--***
CREATE trigger realcomsterg on realcom for insert,update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into syssrealcom
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'A', Marca, Loc_de_munca, Numar_document, Data, Comanda, Cod_reper, Cod, Cantitate , Categoria_salarizare, Norma_de_timp, Tarif_unitar
	from inserted 

insert into syssrealcom
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'S', Marca, Loc_de_munca, Numar_document, Data, Comanda, Cod_reper, Cod, Cantitate , Categoria_salarizare, Norma_de_timp, Tarif_unitar 
	from deleted
end

GO

create  trigger tr_validRealcom on realcom for insert,update NOT FOR REPLICATION as
	DECLARE 
		@mesaj varchar(255),@validcomstrictGE int,@salariatiPecomenzi int

begin try
	
	if UPDATE(Comanda) 
	begin
		exec luare_date_par 'GE', 'COMANDA', 0, @validcomstrictGE output, ''
		exec luare_date_par 'PS', 'SALCOM', @salariatiPecomenzi output, 0, ''	
		
		if @validcomstrictGE=1 and @salariatiPecomenzi=1 and exists(select 1 from inserted where isnull(inserted.Comanda,'')='')
			raiserror('Eroare operare (realcom.tr_validRealcom): Comanda necompletata!',16,1)
		
		if exists(select 1 from inserted where isnull(inserted.Comanda,'')<>'') 
			and not exists(select 1 from inserted inner join comenzi on comenzi.Comanda=inserted.Comanda) 
			raiserror('Eroare operare (realcom.tr_validRealcom): Comanda inexistenta in tabela de comenzi!',16,1)

		if ((select count(*) from inserted i  
		inner join comenzi c on i.comanda = c.comanda  
		where c.starea_comenzii = 'I' and i.data>c.data_inchiderii)>0  )
			RAISERROR ('Violare integritate date. Incercare de operare realizari (realcom) pe comanda inchisa.', 16, 1)  	
	end 
	
end try
begin catch
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE() +' (tr_validRealcom)'
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
