CREATE TABLE [dbo].[altedocCFP] (
    [ID]            INT        IDENTITY (1, 1) NOT NULL,
    [Indicator]     CHAR (20)  NOT NULL,
    [Tip]           CHAR (20)  NOT NULL,
    [Numar]         CHAR (8)   NOT NULL,
    [Data]          DATETIME   NOT NULL,
    [Stare]         CHAR (1)   NOT NULL,
    [Loc_de_munca]  CHAR (9)   NOT NULL,
    [Beneficiar]    CHAR (20)  NOT NULL,
    [Suma]          FLOAT (53) NOT NULL,
    [Valuta]        CHAR (3)   NOT NULL,
    [Curs]          FLOAT (53) NOT NULL,
    [Suma_valuta]   FLOAT (53) NOT NULL,
    [Explicatii]    CHAR (200) NOT NULL,
    [Observatii]    CHAR (200) NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[altedocCFP]([ID] ASC);


GO
CREATE NONCLUSTERED INDEX [Tip_numar_data]
    ON [dbo].[altedocCFP]([Tip] ASC, [Numar] ASC, [Data] ASC);


GO
CREATE NONCLUSTERED INDEX [Indicator]
    ON [dbo].[altedocCFP]([Indicator] ASC);

