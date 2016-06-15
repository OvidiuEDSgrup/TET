CREATE TABLE [dbo].[ExceptiiSoldTert] (
    [idExceptie]    INT           IDENTITY (1, 1) NOT NULL,
    [tert]          VARCHAR (13)  NULL,
    [dela]          DATETIME      NULL,
    [panala]        DATETIME      NULL,
    [sold_max]      FLOAT (53)    NULL,
    [explicatii]    VARCHAR (500) NULL,
    [utilizator]    VARCHAR (100) NULL,
    [data_operarii] DATETIME      DEFAULT (getdate()) NULL,
    PRIMARY KEY CLUSTERED ([idExceptie] ASC)
);

