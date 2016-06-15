CREATE TABLE [dbo].[tehnologii] (
    [cod]           CHAR (20)    NOT NULL,
    [Denumire]      CHAR (80)    NOT NULL,
    [tip]           CHAR (1)     NOT NULL,
    [Data_operarii] DATETIME     NOT NULL,
    [detalii]       XML          NULL,
    [codNomencl]    VARCHAR (20) NULL,
    CONSTRAINT [PK_tehnologii] PRIMARY KEY CLUSTERED ([cod] ASC) WITH (FILLFACTOR = 20)
);


GO
CREATE NONCLUSTERED INDEX [cNomencl]
    ON [dbo].[tehnologii]([codNomencl] ASC);


GO
CREATE NONCLUSTERED INDEX [princ]
    ON [dbo].[tehnologii]([cod] ASC) WITH (FILLFACTOR = 20);

