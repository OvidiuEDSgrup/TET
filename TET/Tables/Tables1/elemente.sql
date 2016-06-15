CREATE TABLE [dbo].[elemente] (
    [Cod]      CHAR (20)  NOT NULL,
    [Denumire] CHAR (60)  NOT NULL,
    [Tip]      CHAR (1)   NOT NULL,
    [UM]       CHAR (3)   NOT NULL,
    [UM2]      CHAR (3)   NOT NULL,
    [Interval] FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[elemente]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip]
    ON [dbo].[elemente]([Tip] ASC);


GO
--***
CREATE trigger elemsterg on elemente for insert,update, delete  NOT FOR REPLICATION as  
begin  

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

    insert into sysselem 
 select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator, 
	'A', Cod, Denumire, Tip, UM, UM2, Interval 
from inserted   

    insert into sysselem  
 select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'S', Cod, Denumire, Tip, UM, UM2, Interval  
from deleted  
end
