CREATE TABLE [dbo].[auto] (
    [Cod]                    VARCHAR (20)  NOT NULL,
    [Tip_auto]               VARCHAR (10)  NOT NULL,
    [Marca]                  VARCHAR (30)  NOT NULL,
    [Model]                  VARCHAR (30)  NOT NULL,
    [Versiune]               VARCHAR (30)  NOT NULL,
    [An_fabricatie]          VARCHAR (4)   NOT NULL,
    [Dealer]                 VARCHAR (50)  NOT NULL,
    [Serie_de_sasiu]         VARCHAR (30)  NOT NULL,
    [Nr_circulatie]          VARCHAR (15)  NOT NULL,
    [Serie_de_motor]         VARCHAR (30)  NOT NULL,
    [Km_la_bord]             FLOAT (53)    NOT NULL,
    [DAM]                    VARCHAR (4)   NOT NULL,
    [DDG]                    DATETIME      NOT NULL,
    [Cilindree]              VARCHAR (30)  NOT NULL,
    [Carburant]              VARCHAR (1)   NOT NULL,
    [Culoare]                VARCHAR (20)  NOT NULL,
    [Denumire_culoare]       VARCHAR (30)  NOT NULL,
    [Cod_antidemaraj]        VARCHAR (10)  NOT NULL,
    [Cod_radio]              VARCHAR (10)  NOT NULL,
    [Cod_chei]               VARCHAR (10)  NOT NULL,
    [Tip_club]               VARCHAR (20)  NOT NULL,
    [Numar_card]             VARCHAR (20)  NOT NULL,
    [Data_card]              DATETIME      NOT NULL,
    [Data_adeziunii]         DATETIME      NOT NULL,
    [Cod_chirias]            VARCHAR (20)  NOT NULL,
    [Cod_proprietar]         VARCHAR (20)  NOT NULL,
    [Data_ITP]               DATETIME      NOT NULL,
    [Asigurare]              VARCHAR (20)  NOT NULL,
    [Asigurare_obligatorie]  VARCHAR (20)  NOT NULL,
    [Data_cumpararii]        DATETIME      NOT NULL,
    [Observatii]             VARCHAR (100) NOT NULL,
    [Nr_comanda]             VARCHAR (40)  NOT NULL,
    [Tip_motor]              VARCHAR (20)  NOT NULL,
    [Putere_motor]           VARCHAR (10)  NOT NULL,
    [Garantie]               REAL          NOT NULL,
    [Furnizor]               VARCHAR (30)  NOT NULL,
    [Localitate_furnizor]    VARCHAR (50)  NOT NULL,
    [Mod_de_plata]           VARCHAR (20)  NOT NULL,
    [Denumire_firma_leasing] VARCHAR (50)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[auto]([Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Marca]
    ON [dbo].[auto]([Marca] ASC, [Model] ASC);


GO
CREATE NONCLUSTERED INDEX [nr_CIRCULATIE]
    ON [dbo].[auto]([Nr_circulatie] ASC, [Serie_de_sasiu] ASC, [Nr_comanda] ASC);


GO
--***
create trigger autosterg on [auto] for update, delete /*with append*/ NOT FOR REPLICATION as
insert into sysstauto
select Cod, Tip_auto, Marca, Model, Versiune, An_fabricatie, Dealer, Serie_de_sasiu, Nr_circulatie, 
Serie_de_motor, Km_la_bord, DAM, DDG, Cilindree, Carburant, Culoare, Denumire_culoare, Cod_antidemaraj, 
Cod_radio, Cod_chei, Tip_club, Numar_card, Data_card, Data_adeziunii, Cod_chirias, Cod_proprietar, 
Data_ITP, Asigurare, Asigurare_obligatorie, Data_cumpararii, Observatii, Nr_comanda, Tip_motor, 
Putere_motor, Garantie, Furnizor, Localitate_furnizor, Mod_de_plata, Denumire_firma_leasing,
host_id(), 
left(isnull((case when left(app_name(),5)='Magic' then (select max(utilizator) from sysunic where 
host_id()=ltrim(rtrim(hostid)) and data_intrarii=(select max(data_intrarii) from sysunic where 
host_id()=ltrim(rtrim(hostid)))) else host_name() end),'NU_STIU'),30), app_name(), getdate() 
from deleted
