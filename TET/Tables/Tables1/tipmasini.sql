CREATE TABLE [dbo].[tipmasini] (
    [Cod]            CHAR (20) NOT NULL,
    [Denumire]       CHAR (60) NOT NULL,
    [Tip_activitate] CHAR (1)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[tipmasini]([Cod] ASC);


GO
--***
CREATE trigger tipmassterg on tipmasini for insert,update, delete  NOT FOR REPLICATION as  
begin  

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysstipmas 
 select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'A', Cod, Denumire, tip_activitate
from inserted   

    insert into sysstipmas  
 select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'S', Cod, Denumire, tip_activitate  
from deleted  
end
