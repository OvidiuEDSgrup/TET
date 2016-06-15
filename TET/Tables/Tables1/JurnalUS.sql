CREATE TABLE [dbo].[JurnalUS] (
    [IDSesiune]    CHAR (20) NOT NULL,
    [IDC]          CHAR (13) NOT NULL,
    [Utilizator]   CHAR (6)  NOT NULL,
    [Data_logarii] DATETIME  NOT NULL,
    [Ora_logarii]  CHAR (6)  NOT NULL,
    [Data_iesirii] DATETIME  NOT NULL,
    [Ora_iesirii]  CHAR (6)  NOT NULL,
    [Valid]        BIT       NOT NULL,
    [Activitate]   CHAR (6)  NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Principal]
    ON [dbo].[JurnalUS]([IDSesiune] ASC);

