CREATE TABLE [dbo].[Programator] (
    [Numar_curent]           INT           NOT NULL,
    [Data]                   DATETIME      NOT NULL,
    [Descriere_problema]     VARCHAR (200) NOT NULL,
    [Tert]                   VARCHAR (13)  NOT NULL,
    [Cod]                    VARCHAR (20)  NOT NULL,
    [Postul]                 SMALLINT      NOT NULL,
    [Data_planificarii]      DATETIME      NOT NULL,
    [Ora_planificarii_start] VARCHAR (6)   NOT NULL,
    [Data_planificarii_stop] DATETIME      NOT NULL,
    [Ora_planificarii_stop]  VARCHAR (6)   NOT NULL,
    [Utilizator]             VARCHAR (20)  NOT NULL,
    [Data_operarii]          DATETIME      NOT NULL,
    [Ora_operarii]           VARCHAR (6)   NOT NULL,
    [Stare]                  VARCHAR (1)   NOT NULL,
    [Deviz]                  VARCHAR (20)  NOT NULL,
    [nr_inmatriculare_prog]  VARCHAR (10)  NOT NULL,
    [nume_prog]              VARCHAR (20)  NOT NULL,
    [telefon_prog]           VARCHAR (15)  NOT NULL,
    [numar_parinte]          INT           NOT NULL,
    [Motiv_intrare]          VARCHAR (10)  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic_programator]
    ON [dbo].[Programator]([Numar_curent] ASC, [Data] ASC, [Deviz] ASC);


GO
CREATE NONCLUSTERED INDEX [Postul_de_lucru]
    ON [dbo].[Programator]([Postul] ASC, [Data_planificarii] ASC, [Ora_planificarii_start] ASC);

