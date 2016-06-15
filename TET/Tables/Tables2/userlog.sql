CREATE TABLE [dbo].[userlog] (
    [ID]                INT       IDENTITY (1, 1) NOT NULL,
    [HostID]            CHAR (10) NOT NULL,
    [UserID]            CHAR (10) NOT NULL,
    [Aplicatia]         CHAR (8)  NOT NULL,
    [Data_intrarii]     DATETIME  NOT NULL,
    [Ora_intrarii]      CHAR (6)  NOT NULL,
    [Data_ora_intrarii] DATETIME  NOT NULL,
    [Baza_de_date]      CHAR (30) NOT NULL,
    [Selectat]          BIT       NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[userlog]([ID] ASC);


GO
CREATE NONCLUSTERED INDEX [Intrari]
    ON [dbo].[userlog]([HostID] ASC, [Data_intrarii] ASC, [Ora_intrarii] ASC);

