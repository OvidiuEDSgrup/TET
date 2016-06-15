CREATE TABLE [dbo].[elemantec] (
    [Element]               CHAR (20)    NOT NULL,
    [Descriere]             CHAR (80)    NOT NULL,
    [Articol_de_calculatie] CHAR (9)     NOT NULL,
    [Formula]               CHAR (2000)  NOT NULL,
    [NrOrdine]              REAL         NOT NULL,
    [procent]               BIT          NULL,
    [element_parinte]       VARCHAR (20) NULL,
    [valoare_implicita]     FLOAT (53)   NULL,
    [pas]                   INT          NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[elemantec]([Element] ASC) WITH (FILLFACTOR = 20);


GO
CREATE NONCLUSTERED INDEX [Ordine_elemente]
    ON [dbo].[elemantec]([NrOrdine] ASC) WITH (FILLFACTOR = 20);

