CREATE TABLE [dbo].[barcodcp] (
    [Subunitate]    CHAR (9)   NOT NULL,
    [Comanda]       CHAR (13)  NOT NULL,
    [Produs]        CHAR (20)  NOT NULL,
    [Nr_pozitie]    FLOAT (53) NOT NULL,
    [Tip_comp]      CHAR (1)   NOT NULL,
    [Nr_comp]       FLOAT (53) NOT NULL,
    [Cod_comp]      CHAR (20)  NOT NULL,
    [Barcod_comp]   CHAR (30)  NOT NULL,
    [Utilizator]    CHAR (10)  NOT NULL,
    [Data_operarii] DATETIME   NOT NULL,
    [Ora_operarii]  CHAR (6)   NOT NULL,
    [Alfa1]         CHAR (20)  NOT NULL,
    [Alfa2]         CHAR (20)  NOT NULL,
    [Val1]          FLOAT (53) NOT NULL,
    [Val2]          FLOAT (53) NOT NULL,
    [Data]          DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Barcodcp1]
    ON [dbo].[barcodcp]([Subunitate] ASC, [Comanda] ASC, [Produs] ASC, [Nr_pozitie] ASC, [Tip_comp] ASC, [Nr_comp] ASC, [Cod_comp] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Barcodcp2]
    ON [dbo].[barcodcp]([Subunitate] ASC, [Comanda] ASC, [Produs] ASC, [Nr_pozitie] ASC, [Tip_comp] ASC, [Cod_comp] ASC, [Nr_comp] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Barcodcp3]
    ON [dbo].[barcodcp]([Subunitate] ASC, [Comanda] ASC, [Produs] ASC, [Nr_pozitie] ASC, [Cod_comp] ASC, [Tip_comp] ASC, [Nr_comp] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [Barcodcp4]
    ON [dbo].[barcodcp]([Subunitate] ASC, [Barcod_comp] ASC, [Comanda] ASC, [Produs] ASC, [Nr_pozitie] ASC, [Tip_comp] ASC, [Nr_comp] ASC, [Cod_comp] ASC);

