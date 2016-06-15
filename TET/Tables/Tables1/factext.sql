CREATE TABLE [dbo].[factext] (
    [tert]            CHAR (13) NOT NULL,
    [factura]         CHAR (20) NOT NULL,
    [nr_DVE]          CHAR (13) NOT NULL,
    [data_DVE]        DATETIME  NOT NULL,
    [nr_DIV]          CHAR (13) NOT NULL,
    [data_DIV]        DATETIME  NOT NULL,
    [factura_externa] CHAR (20) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [unic]
    ON [dbo].[factext]([tert] ASC, [factura] ASC);

