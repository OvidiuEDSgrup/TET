CREATE TABLE [dbo].[TFormular] (
    [Terminal] CHAR (40)      NOT NULL,
    [Coloana]  CHAR (255)     NOT NULL,
    [Rand]     INT            NOT NULL,
    [Valoare]  VARCHAR (4000) NOT NULL
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [PTFormular]
    ON [dbo].[TFormular]([Terminal] ASC, [Coloana] ASC, [Rand] ASC);

