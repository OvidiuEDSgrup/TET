CREATE TABLE [dbo].[tmpcodfurn] (
    [HostID]                CHAR (8)  NOT NULL,
    [Tert]                  CHAR (13) NOT NULL,
    [Cod_furnizor]          CHAR (20) NOT NULL,
    [Denumire_cod_furnizor] CHAR (80) NOT NULL,
    [Cod]                   CHAR (20) NOT NULL,
    [Cod_special]           CHAR (20) NOT NULL,
    [Cod_de_bare]           CHAR (20) NOT NULL,
    [Tip_asociere]          SMALLINT  NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[tmpcodfurn]([HostID] ASC, [Tert] ASC, [Cod_furnizor] ASC);

