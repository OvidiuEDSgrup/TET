CREATE TABLE [dbo].[barcodp] (
    [Subunitate] CHAR (9)   NOT NULL,
    [Comanda]    CHAR (13)  NOT NULL,
    [Produs]     CHAR (20)  NOT NULL,
    [Nr_pozitie] FLOAT (53) NOT NULL,
    [Barcod]     CHAR (30)  NOT NULL,
    [Nr_pozitii] FLOAT (53) NOT NULL,
    [Alfa1]      CHAR (20)  NOT NULL,
    [Alfa2]      CHAR (20)  NOT NULL,
    [Val1]       FLOAT (53) NOT NULL,
    [Val2]       FLOAT (53) NOT NULL,
    [Data]       DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Barcodp1]
    ON [dbo].[barcodp]([Subunitate] ASC, [Comanda] ASC, [Produs] ASC, [Nr_pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Barcodp2]
    ON [dbo].[barcodp]([Subunitate] ASC, [Produs] ASC, [Comanda] ASC, [Nr_pozitie] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Barcodp3]
    ON [dbo].[barcodp]([Subunitate] ASC, [Barcod] ASC, [Comanda] ASC, [Produs] ASC, [Nr_pozitie] ASC);

