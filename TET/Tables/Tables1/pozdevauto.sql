CREATE TABLE [dbo].[pozdevauto] (
    [Tip]                  VARCHAR (1)   NOT NULL,
    [Cod_deviz]            VARCHAR (20)  NOT NULL,
    [Pozitie_articol]      FLOAT (53)    NOT NULL,
    [Tip_resursa]          VARCHAR (1)   NOT NULL,
    [Cod]                  VARCHAR (20)  NOT NULL,
    [Cantitate]            FLOAT (53)    NOT NULL,
    [Timp_normat]          FLOAT (53)    NOT NULL,
    [Tarif_orar]           FLOAT (53)    NOT NULL,
    [Pret_de_stoc]         FLOAT (53)    NOT NULL,
    [Adaos]                REAL          NOT NULL,
    [Discount]             REAL          NOT NULL,
    [Pret_vanzare]         FLOAT (53)    NOT NULL,
    [Cont_de_stoc]         VARCHAR (13)  NOT NULL,
    [Cod_corespondent]     VARCHAR (20)  NOT NULL,
    [Data_lansarii]        DATETIME      NOT NULL,
    [Ora_planificata]      VARCHAR (6)   NOT NULL,
    [Numar_consum]         VARCHAR (8)   NOT NULL,
    [Data_finalizarii]     DATETIME      NULL,
    [Ora_finalizarii]      VARCHAR (6)   NOT NULL,
    [Cod_gestiune]         VARCHAR (9)   NOT NULL,
    [Stare_pozitie]        VARCHAR (1)   NOT NULL,
    [Loc_de_munca]         VARCHAR (9)   NOT NULL,
    [Marca]                VARCHAR (6)   NOT NULL,
    [Cod_intrare]          VARCHAR (13)  NOT NULL,
    [Utilizator]           VARCHAR (20)  NOT NULL,
    [Data_operarii]        DATETIME      NOT NULL,
    [Ora_operarii]         VARCHAR (6)   NOT NULL,
    [Utilizator_consum]    VARCHAR (10)  NOT NULL,
    [Utilizator_facturare] VARCHAR (10)  NOT NULL,
    [Numar_aviz]           VARCHAR (8)   NOT NULL,
    [Data_facturarii]      DATETIME      NOT NULL,
    [Promotie]             VARCHAR (13)  NOT NULL,
    [Generatie]            SMALLINT      NOT NULL,
    [Confirmat_telefonic]  BIT           NOT NULL,
    [Explicatii]           VARCHAR (100) NOT NULL,
    [Cota_TVA]             REAL          NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Dupa_tip_resursa]
    ON [dbo].[pozdevauto]([Tip] ASC, [Cod_deviz] ASC, [Pozitie_articol] ASC, [Tip_resursa] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Crescator_dupa_stare]
    ON [dbo].[pozdevauto]([Cod_deviz] ASC, [Stare_pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Tip_Cod_Resursa]
    ON [dbo].[pozdevauto]([Tip] ASC, [Cod_deviz] ASC, [Tip_resursa] DESC, [Cod] ASC, [Pozitie_articol] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Tip_nr_pozitie]
    ON [dbo].[pozdevauto]([Tip] ASC, [Cod_deviz] ASC, [Tip_resursa] DESC, [Pozitie_articol] ASC, [Cod] ASC);


GO
--***
create trigger pdevsterg on pozdevauto for update, delete /*with append*/ NOT FOR REPLICATION as
insert into sysstpozdevauto
select Tip, Cod_deviz, Pozitie_articol, Tip_resursa, Cod, Cantitate, Timp_normat, Tarif_orar, 
Pret_de_stoc, Adaos, Discount, Pret_vanzare, Cont_de_stoc, Cod_corespondent, Data_lansarii, 
Ora_planificata, Numar_consum, Data_finalizarii, Ora_finalizarii, Cod_gestiune, Stare_pozitie, 
Loc_de_munca, Marca, Cod_intrare, Utilizator, Data_operarii, Ora_operarii, Utilizator_consum, 
Utilizator_facturare, Numar_aviz, Data_facturarii, Promotie, Generatie, Confirmat_telefonic, 
Explicatii, Cota_TVA,
host_id(), 
left(isnull((case when left(app_name(),5)='Magic' then (select max(utilizator) from sysunic where 
host_id()=ltrim(rtrim(hostid)) and data_intrarii=(select max(data_intrarii) from sysunic where 
host_id()=ltrim(rtrim(hostid)))) else host_name() end),'NU_STIU'),30), left(app_name(),30), getdate()
from deleted
