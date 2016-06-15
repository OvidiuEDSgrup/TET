CREATE TABLE [dbo].[catop] (
    [Cod]            CHAR (20)  NOT NULL,
    [Denumire]       CHAR (350) NOT NULL,
    [UM]             CHAR (3)   NOT NULL,
    [Tip_operatie]   CHAR (13)  NOT NULL,
    [Numar_pozitii]  FLOAT (53) NOT NULL,
    [Numar_persoane] FLOAT (53) NOT NULL,
    [Tarif]          FLOAT (53) NOT NULL,
    [Categorie]      CHAR (4)   NOT NULL,
    [Norma_timp]     FLOAT (53) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Cod]
    ON [dbo].[catop]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[catop]([Denumire] ASC);


GO
--***
CREATE trigger catopsterg on catop for insert,update, delete  NOT FOR REPLICATION as
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysscatop
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'A', Cod, Denumire, UM, Tip_operatie, Numar_pozitii, Numar_persoane, Tarif, Categorie
from inserted 

insert into sysscatop
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'S', Cod, Denumire, UM, Tip_operatie, Numar_pozitii, Numar_persoane, Tarif, Categorie
   from deleted
end
