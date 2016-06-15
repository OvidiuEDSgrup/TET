CREATE TABLE [dbo].[dateSincronizare] (
    [id]         INT           IDENTITY (1, 1) NOT NULL,
    [utilizator] VARCHAR (50)  NULL,
    [cod]        VARCHAR (50)  NULL,
    [cod2]       VARCHAR (50)  NULL,
    [tip]        VARCHAR (2)   NULL,
    [data]       DATETIME      NULL,
    [suma]       FLOAT (53)    NULL,
    [tert]       VARCHAR (20)  NULL,
    [status]     VARCHAR (400) NULL,
    [detalii]    XML           NULL
);

