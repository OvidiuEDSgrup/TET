CREATE TABLE [dbo].[pozcom] (
    [Subunitate] CHAR (9)   NOT NULL,
    [Comanda]    CHAR (20)  NOT NULL,
    [Cod_produs] CHAR (30)  NOT NULL,
    [Cantitate]  FLOAT (53) NOT NULL,
    [UM]         CHAR (3)   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Sub_Com_CodProdus]
    ON [dbo].[pozcom]([Subunitate] ASC, [Comanda] ASC, [Cod_produs] ASC);

