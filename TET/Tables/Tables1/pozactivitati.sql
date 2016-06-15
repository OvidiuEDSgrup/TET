CREATE TABLE [dbo].[pozactivitati] (
    [Tip]             CHAR (2)   NOT NULL,
    [Fisa]            CHAR (20)  NOT NULL,
    [Data]            DATETIME   NOT NULL,
    [Numar_pozitie]   INT        NOT NULL,
    [Traseu]          CHAR (20)  NOT NULL,
    [Plecare]         CHAR (30)  NOT NULL,
    [Data_plecarii]   DATETIME   NOT NULL,
    [Ora_plecarii]    CHAR (6)   NOT NULL,
    [Sosire]          CHAR (30)  NOT NULL,
    [Data_sosirii]    DATETIME   NOT NULL,
    [Ora_sosirii]     CHAR (6)   NOT NULL,
    [Explicatii]      CHAR (50)  NOT NULL,
    [Comanda_benef]   CHAR (13)  NOT NULL,
    [Lm_beneficiar]   CHAR (9)   NOT NULL,
    [Tert]            CHAR (13)  NOT NULL,
    [Marca]           CHAR (6)   NOT NULL,
    [Utilizator]      CHAR (10)  NOT NULL,
    [Data_operarii]   DATETIME   NOT NULL,
    [Ora_operarii]    CHAR (6)   NOT NULL,
    [Alfa1]           CHAR (50)  NOT NULL,
    [Alfa2]           CHAR (50)  NOT NULL,
    [Val1]            FLOAT (53) NOT NULL,
    [Val2]            FLOAT (53) NOT NULL,
    [Data1]           DATETIME   NOT NULL,
    [idPozActivitati] INT        IDENTITY (1, 1) NOT NULL,
    [idActivitati]    INT        NULL,
    CONSTRAINT [idPozActivitati] PRIMARY KEY NONCLUSTERED ([idPozActivitati] ASC),
    CONSTRAINT [pozactivitati_idActivitati] FOREIGN KEY ([idActivitati]) REFERENCES [dbo].[activitati] ([idActivitati])
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[pozactivitati]([Tip] ASC, [Fisa] ASC, [Data] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Traseu]
    ON [dbo].[pozactivitati]([Traseu] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Comanda_beneficiar]
    ON [dbo].[pozactivitati]([Tip] ASC, [Fisa] ASC, [Data] ASC, [Numar_pozitie] ASC, [Comanda_benef] ASC);


GO
--***
create trigger pozactivlunai on pozactivitati for update, insert, delete as
declare @nlunainc int, @nanulinc int, @ddatainc datetime
set @nlunainc= (select val_numerica from par where tip_parametru='MM' and parametru='LUNAINC')
set @nanulinc= (select val_numerica from par where tip_parametru='MM' and parametru='ANULINC')
set @dDataInc=dateadd(month,1,convert(datetime,str(@nLunaInc,2)+'/01/'+str(@nAnulInc,4)))
if (select count(*) from inserted where data<@dDataInc)>0 or (select count(*) from deleted where data<@dDataInc)>0
begin
 RAISERROR ('Violare integritate date. Incercare de modificare luna inchisa(pozactivitati)', 16, 1)
 rollback transaction
end

GO
--***
CREATE trigger pozactivsterg on pozactivitati for insert,update, delete  NOT FOR REPLICATION as  
begin

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspozactiv
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator, 'A',   
Tip, Fisa, Data, Numar_pozitie, Traseu, Plecare, Data_plecarii, Ora_plecarii, Sosire, Data_sosirii,
Ora_sosirii, Explicatii, Comanda_benef, Lm_beneficiar, Tert, Marca, Utilizator, Data_operarii, 
Ora_operarii, Alfa1, Alfa2, Val1, Val2, Data1 
from inserted   

insert into sysspozactiv  
	select host_id(),host_name (), @Aplicatia, getdate(),@Utilizator, 'S',   
Tip, Fisa, Data, Numar_pozitie, Traseu, Plecare, Data_plecarii, Ora_plecarii, Sosire, Data_sosirii,
Ora_sosirii, Explicatii, Comanda_benef, Lm_beneficiar, Tert, Marca, Utilizator, Data_operarii, 
Ora_operarii, Alfa1, Alfa2, Val1, Val2, Data1 
from deleted  
end
