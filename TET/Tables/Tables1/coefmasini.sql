CREATE TABLE [dbo].[coefmasini] (
    [Masina]     CHAR (20)  NOT NULL,
    [Coeficient] CHAR (20)  NOT NULL,
    [Valoare]    FLOAT (53) NOT NULL,
    [Interval]   FLOAT (53) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[coefmasini]([Masina] ASC, [Coeficient] ASC);


GO
--***
CREATE trigger coefmsterg on coefmasini for insert,update, delete  NOT FOR REPLICATION as  
begin  

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysscoefm
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'A', Masina, Coeficient, Valoare, Interval
from inserted   

insert into sysscoefm  
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
		'S', Masina, Coeficient, Valoare, Interval
from deleted  
end
