CREATE TABLE [dbo].[comlivrtmp] (
    [Utilizator]     CHAR (10)  NOT NULL,
    [Cod]            CHAR (20)  NOT NULL,
    [Cant_comandata] FLOAT (53) NOT NULL,
    [Stoc]           FLOAT (53) NOT NULL,
    [Cant_aprobata]  FLOAT (53) NOT NULL,
    [Aprobat_alte]   FLOAT (53) NOT NULL,
    [Stare]          CHAR (1)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[comlivrtmp]([Utilizator] ASC, [Cod] ASC);


GO
CREATE NONCLUSTERED INDEX [Stare]
    ON [dbo].[comlivrtmp]([Utilizator] ASC, [Stare] ASC);

