CREATE TABLE [dbo].[devauto] (
    [Cod_deviz]          VARCHAR (20)  NOT NULL,
    [Denumire_deviz]     VARCHAR (50)  NOT NULL,
    [Data_lansarii]      DATETIME      NOT NULL,
    [Ora_lansarii]       VARCHAR (6)   NOT NULL,
    [Data_inchiderii]    DATETIME      NULL,
    [Autovehicul]        VARCHAR (20)  NOT NULL,
    [KM_bord]            FLOAT (53)    NOT NULL,
    [Executant]          VARCHAR (9)   NOT NULL,
    [Beneficiar]         VARCHAR (13)  NOT NULL,
    [Valoare_deviz]      FLOAT (53)    NOT NULL,
    [Valoare_realizari]  FLOAT (53)    NOT NULL,
    [Sesizare_client]    VARCHAR (200) NOT NULL,
    [Constatare_service] VARCHAR (200) NOT NULL,
    [Observatii]         VARCHAR (200) NOT NULL,
    [Stare]              VARCHAR (1)   NOT NULL,
    [Termen_de_executie] VARCHAR (6)   NOT NULL,
    [Ora_executie]       VARCHAR (6)   NOT NULL,
    [Numar_de_dosar]     VARCHAR (200) NOT NULL,
    [Tip]                VARCHAR (1)   NOT NULL,
    [Factura]            VARCHAR (20)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[devauto]([Cod_deviz] ASC);


GO
CREATE NONCLUSTERED INDEX [Data]
    ON [dbo].[devauto]([Data_lansarii] DESC, [Cod_deviz] ASC);


GO
CREATE NONCLUSTERED INDEX [data_lansare]
    ON [dbo].[devauto]([Data_lansarii] ASC, [Ora_lansarii] ASC);


GO
CREATE NONCLUSTERED INDEX [Denumire]
    ON [dbo].[devauto]([Denumire_deviz] ASC);


GO
CREATE NONCLUSTERED INDEX [Loc_de_munca]
    ON [dbo].[devauto]([Beneficiar] ASC, [Cod_deviz] ASC);


GO
--***
create trigger devautosterg on devauto for update, delete /*with append*/ NOT FOR REPLICATION as
insert into sysstdevauto
select Cod_deviz, Denumire_deviz, Data_lansarii, Ora_lansarii, Data_inchiderii, Autovehicul, KM_bord, 
Executant, Beneficiar, Valoare_deviz, Valoare_realizari, Sesizare_client, Constatare_service, 
Observatii, Stare, Termen_de_executie, Ora_executie, Numar_de_dosar, Tip, Factura,
host_id(), 
left(isnull((case when left(app_name(),5)='Magic' then (select max(utilizator) from sysunic where 
host_id()=ltrim(rtrim(hostid)) and data_intrarii=(select max(data_intrarii) from sysunic where 
host_id()=ltrim(rtrim(hostid)))) else host_name() end),'NU_STIU'),30), left(app_name(), 30), getdate()
from deleted
