CREATE TABLE [dbo].[pozcomlivrtmp] (
    [Utilizator]     CHAR (10)  NOT NULL,
    [Cod]            CHAR (20)  NOT NULL,
    [Comanda]        CHAR (20)  NOT NULL,
    [Tert]           CHAR (13)  NOT NULL,
    [Cant_comandata] FLOAT (53) NOT NULL,
    [Cant_aprobata]  FLOAT (53) NOT NULL,
    [Termen]         DATETIME   NOT NULL,
    [Numar_document] CHAR (20)  NOT NULL,
    [Data_document]  DATETIME   NOT NULL,
    [Stare]          CHAR (1)   NOT NULL,
    [Selectat]       BIT        NOT NULL,
    [Observatii]     CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[pozcomlivrtmp]([Utilizator] ASC, [Cod] ASC, [Comanda] ASC, [Tert] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod]
    ON [dbo].[pozcomlivrtmp]([Utilizator] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod_si_termen]
    ON [dbo].[pozcomlivrtmp]([Utilizator] ASC, [Cod] ASC, [Termen] ASC);

