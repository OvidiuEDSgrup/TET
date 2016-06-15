CREATE TABLE [dbo].[legCpvNomencl] (
    [idcpv] INT          NULL,
    [cod]   VARCHAR (20) NULL
);


GO
CREATE NONCLUSTERED INDEX [indcod]
    ON [dbo].[legCpvNomencl]([cod] ASC);

