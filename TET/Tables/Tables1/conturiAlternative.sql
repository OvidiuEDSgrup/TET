CREATE TABLE [dbo].[conturiAlternative] (
    [cont]      VARCHAR (20)  NULL,
    [descriere] VARCHAR (200) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [indxContAlternativ]
    ON [dbo].[conturiAlternative]([cont] ASC);

