CREATE TABLE [dbo].[catproprietati] (
    [Cod_proprietate]     CHAR (20) NOT NULL,
    [Descriere]           CHAR (80) NOT NULL,
    [Validare]            SMALLINT  NOT NULL,
    [Catalog]             CHAR (1)  NOT NULL,
    [Proprietate_parinte] CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[catproprietati]([Cod_proprietate] ASC);

