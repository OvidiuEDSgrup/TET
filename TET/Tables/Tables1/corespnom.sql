CREATE TABLE [dbo].[corespnom] (
    [cod]              CHAR (20) NOT NULL,
    [Cod_corespondent] CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [unic]
    ON [dbo].[corespnom]([cod] ASC, [Cod_corespondent] ASC);

