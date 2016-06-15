CREATE TABLE [dbo].[tmpselarb] (
    [HostId]      CHAR (8)   NOT NULL,
    [Cod]         CHAR (20)  NOT NULL,
    [Cod_parinte] CHAR (20)  NOT NULL,
    [Descriere]   CHAR (200) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [Unic]
    ON [dbo].[tmpselarb]([HostId] ASC, [Cod] ASC);

