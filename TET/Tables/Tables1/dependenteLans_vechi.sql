﻿CREATE TABLE [dbo].[dependenteLans_vechi] (
    [id]         INT          IDENTITY (1, 1) NOT NULL,
    [comanda]    VARCHAR (20) NOT NULL,
    [cod]        VARCHAR (20) NULL,
    [tert]       VARCHAR (20) NULL,
    [contract]   VARCHAR (20) NULL,
    [comandaleg] VARCHAR (20) NULL,
    [detalii]    XML          NULL
);

