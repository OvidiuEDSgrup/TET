CREATE TABLE [dbo].[tmpValori] (
    [Terminal]         CHAR (8)   NOT NULL,
    [Cod]              CHAR (100) NOT NULL,
    [Val_logica]       BIT        NOT NULL,
    [Val_numerica]     FLOAT (53) NOT NULL,
    [Val_alfanumerica] CHAR (200) NOT NULL,
    [Data]             DATETIME   NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[tmpValori]([Terminal] ASC, [Cod] ASC);

