CREATE TABLE [dbo].[elemtipm] (
    [Tip_masina]  CHAR (20)   NOT NULL,
    [Element]     CHAR (20)   NOT NULL,
    [Mod_calcul]  CHAR (1)    NOT NULL,
    [Formula]     CHAR (2000) NOT NULL,
    [Valoare]     FLOAT (53)  NOT NULL,
    [Ord_macheta] SMALLINT    NOT NULL,
    [Ord_raport]  SMALLINT    NOT NULL,
    [Cu_totaluri] BIT         NOT NULL,
    [Grupa]       CHAR (20)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[elemtipm]([Tip_masina] ASC, [Element] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_si_calcul]
    ON [dbo].[elemtipm]([Tip_masina] ASC, [Mod_calcul] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_si_macheta]
    ON [dbo].[elemtipm]([Tip_masina] ASC, [Ord_macheta] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_si_raport]
    ON [dbo].[elemtipm]([Tip_masina] ASC, [Ord_raport] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_si_grupa]
    ON [dbo].[elemtipm]([Tip_masina] ASC, [Grupa] ASC);


GO
--***
CREATE trigger elemtmsterg on elemtipm for insert,update, delete  NOT FOR REPLICATION as  
begin  

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysselemtm
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'A', Tip_masina, Element, Mod_calcul, Formula, Valoare, Ord_macheta, Ord_raport, Cu_totaluri, Grupa
from inserted   

    insert into sysselemtm  
 select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator,
	'S', Tip_masina, Element, Mod_calcul, Formula, Valoare, Ord_macheta, Ord_raport, Cu_totaluri, Grupa
from deleted  
end
