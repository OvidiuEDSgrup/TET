CREATE TABLE [dbo].[elemactivitati] (
    [Tip]              CHAR (2)   NOT NULL,
    [Fisa]             CHAR (20)  NOT NULL,
    [Data]             DATETIME   NOT NULL,
    [Numar_pozitie]    INT        NOT NULL,
    [Element]          CHAR (20)  NOT NULL,
    [Valoare]          FLOAT (53) NOT NULL,
    [Tip_document]     CHAR (2)   NOT NULL,
    [Numar_document]   CHAR (8)   NOT NULL,
    [Data_document]    DATETIME   NOT NULL,
    [idElemActivitati] INT        IDENTITY (1, 1) NOT NULL,
    [idPozActivitati]  INT        NULL,
    CONSTRAINT [idElemActivitati] PRIMARY KEY NONCLUSTERED ([idElemActivitati] ASC),
    CONSTRAINT [elemactivitati_idPozActivitati] FOREIGN KEY ([idPozActivitati]) REFERENCES [dbo].[pozactivitati] ([idPozActivitati])
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[elemactivitati]([Tip] ASC, [Fisa] ASC, [Data] ASC, [Numar_pozitie] ASC, [Element] ASC);


GO
--***
create trigger elemactivlunai on elemactivitati for update, insert, delete as
declare @nlunainc int, @nanulinc int, @ddatainc datetime
set @nlunainc= (select val_numerica from par where tip_parametru='MM' and parametru='LUNAINC')
set @nanulinc= (select val_numerica from par where tip_parametru='MM' and parametru='ANULINC')
set @dDataInc=dateadd(month,1,convert(datetime,str(@nLunaInc,2)+'/01/'+str(@nAnulInc,4)))
if (select count(*) from inserted where data<@dDataInc)>0 or (select count(*) from deleted where data<@dDataInc)>0
begin
 RAISERROR ('Violare integritate date. Incercare de modificare luna inchisa(elemactivitati)', 16, 1)
 rollback transaction
end

GO
--***
CREATE trigger elemactivsterg on elemactivitati for insert,update, delete  NOT FOR REPLICATION as  
begin  

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysselemactiv
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator, 'A',   
Tip, Fisa, Data, Numar_pozitie, Element, Valoare, Tip_document, Numar_document, Data_document
from inserted   

insert into sysselemactiv  
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator, 'S',   
Tip, Fisa, Data, Numar_pozitie, Element, Valoare, Tip_document, Numar_document, Data_document
from deleted  
end
